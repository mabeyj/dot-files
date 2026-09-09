# Headless browsers under the sandbox

Measured on Arch Linux, kernel 7.1.8, Landlock ABI v9, `sandlock 0.8.6`,
Google Chrome 152.0.7977.64 and the system Firefox. The Chrome result
reproduces unchanged from the original measurements on `sandlock 0.8.5` and
Chrome 150, taken on different hardware. On `sandlock 0.8.7` the four Crashpad
syscall probes below give identical results in every configuration; Chrome
itself was not re-run.

Summary: **Firefox works under Sandlock; Chrome does not, in any
configuration.** Running Chrome requires `--no-sandlock`, which leaves
Bubblewrap's file system isolation intact but gives up network enforcement and
the syscall blocklist.

## Chrome: Crashpad cannot start

Chrome aborts with SIGTRAP (exit 133) and **zero log output**, immediately
after the crash-reporter line.

The core dump pins it exactly. The crash site is an `int3; ud2` pair — Chrome's
`IMMEDIATE_CRASH()` — surrounded by Crashpad's argv strings
(`https://clients2.google.com/cr/report`, `--monitor-self`,
`--monitor-self-annotation=ptype=crashpad-handler`). That is
`CrashpadClient::StartHandler()`, and the trap is the `CHECK(result)` in
`crashpad_linux.cc` asserting it succeeded. In official release builds Chrome's
`CHECK` compiles to a bare trap with no message, which is why there is no
diagnostic.

Crashpad on Linux needs `sendmsg(SCM_CREDENTIALS)`, `ptrace`,
`prctl(PR_SET_PTRACER)` and `process_vm_readv`. Sandlock denies all four.
`prctl(PR_SET_PTRACER)` is denied unconditionally by the seccomp blocklist
regardless of network mode, so every configuration fails here, including the
network-free one where `SCM_CREDENTIALS` is allowed and the networked one where
loopback fully works.

There is **no Chrome-side workaround**: `InitializeCrashpad()` runs
unconditionally in the browser process, `--disable-breakpad` and
`--disable-crash-reporter` do not skip it, and `--headless=old` was removed in
Chrome 132.

Two cores taken hours apart, under different sandbox configurations, crash at
the **identical offset `chrome+0x5e96f4e`**. Relaxing `SCM_CREDENTIALS` alone
only moves the failure to the next gate in the same function.

Re-confirmed on Chrome 152 under `sandlock 0.8.6`, at `chrome+0x4eeba3e` — a
different offset, as expected across builds, but the same crash. The core again
holds an `int3; ud2` at the trap site, and Crashpad's argv strings
(`https://clients2.google.com/cr/report`, `--monitor-self`,
`--monitor-self-annotation=ptype=crashpad-handler`) sit in **anonymous** heap
pages rather than the binary's file-backed mappings, so they were assembled at
runtime: the process reached `StartHandler()`, built the handler's argv, and
then trapped.

`systemd-coredump` did not dump the stack pages, so frames above the trap are
unrecoverable and gdb's `find` over `$rsp` returns nothing. Locating those
strings instead means parsing the core's `PT_LOAD` headers and mapping file
offsets back to virtual addresses.

## Firefox: needs loopback explicitly allowed

Firefox itself is fine. What used to look like a Firefox hang was the
supervisor refusing the loopback connect, so a test runner such as Karma bound
its port successfully but nothing inside the sandbox could reach it, and the
runner waited out its capture timeout reporting something like "Firefox have
not captured in 60000 ms".

The fix is to pass `--allow-localhost <ports>`, which emits the `--net-allow`
rule the supervisor needs for loopback. Verified end to end: headless Firefox
screenshotting a `python3 -m http.server` on the sandbox's own loopback, under
`--allow-https ... --allow-localhost 9876`, with network restrictions active.
Without `--allow-localhost` the connect is still refused — see
`network-layers.md`.

## Core dumps accumulate invisibly

`core_pattern` pipes to `systemd-coredump`, which runs on the host outside the
sandbox. Every Chrome crash writes a full core there. `coredumpctl` does not
list them, because the processes died inside bwrap's PID namespace and the
journal metadata never landed, so they also never get vacuumed. Repeated crash
testing accumulates gigabytes. Clean up with:

    sudo find /var/lib/systemd/coredump -name 'core.chrome.1000.*' -delete

`ulimit -c 0` does **not** prevent this: when `core_pattern` is a pipe the
kernel sets the limit to `RLIM_INFINITY` and ignores `RLIMIT_CORE`.

## Ruled out

Recorded so they are not re-tested.

Chrome flags and conditions that make no difference to the crash: `--no-sandbox`,
`--no-zygote`, `--single-process`, `--disable-dev-shm-usage`, `--disable-gpu`,
unsetting `DISPLAY`, rlimits, CPU count detection, large mmap reservations, and
device ioctls.

Hypotheses that were wrong:

- `RLIMIT_AS` / PartitionAlloc address-space exhaustion — address space is
  unlimited and 64 GiB `PROT_NONE` reservations succeed.
- Chrome's namespace sandbox needing `unshare(CLONE_NEWUSER)` — `--no-sandbox`
  makes no difference to the crash.
- `SCM_CREDENTIALS` being universally denied — it is denied only when the
  supervisor's network interception is active.
- Enabling network without `--net-allow` avoiding the supervisor — it does not;
  the `--http-*` flags trigger it too.
- Missing `/etc/hosts` breaking a test runner's port search — glibc has a
  built-in `localhost` fallback, so resolution works even with all four name
  resolution files absent. The observed failure was `EACCES` on bind: Karma's
  `bindAvailablePort` retries on `EADDRINUSE`/`EACCES`, walked its port up to
  65536, then threw `ERR_SOCKET_BAD_PORT`.

## Incidental

- `google-chrome-stable` is a bash wrapper that does `exec > >(exec cat)` and
  `exec 2> >(exec cat >&2)`. Under the sandbox those `cat` processes emit
  garbled `write error: Function not implemented` messages. Noise, not the
  failure. Use `/opt/google/chrome/chrome` directly, or point `CHROME_BIN` at
  it.
- X11 is unreachable inside the sandbox even if `DISPLAY` is forwarded: the
  abstract socket is blocked by Landlock's abstract-unix-socket scoping, and
  `/tmp/.X11-unix` is shadowed by the tmpfs over `/tmp`. Headless only.
- SysV IPC (`shmget`, `semget`, `msgget`) is denied outright.
