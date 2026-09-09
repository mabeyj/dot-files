# Network enforcement layers

Three separate mechanisms restrict networking, and they interact in ways that
are not obvious from the option names.

## The measurement matrix

Measured with `scripts/sandbox-diag.py` across sandbox configurations, on
`sandlock 0.8.7`. Every row reproduces the `0.8.6` result unchanged:

| Configuration | TCP bind | loopback connect | SCM_CREDENTIALS |
|---|---|---|---|
| network-free | `EACCES` | `EACCES` | OK |
| network, no loopback `--net-allow` | OK | `ECONNREFUSED` | `EPERM` |
| network + `--net-allow 127.0.0.1:<ports>` | OK | OK | `EPERM` |
| network-free + `--net-allow-bind` | OK (listed ports) | `EACCES` | OK |
| network-free + `--disable net-tcp` | OK | OK | OK |
| network + `--net-deny` (denylist mode) | OK | OK | `EPERM` |

Conclusions:

- Landlock denies TCP bind **and** connect by default. `--net-allow-bind`
  relaxes bind only, `--disable net-tcp` relaxes both, and `--net-allow`
  relaxes connect for the endpoints it names.
- **Any** Sandlock network policy flag — `--net-allow` or the `--http-*` set —
  switches on the supervisor's syscall interception, which then fails
  `sendmsg(SCM_CREDENTIALS)` with `EPERM`. That is not implied by the flag
  being asked for, and it is what makes Chrome unrunnable in every networked
  configuration.
- Once the supervisor is running, **loopback is just another destination**: it
  needs a `--net-allow` rule of its own. Without one the connect is refused
  with `ECONNREFUSED`, which reads like nothing is listening rather than like a
  policy denial. With one, a local server works end to end — this is what
  `--allow-localhost` emits alongside a network option, and headless Firefox
  against a local server passes in that configuration.
- The `--net-deny` denylist mode permits loopback with no rule at all, but it
  is default-allow outbound and mutually exclusive with `--net-allow`, so it
  trades the allowlist away to get there.

## UDP is gated at socket() or at sendto(), depending on the rules

Since `sandlock 0.8.7`, `socket(SOCK_DGRAM)` is denied with `EPERM` only when
no network rule exists at all. With any network option in `bin/sandbox`,
including a bare `--allow-https`, the socket is created and the supervisor
judges each `sendto` destination instead: an uncovered one fails with
`ECONNREFUSED`, the same errno as an uncovered loopback TCP connect. Upstream
made the change so glibc's address-sorting probes in `getaddrinfo` stop
breaking name resolution under TCP-only rule sets. Two consequences:

- `--allow-unsafe-dns` is what allows the `sendto` to `127.0.0.53:53`; without
  it a resolver query now fails at `sendto`, not at `socket`.
- A `--net-allow 127.0.0.1:<port>` rule, as emitted by `--allow-localhost`,
  also permits UDP `sendto` to that endpoint.

A bare `--allow-network` under Sandlock uses the last row: Sandlock has no
allow-everything switch, so `bin/sandbox` emits `--net-deny 240.0.0.0/4`, a
reserved and unroutable range, to get default-allow TCP and UDP with no HTTPS
interception. Loopback needs nothing further in that mode. Any restrictive
network option given alongside takes precedence and the usual allowlist
configuration is emitted instead.

This is why `--allow-localhost` behaves differently per mode: network-free it
emits `--disable net-tcp`, which is safe because bwrap gives the sandbox a
private network namespace and it can only ever reach its own loopback;
network-enabled it emits `--net-allow "127.0.0.1:<ports>"` plus
`--net-allow-bind <ports>`, since `--disable net-tcp` would then be a real hole.

## The /etc/hosts trap, fixed in 0.8.6

Sandlock still mounts its own `/etc/hosts` when networking is enabled — it
appears inside the sandbox carrying an address entry per allowlisted host — but
adding a Landlock rule for that path on top of it no longer fails. Through
`sandlock 0.8.5` it aborted the run with

    landlock error: add path rule for "/etc/hosts":
    File descriptor in bad state (os error 77)

and so `/etc/hosts` had to be a bwrap-only `--ro-bind`, kept out of
`bind-read`. That constraint is lifted. `bin/sandbox` still binds it
bwrap-only, which remains correct but is no longer required, and its comment
there still describes the old failure.

`/etc/gai.conf` and `/etc/nsswitch.conf` are ordinary `bind-read` entries and
are bound unconditionally; `/etc/resolv.conf`, `/etc/ssl` and
`/etc/ca-certificates` stay network-only.

## Nesting

Two markers, with distinct meanings:

- `SANDBOX_NESTED` — bwrap and systemd-run have already run.
- `SANDBOX_SANDLOCK` — an outer supervisor already owns the seccomp listener.

Splitting them is what lets a sandbox nested inside a `--no-sandlock` sandbox
run a **full supervisor** of its own and impose its own network restrictions.
It needs neither bwrap nor systemd-run to do so: Landlock and seccomp work
without namespaces, the outer bwrap already established the mount namespace,
and `systemd-run --user` would fail anyway since `/run/user/1000/bus` is not
bound.

Confirmed by measurement. Network-free, the nested Sandlock has Landlock active
(bind and connect give `EACCES`) and the seccomp blocklist active (`EPERM`).
With `--allow-https`, its supervisor runs, a non-allowlisted host is refused,
and an allowlisted one succeeds through the HTTPS interception.

## Consequences for --env

`--env` is routed through whichever layer actually runs: bwrap `--setenv` when
outermost, Sandlock `--env` when nested under a supervisor, and a plain `env`
prefix when neither layer remains. Implementing it against Sandlock alone means
it silently stops working under `--no-sandlock`.
