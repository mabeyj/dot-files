---
name: sandbox-internals
description: Enforcement details and known failure modes of bin/sandbox (Bubblewrap + Sandlock). Use when something misbehaves inside the sandbox with no useful error - a process dies silently, a local server is unreachable, TLS verification fails, a headless browser crashes or hangs - or when changing bin/sandbox's network, TLS, or nesting behaviour.
---

# Sandbox internals

`bin/sandbox` layers three things, and a failure looks completely different
depending on which one produced it:

1. **systemd-run** — memory limits only.
2. **Bubblewrap** — mount and PID namespaces, `--clearenv`, and stub binds that
   conceal secret files. Without `--allow-network` it also gives the sandbox a
   private network namespace.
3. **Sandlock** — Landlock rules (file system, TCP bind/connect, signal and
   abstract-unix-socket scoping), a deny-only seccomp filter returning `EPERM`,
   and a supervisor process that intercepts syscalls through seccomp user
   notification to enforce network and HTTP policy, including a MITM proxy.

## Read the errno, not the message

The errno identifies the layer, and that is usually the whole diagnosis:

| errno | layer |
|---|---|
| `EACCES` | Landlock denied it |
| `EPERM` | the seccomp blocklist denied it |
| `ECONNREFUSED` on loopback, or on a UDP `sendto` | the supervisor intercepted it, and no `--net-allow` rule covers it |
| `ENOSYS` | seccomp, on a syscall the filter stubs out |

## Headline findings

Verified against `sandlock 0.8.7`.

- **Chrome cannot run under Sandlock at all.** Its Crashpad handler needs four
  syscalls that Sandlock denies, and it aborts with SIGTRAP and no output
  whatsoever. Firefox works, including against a server on the sandbox's own
  loopback. See `reference/headless-browsers.md`.
- **Any Sandlock network-policy flag activates the supervisor**, which fails
  `sendmsg(SCM_CREDENTIALS)` with `EPERM`. Once it is running, loopback
  connects need an explicit `--net-allow` rule covering them, or they are
  refused with `ECONNREFUSED`. See `reference/network-layers.md`.
- **CA injection follows symlinks since `sandlock 0.8.7`**, so `bin/sandbox`
  injects only the canonical bundle. Earlier versions matched the literal path
  opened and needed every bundle path injected. Python 3.14 still rejects the
  MITM leaf certificates. See `reference/tls-trust.md`.

## Investigating

`ptrace` is denied inside the sandbox, so `strace` and live `gdb` are both
unusable. Two techniques work instead:

1. **Syscall probes.** Call the syscall directly through `ctypes` in a forked
   child, so a denial cannot take down the harness, and report the exact errno.
   `scripts/sandbox-diag.py` covers name resolution, TCP bind, loopback
   connect, and the four Crashpad syscalls, ending in a one-line verdict.
   `scripts/scm-probe.py` is a minimal `SCM_CREDENTIALS` reproducer. Run either
   under several sandbox configurations and compare.
2. **Core dump analysis.** `gdb` reading a core file does *not* need `ptrace`,
   which sidesteps the restriction entirely.

To exercise `bin/sandbox` without running anything, replace the final
invocation with a print:

    sed 's/^\t"\${cmd\[@\]}"$/\tprint -rl -- "${cmd[@]}"/' bin/sandbox > dry-sandbox

Clear the nesting markers when doing this from inside a sandbox, or the script
takes the nested path: `env -u SANDBOX_NESTED -u SANDBOX_SANDLOCK`.

## Reference

- `reference/headless-browsers.md` — why Chrome crashes and Firefox hangs, plus
  hypotheses already ruled out.
- `reference/network-layers.md` — which layer denies bind, connect and
  `SCM_CREDENTIALS` in each configuration, as a measured matrix.
- `reference/tls-trust.md` — MITM CA injection, and the one client that still
  fails.
- `reference/upstream-bugs.md` — Sandlock defects found along the way, not yet
  reported.
