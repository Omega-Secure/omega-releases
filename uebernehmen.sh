#!/usr/bin/env bash
#
#  Ein frisch signiertes Release hierher übernehmen.
#  ------------------------------------------------------------------
#  Aufruf im entpackten Release-Ordner (dort, wo public/ liegt):
#
#      /pfad/zu/omega-releases/uebernehmen.sh wallet 1.4.9
#      /pfad/zu/omega-releases/uebernehmen.sh stack  1.3.1
#
#  Kopiert nur, was öffentlich ist: Manifest, beide Signaturen, die
#  Metadaten und die öffentlichen Schlüssel. Sonst nichts — kein
#  Quellcode, keine Konfiguration, keine Schlüssel mit privatem Teil.
#
#  Danach prüft es beide Signaturen gegen das übernommene Manifest.
#  Was hier landet, ist also nachweislich gültig.
#
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
PRODUKT="${1:-}"
VERSION="${2:-}"

say()  { printf '\n\033[1;31m▸ %s\033[0m\n' "$*"; }
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[0;33m!\033[0m %s\n' "$*"; }
fail() { printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

case "$PRODUKT" in
  wallet|stack) ;;
  *) fail "Aufruf:  uebernehmen.sh (wallet|stack) VERSION
   Beispiel:  $REPO/uebernehmen.sh wallet 1.4.9" ;;
esac
[ -n "$VERSION" ] || fail "Die Version fehlt.  Beispiel:  uebernehmen.sh $PRODUKT 1.4.9"
echo "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail "Version muss MAJOR.MINOR.PATCH sein."

QUELLE="public/releases/$VERSION"
[ -d "$QUELLE" ] || fail "$QUELLE gibt es hier nicht.
   Dieses Skript wird im entpackten Release-Ordner aufgerufen — dort, wo public/ liegt.
   Aktuell: $(pwd)"

ZIEL="$REPO/$PRODUKT/$VERSION"
if [ -d "$ZIEL" ] && [ -f "$ZIEL/SHA256SUMS" ]; then
  if cmp -s "$QUELLE/SHA256SUMS" "$ZIEL/SHA256SUMS"; then
    ok "$PRODUKT $VERSION liegt bereits hier und ist identisch — nichts zu tun."
    exit 0
  fi
  fail "$PRODUKT $VERSION liegt hier schon, mit ANDEREM Manifest.
   Eine veröffentlichte Fassung ändert sich nicht. Entweder wurde neu signiert,
   ohne die Version zu erhöhen — dann bitte die Versionsnummer erhöhen — oder
   hier stimmt etwas grundsätzlich nicht."
fi

say "Übernehme $PRODUKT $VERSION"
mkdir -p "$ZIEL"
for f in SHA256SUMS SHA256SUMS.minisig build-info.json; do
  [ -f "$QUELLE/$f" ] || fail "$QUELLE/$f fehlt — ist das Release vollständig signiert?"
  cp "$QUELLE/$f" "$ZIEL/$f"
done
if [ -f "$QUELLE/SHA256SUMS.mldsa" ]; then
  cp "$QUELLE/SHA256SUMS.mldsa" "$ZIEL/SHA256SUMS.mldsa"
  ok "Manifest, beide Signaturen und Metadaten übernommen"
else
  warn "Keine ML-DSA-Signatur in diesem Release — nur die minisign-Signatur übernommen."
fi

mkdir -p "$REPO/keys"
[ -f public/.well-known/minisign.pub ]     && cp public/.well-known/minisign.pub     "$REPO/keys/minisign.pub"
[ -f public/.well-known/omega-mldsa.pub ]  && cp public/.well-known/omega-mldsa.pub  "$REPO/keys/omega-mldsa.pub"
mkdir -p "$REPO/werkzeug"
[ -f public/omega-pqsign.py ] && cp public/omega-pqsign.py "$REPO/werkzeug/omega-pqsign.py"
ok "Öffentliche Schlüssel und Prüfwerkzeug aktualisiert"

# ── gegenprüfen, bevor es in die Historie wandert ──────────────────
say "Signaturen gegenprüfen"
if command -v minisign >/dev/null 2>&1; then
  minisign -Vm "$ZIEL/SHA256SUMS" -p "$REPO/keys/minisign.pub" >/dev/null \
    || fail "Die minisign-Signatur ist ungültig — nichts übernommen, was nicht trägt."
  ok "Ed25519 gültig"
else
  warn "minisign nicht installiert — Ed25519-Signatur ungeprüft übernommen."
fi

if [ -f "$ZIEL/SHA256SUMS.mldsa" ]; then
  if python3 -c 'import dilithium_py' 2>/dev/null; then
    python3 "$REPO/werkzeug/omega-pqsign.py" verify \
      "$ZIEL/SHA256SUMS" "$ZIEL/SHA256SUMS.mldsa" "$REPO/keys/omega-mldsa.pub" >/dev/null \
      || fail "Die ML-DSA-Signatur ist ungültig — nichts übernommen, was nicht trägt."
    ok "ML-DSA-65 gültig"
  else
    warn "dilithium-py fehlt — ML-DSA-Signatur ungeprüft übernommen.  pip3 install dilithium-py"
  fi
fi

ANZAHL=$(wc -l < "$ZIEL/SHA256SUMS" | tr -d ' ')
cat <<EOF

──────────────────────────────────────────────────────────────
  $PRODUKT $VERSION übernommen — $ANZAHL Dateien im Manifest.

  Nächster Schritt:

      cd $REPO
      git add .
      git commit -m "$PRODUKT $VERSION"
      git push

──────────────────────────────────────────────────────────────
EOF
