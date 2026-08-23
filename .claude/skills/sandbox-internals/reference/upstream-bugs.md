# Sandlock defects worth reporting upstream

Found in `sandlock 0.8.5` while diagnosing headless browsers. None has been
reported yet. All are independent of anything in `bin/sandbox`.

1. **Enabling the HTTP proxy breaks `sendmsg(SCM_CREDENTIALS)` with `EPERM`.**
   This makes **every official Chrome build** abort during startup with SIGTRAP
   and no diagnostic output whatsoever — extremely hard to attribute.

2. **In the same mode, loopback connections are refused with `ECONNREFUSED`**,
   which breaks any local test server.

3. **MITM leaf certificates omit the Authority Key Identifier extension**, so
   OpenSSL clients using strict X.509 verification (Python 3.13+) reject them
   with verify code 85. Adding an AKID matching the CA's Subject Key Identifier
   would fix it.

4. **`--http-inject-ca` matches the literal path opened rather than the
   resolved file**, so it silently misses other symlinks to the same bundle,
   and injecting into the shared target fixes none of them.

5. **`--extra-allow-syscall` silently ignores unrecognised group names** —
   `bogus_group` is accepted without error — so there is no way to discover
   valid ones.

6. **Landlock denies loopback bind and connect by default** with no
   loopback-scoped escape hatch short of `--disable net-tcp`, which removes TCP
   protection entirely.

7. **The process counter leaks.** zsh subshells increment it without
   decrementing, so a long-running session eventually hits `--max-processes`
   and dies.
