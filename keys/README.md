# Öffentliche Schlüssel / Public keys

    minisign.pub       Ed25519 — für `minisign -V`
    omega-mldsa.pub    ML-DSA-65 (FIPS 204) — für `werkzeug/omega-pqsign.py verify`

Dieselben Schlüssel liegen auf den Websites unter `/.well-known/minisign.pub`
und `/.well-known/omega-mldsa.pub`. Beide Orte müssen übereinstimmen — ein
Schlüsselwechsel wird im Changelog der Websites angekündigt.

The same keys are served by the websites under `/.well-known/minisign.pub` and
`/.well-known/omega-mldsa.pub`. Both locations must match — a key rotation is
announced in the websites' changelog.
