# Omega Releases — signierte Auslieferungen

Dieses Repository führt die **Manifeste und Signaturen** der veröffentlichten
Fassungen von `omegastack.io` und `wallet.omegastack.io`. Es enthält keinen
Quellcode und keine Zugangsdaten — nur das, was ohnehin öffentlich auf den
Websites steht.

## Wozu das gut ist

Manifest und Signaturen liegen sonst nur auf demselben Server, den sie
absichern sollen. Wer diesen Server übernimmt, kann den privaten Schlüssel
zwar nicht stehlen — aber er kann eine **ältere, echt signierte Fassung
zurückspielen**, etwa eine mit einer Lücke, die längst geschlossen ist. Die
Signatur wäre gültig, und niemandem fiele etwas auf.

Liegen dieselben Manifeste zusätzlich hier, wird genau das sichtbar: die
Git-Historie ist unveränderlich und liegt woanders. `pruefe.sh` und der
tägliche Lauf unter `.github/workflows/` vergleichen beides automatisch.

Das ist der ganze Zweck. Kein Deployment, kein Signieren, keine Geheimnisse.

## Was hier liegt

    keys/minisign.pub          öffentlicher Schlüssel, Ed25519 (minisign)
    keys/omega-mldsa.pub       öffentlicher Schlüssel, ML-DSA-65 (FIPS 204)

    wallet/<version>/          je Fassung von wallet.omegastack.io
    stack/<version>/           je Fassung von omegastack.io
        SHA256SUMS             das Manifest: ein SHA-256 je ausgelieferter Datei
        SHA256SUMS.minisig     Signatur, Ed25519
        SHA256SUMS.mldsa       Signatur, ML-DSA-65
        build-info.json        Metadaten der Fassung

    werkzeug/omega-pqsign.py   Prüfwerkzeug für die ML-DSA-Signatur
    uebernehmen.sh             übernimmt ein frisch signiertes Release hierher
    pruefe.sh                  gleicht die Websites gegen dieses Repository ab

## Eine Fassung selbst nachprüfen

    # Ed25519
    minisign -Vm wallet/1.4.9/SHA256SUMS -p keys/minisign.pub

    # ML-DSA-65 (post-quantensicher)
    pip3 install dilithium-py
    python3 werkzeug/omega-pqsign.py verify \
        wallet/1.4.9/SHA256SUMS wallet/1.4.9/SHA256SUMS.mldsa keys/omega-mldsa.pub

Beide Signaturen decken dasselbe Manifest ab. Fällt eines der Verfahren,
trägt das andere.

## Abgleich mit der laufenden Website

    ./pruefe.sh

Das Skript holt von beiden Websites die aktuell ausgelieferte Fassung und
vergleicht sie mit dem, was hier liegt. Drei Fälle:

- **gleich** — alles in Ordnung.
- **Website älter als das Repository** — jemand hat eine alte Fassung
  zurückgespielt, oder ein Deployment ist steckengeblieben. Nachsehen.
- **gleiche Version, anderes Manifest** — das darf nicht vorkommen. Eine
  veröffentlichte Fassung ändert sich nicht. Ernst nehmen.

## Nach jedem Release

Auf dem Rechner, auf dem signiert wurde, im entpackten Release-Ordner:

    /pfad/zu/omega-releases/uebernehmen.sh wallet 1.4.9
    cd /pfad/zu/omega-releases
    git add . && git commit -m "wallet 1.4.9" && git push

## Was hier niemals hineingehört

- private Schlüssel (`*.key`, `~/.minisign/…`)
- `config.php`, `report-config.php`, `bounty-db.php` und ähnliche Konfigurationen
- Datenbank-Abzüge, Zugangsdaten, API-Schlüssel

**Git vergisst nichts.** Eine Datei, die einmal committet wurde, bleibt in der
Historie — auch nach `git rm`, auch in einem privaten Repository. Gerät ein
Geheimnis hinein, hilft nur: rotieren und das Repository neu anfangen.

Als Netz liegt unter `.githooks/pre-commit` eine Prüfung, die Commits mit
verdächtigem Inhalt abbricht. Einmalig einschalten:

    git config core.hooksPath .githooks
