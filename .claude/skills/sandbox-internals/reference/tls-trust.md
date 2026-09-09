# TLS trust under the MITM proxy

When Sandlock's HTTP policy is active, its supervisor terminates TLS and
re-signs with a generated CA, so clients inside the sandbox must trust that CA.
`--http-inject-ca` adds it to a trust bundle. There were two independent
problems, and they surface in that order. The first is fixed upstream as of
`sandlock 0.8.7`; the second remains.

## 1. Injection was per-path, not per-file (fixed in 0.8.7)

Through `sandlock 0.8.6`, `--http-inject-ca` matched the **literal path a
client opens**, not the file that path resolves to. On Arch,
`/etc/ssl/cert.pem` and `/etc/ssl/certs/ca-certificates.crt` are separate
symlinks to `/etc/ca-certificates/extracted/tls-ca-bundle.pem`, and OpenSSL
defaults to the former while curl reads the latter. Injecting one path fixed
curl and left Python failing with `unable to get local issuer certificate`.

Injecting into the shared *target* did not help either. Measured on `0.8.6`,
with only `/etc/ca-certificates/extracted/tls-ca-bundle.pem` injected:

    /etc/ca-certificates/extracted/tls-ca-bundle.pem   122 certs
    /etc/ssl/certs/ca-certificates.crt                 121 certs
    /etc/ssl/cert.pem                                  121 certs

which is what established that the matching was on the path string.

`sandlock 0.8.7` canonicalises both the opened path and the declared inject
paths before comparing (upstream commit `0dae1d3d`, "ca_inject: follow
symlinks when matching bundle paths"). Re-measured: injecting only the target,
or only `/etc/ssl/cert.pem`, now yields 122 certs at all three paths.

`bin/sandbox` therefore injects only the canonical
`/etc/ca-certificates/extracted/tls-ca-bundle.pem`. On a Sandlock older than
`0.8.7` that leaves `/etc/ssl/cert.pem` and
`/etc/ssl/certs/ca-certificates.crt` uninjected, so OpenSSL and curl fail.

Setting `SSL_CERT_FILE` / `REQUESTS_CA_BUNDLE` to one injected path also
works, but was rejected: it overrides whatever the user or program had set,
forces a single bundle, and only helps clients that honour those variables.

## 2. MITM leaf certificates omit the Authority Key Identifier

Upstream defect, still present in `0.8.7`. Sandlock's generated leaves carry
only a Subject Alternative Name extension, while its CA does have a Subject
Key Identifier. Modern OpenSSL in strict mode then rejects the chain with
`X509_V_ERR_MISSING_AKID` (verify code 85), which Python reports as
`certificate verify failed: Missing Authority Key Identifier`.

Practical effect, all measured with the CA injected into every bundle path:

| client | result |
|---|---|
| curl | works (worked before the multi-path fix too) |
| node / npm | works (also has `NODE_EXTRA_CA_CERTS`) |
| python 3.12 | works — failed before the multi-path fix (measured on `0.8.6`) |
| python 3.14 | still fails on `0.8.7`: strict X.509 is on by default, so it hits the AKID defect |

Only fixable upstream. `ssl.VERIFY_X509_STRICT` cannot be cleared through an
environment variable, and disabling verification wholesale is not worth it.
