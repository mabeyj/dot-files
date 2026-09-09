# Sandlock defects worth reporting upstream

Found in `sandlock 0.8.5` while diagnosing headless browsers, re-checked
against `0.8.6` and `0.8.7`. None has been reported yet. All are independent
of anything in `bin/sandbox`.

## Still open

1. **Enabling the HTTP proxy breaks `sendmsg(SCM_CREDENTIALS)` with `EPERM`.**
   This makes **every official Chrome build** abort during startup with SIGTRAP
   and no diagnostic output whatsoever — extremely hard to attribute.

2. **MITM leaf certificates omit the Authority Key Identifier extension**, so
   OpenSSL clients using strict X.509 verification (Python 3.13+) reject them
   with verify code 85. Adding an AKID matching the CA's Subject Key Identifier
   would fix it.

3. **There is no loopback-scoped relaxation of the Landlock TCP rules.**
   Loopback bind and connect are denied by default, and every way out has a
   cost: `--disable net-tcp` removes TCP protection entirely, while
   `--net-allow 127.0.0.1:<port>` works but activates the supervisor, which
   brings defect 1 with it.

4. **The process counter leaks.** zsh subshells increment it without
   decrementing, so a long-running session eventually hits `--max-processes`
   and dies. bash is unaffected: under `--max-processes 20`, 200 sequential
   bash subshells succeed while zsh fails partway through with `fork failed:
   resource temporarily unavailable`.

## Resolved in 0.8.7

- **`--http-inject-ca` matching the literal path opened rather than the
  resolved file.** Both sides are now canonicalised (commit `0dae1d3d`), so
  injecting any one of several symlinked bundle paths covers them all. See
  `tls-trust.md`.

## Resolved in 0.8.6

- **`--extra-allow-syscall` silently ignoring unrecognised group names.** It
  now rejects them and lists the valid ones.

- **Landlock failing with errno 77 on `/etc/hosts`** once Sandlock had mounted
  its own over it. See `network-layers.md`.

## Withdrawn

- **"Loopback connections are refused with `ECONNREFUSED` when the supervisor
  is running."** Measured too narrowly: the configurations tested had no
  `--net-allow` rule covering loopback, so the refusal was ordinary allowlist
  behaviour. Adding `--net-allow 127.0.0.1:<port>` makes loopback work. The
  misleading part is the errno — a policy denial reported as if nothing were
  listening — which is worth reporting as a diagnostics complaint, not as this
  defect. Defect 3 above covers what genuinely remains.
