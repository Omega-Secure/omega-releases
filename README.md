# Omega Releases

Signaturen, Manifeste und öffentliche Schlüssel der veröffentlichten Fassungen
von **omegastack.io** und **wallet.omegastack.io** — als zweiter, unabhängiger
Ort neben den Websites selbst.

*English below.*

## Wozu

Jede ausgelieferte Fassung der Websites wird signiert: Ein Manifest listet die
SHA-256-Prüfsumme jeder Datei, und dieses Manifest trägt zwei Signaturen —
klassisch (Ed25519, minisign) und post-quantensicher (ML-DSA-65, FIPS 204).
Manifest und Signaturen liegen auf den Websites unter `/releases/`.

Dieses Repository führt dieselben Manifeste und Signaturen ein zweites Mal,
mit unveränderlicher Historie und ausserhalb der Server. Damit lässt sich
prüfen, dass die Website genau das ausliefert, was signiert wurde — und dass
niemand eine ältere, ebenfalls echt signierte Fassung zurückgespielt hat.

## Inhalt

    keys/minisign.pub          öffentlicher Schlüssel, Ed25519 (minisign)
    keys/omega-mldsa.pub       öffentlicher Schlüssel, ML-DSA-65 (FIPS 204)

    wallet/<version>/          je veröffentlichte Fassung von wallet.omegastack.io
    stack/<version>/           je veröffentlichte Fassung von omegastack.io
        SHA256SUMS             Manifest: ein SHA-256 je ausgelieferter Datei
        SHA256SUMS.minisig     Signatur, Ed25519
        SHA256SUMS.mldsa       Signatur, ML-DSA-65
        build-info.json        Metadaten der Fassung

    werkzeug/omega-pqsign.py   Prüfwerkzeug für die ML-DSA-Signatur
    pruefe.sh                  gleicht die laufenden Websites gegen dieses Repository ab

## Eine Fassung prüfen

Ed25519 mit [minisign](https://jedisct1.github.io/minisign/):

    minisign -Vm wallet/1.4.9/SHA256SUMS -p keys/minisign.pub

ML-DSA-65 mit dem mitgelieferten Werkzeug (braucht Python 3 und `dilithium-py`):

    pip3 install dilithium-py
    python3 werkzeug/omega-pqsign.py verify \
        wallet/1.4.9/SHA256SUMS wallet/1.4.9/SHA256SUMS.mldsa keys/omega-mldsa.pub

Beide Signaturen decken dasselbe Manifest ab. Fällt eines der Verfahren, trägt
das andere.

Die Schlüssel hier müssen mit denen auf den Websites übereinstimmen:
`https://omegastack.io/.well-known/minisign.pub` und
`https://omegastack.io/.well-known/omega-mldsa.pub` (ebenso unter
`wallet.omegastack.io`). Weichen sie ab, stimmt etwas nicht.

## Die laufenden Websites abgleichen

    ./pruefe.sh

holt von beiden Websites die aktuell ausgelieferte Fassung, prüft ihre
Signaturen und vergleicht Version und Manifest mit diesem Repository. Ein
Lauf unter `.github/workflows/` macht dasselbe täglich.

## Sicherheitslücke gefunden?

Bitte über das Bug-Bounty-Programm melden: <https://omegastack.io/bounty.html>

---

# Omega Releases (English)

Signatures, manifests and public keys for every published version of
**omegastack.io** and **wallet.omegastack.io** — a second, independent record
alongside the websites themselves.

## Why

Every published version is signed: a manifest lists the SHA-256 of each
delivered file, and the manifest carries two signatures — classical (Ed25519,
minisign) and post-quantum (ML-DSA-65, FIPS 204). Manifest and signatures are
served by the websites under `/releases/`.

This repository holds the same manifests and signatures a second time, with an
immutable history and outside the servers. That makes it possible to verify
that a website serves exactly what was signed — and that nobody has rolled
back to an older, equally validly signed version.

## Layout

    keys/minisign.pub          public key, Ed25519 (minisign)
    keys/omega-mldsa.pub       public key, ML-DSA-65 (FIPS 204)
    wallet/<version>/          one directory per published version of wallet.omegastack.io
    stack/<version>/           one directory per published version of omegastack.io
        SHA256SUMS             manifest: one SHA-256 per delivered file
        SHA256SUMS.minisig     signature, Ed25519
        SHA256SUMS.mldsa       signature, ML-DSA-65
        build-info.json        version metadata
    werkzeug/omega-pqsign.py   verifier for the ML-DSA signature
    pruefe.sh                  compares the live websites against this repository

## Verify a version

    minisign -Vm wallet/1.4.9/SHA256SUMS -p keys/minisign.pub

    pip3 install dilithium-py
    python3 werkzeug/omega-pqsign.py verify \
        wallet/1.4.9/SHA256SUMS wallet/1.4.9/SHA256SUMS.mldsa keys/omega-mldsa.pub

The keys in `keys/` must match the ones served at
`https://omegastack.io/.well-known/minisign.pub` and
`https://omegastack.io/.well-known/omega-mldsa.pub`. If they differ, something
is wrong.

## Compare the live sites

    ./pruefe.sh

fetches the currently served version from both websites, verifies its
signatures and compares version and manifest with this repository. A workflow
under `.github/workflows/` does the same daily.

## Found a security issue?

Please report it through the bug bounty programme: <https://omegastack.io/bounty.html>
