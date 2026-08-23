# Network enforcement layers

Three separate mechanisms restrict networking, and they interact in ways that
are not obvious from the option names.

## The measurement matrix

Measured with `scripts/sandbox-diag.py` across sandbox configurations:

| Configuration | TCP bind | loopback connect | SCM_CREDENTIALS |
|---|---|---|---|
| network-free | `EACCES` | `EACCES` | OK |
| network, no `--net-allow` | OK | `ECONNREFUSED` | `EPERM` |
| network + `--net-allow` | OK | `ECONNREFUSED` | `EPERM` |
| network-free + `--net-allow-bind` | OK (listed ports) | `EACCES` | OK |
| network-free + `--disable net-tcp` | OK | OK | OK |

Conclusions:

- Landlock denies TCP bind **and** connect by default. `--net-allow-bind`
  relaxes bind only; `--disable net-tcp` relaxes both.
- **Any** Sandlock network policy flag — `--net-allow` or the `--http-*` set —
  switches on the supervisor's syscall interception. The supervisor then
  refuses loopback connects with `ECONNREFUSED` and fails
  `sendmsg(SCM_CREDENTIALS)` with `EPERM`, neither of which is implied by the
  flag being asked for.
- The last row is the only configuration where a local test server works
  end to end. Chrome still fails there, on `prctl(PR_SET_PTRACER)`.

This is why `--allow-localhost` behaves differently per mode: network-free it
emits `--disable net-tcp`, which is safe because bwrap gives the sandbox a
private network namespace and it can only ever reach its own loopback;
network-enabled it emits `--net-allow "127.0.0.1:<ports>"` plus
`--net-allow-bind <ports>`, since `--disable net-tcp` would then be a real hole.

## The /etc/hosts trap

`/etc/hosts` is bound bwrap-only, as a `--ro-bind` in `bwrap_args`, and **must
not** go through `bind-read`. `bind-read` also emits `--fs-read` to Sandlock,
and Sandlock mounts its own `/etc/hosts` when networking is enabled, after
which adding a Landlock rule for that path fails with

    landlock error: add path rule for "/etc/hosts":
    File descriptor in bad state (os error 77)

which kills the sandbox outright. It only reproduces when networking is on, so
network-free tests pass and the breakage surfaces somewhere unrelated, such as
the first `npm` command.

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
