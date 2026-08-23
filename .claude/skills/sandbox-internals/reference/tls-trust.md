# TLS trust under the MITM proxy

When Sandlock's HTTP policy is active, its supervisor terminates TLS and
re-signs with a generated CA, so clients inside the sandbox must trust that CA.
`--http-inject-ca` adds it to a trust bundle. There are two independent
problems, and they surface in that order.

## 1. Injection is per-path, not per-file

`--http-inject-ca` matches the **literal path a client opens**, not the file
that path resolves to. On Arch, `/etc/ssl/cert.pem` and
`/etc/ssl/certs/ca-certificates.crt` are separate symlinks to
`/etc/ca-certificates/extracted/tls-ca-bundle.pem`, and OpenSSL defaults to the
former while curl reads the latter. Injecting one path fixes curl and leaves
Python failing with `unable to get local issuer certificate`.

Injecting into the shared *target* does not help either. Measured, with only
`/etc/ca-certificates/extracted/tls-ca-bundle.pem` injected:

    /etc/ca-certificates/extracted/tls-ca-bundle.pem   122 certs
    /etc/ssl/certs/ca-certificates.crt                 121 certs
    /etc/ssl/cert.pem                                  121 certs

which is what establishes that the matching is on the path string.

`--http-inject-ca` is repeatable, so the fix is to inject into every bundle
path that exists — the `ca_bundle_paths` array in `bin/sandbox`. Verified: all
three then report 122 certs, and python3.12 and curl both succeed with **no
environment overrides**.

Setting `SSL_CERT_FILE` / `REQUESTS_CA_BUNDLE` to the one injected path also
works, but was rejected: it overrides whatever the user or program had set,
forces a single bundle, and only helps clients that honour those variables.

## 2. MITM leaf certificates omit the Authority Key Identifier

Upstream defect. Sandlock's generated leaves carry only a Subject Alternative
Name extension, while its CA does have a Subject Key Identifier. Modern OpenSSL
in strict mode then rejects the chain with `X509_V_ERR_MISSING_AKID` (verify
code 85).

Practical effect, all measured with the multi-path injection in place:

| client | result |
|---|---|
| curl | works (worked before the fix too) |
| node / npm | works (also has `NODE_EXTRA_CA_CERTS`) |
| python 3.12 | works — failed before the fix |
| python 3.14 | still fails: strict X.509 is on by default, so it hits the AKID defect |

Only fixable upstream. `ssl.VERIFY_X509_STRICT` cannot be cleared through an
environment variable, and disabling verification wholesale is not worth it.
