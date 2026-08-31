#!/usr/bin/env bash
#
#  Gleicht die laufenden Websites gegen dieses Repository ab.
#  ------------------------------------------------------------------
#  Das ist der eigentliche Zweck der Sache. Manifest und Signaturen
#  liegen sonst nur auf demselben Server, den sie absichern sollen.
#  Wer den Server übernimmt, kann den privaten Schlüssel nicht stehlen,
#  aber eine ältere, echt signierte Fassung zurückspielen — mit gültiger
#  Signatur, unbemerkt.
#
#  Hier liegt dieselbe Angabe an einem zweiten, unveränderlichen Ort.
#  Laufen beide auseinander, sagt dieses Skript es.
#
#  Aufruf:
#      ./pruefe.sh              beide Websites
#      ./pruefe.sh wallet       nur eine
#
#  Braucht nur curl. Für die Signaturprüfung zusätzlich minisign und
#  (für ML-DSA) python3 mit dilithium-py — fehlen sie, prüft das Skript
#  wenigstens Version und Manifest.
#
set -uo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO"

rot=$'\033[1;31m'; gruen=$'\033[0;32m'; gelb=$'\033[0;33m'; fett=$'\033[1m'; aus=$'\033[0m'
FEHLER=0

kopf()  { printf '\n%s▸ %s%s\n' "$fett" "$*" "$aus"; }
ok()    { printf '  %s✓%s %s\n' "$gruen" "$aus" "$*"; }
warn()  { printf '  %s!%s %s\n' "$gelb" "$aus" "$*"; }
alarm() { printf '  %s✗ %s%s\n' "$rot" "$*" "$aus"; FEHLER=$((FEHLER + 1)); }

# Versionsvergleich: gibt "neuer", "aelter" oder "gleich" zurück
vergleich() {
  [ "$1" = "$2" ] && { echo gleich; return; }
  if [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]; then
    echo aelter
  else
    echo neuer
  fi
}

pruefe_eine() {
  local kurz="$1" domain="$2"
  # Gegen einen Testserver laufen lassen:  OMEGA_TEST_BASIS=http://127.0.0.1:9000
  # Ohne die Variable immer gegen die echte Adresse ueber HTTPS.
  local basis="${OMEGA_TEST_BASIS:-https://$domain}"
  kopf "$domain"

  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  # --- 1. Welche Fassung liefert die Website gerade aus? ---
  if ! curl -fsS --max-time 20 "$basis/releases/latest.json" -o "$tmp/latest.json"; then
    alarm "latest.json nicht erreichbar — Website erreichbar? Deployment gelaufen?"
    return
  fi
  local live
  live=$(grep -o '"version"[^,]*' "$tmp/latest.json" | head -1 | cut -d'"' -f4)
  [ -n "$live" ] || { alarm "In latest.json steht keine Version."; return; }

  # --- 2. Welche Fassung ist hier die neueste? ---
  local hier
  hier=$(ls -1 "$REPO/$kurz" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
  if [ -z "$hier" ]; then
    warn "Für $kurz liegt hier noch keine Fassung — nach dem nächsten Release uebernehmen.sh laufen lassen."
    printf '    Website liefert gerade: %s\n' "$live"
    return
  fi

  printf '  Website: %s   Repository: %s\n' "$live" "$hier"

  case "$(vergleich "$live" "$hier")" in
    gleich) ok "Gleiche Fassung." ;;
    neuer)
      warn "Die Website ist neuer als das Repository."
      printf '    Das ist normal direkt nach einem Deployment. Nachziehen mit uebernehmen.sh %s %s\n' "$kurz" "$live" ;;
    aelter)
      alarm "Die Website liefert eine ÄLTERE Fassung aus als hier bekannt ($live statt $hier)."
      printf '    Entweder ist ein Deployment steckengeblieben — oder jemand hat eine alte\n'
      printf '    Fassung zurückgespielt. Beides gehört angesehen, das zweite sofort.\n' ;;
  esac

  # --- 3. Ist das Manifest zu dieser Fassung identisch? ---
  if [ -f "$REPO/$kurz/$live/SHA256SUMS" ]; then
    if curl -fsS --max-time 20 "$basis/releases/$live/SHA256SUMS" -o "$tmp/SHA256SUMS"; then
      if cmp -s "$tmp/SHA256SUMS" "$REPO/$kurz/$live/SHA256SUMS"; then
        ok "Manifest von $live stimmt Zeichen für Zeichen überein."
      else
        alarm "Das Manifest von $live weicht ab!"
        printf '    Eine veröffentlichte Fassung ändert sich nicht. Das ist der Fall,\n'
        printf '    der nie vorkommen darf. Unterschiede:\n'
        diff "$REPO/$kurz/$live/SHA256SUMS" "$tmp/SHA256SUMS" | head -8 | sed 's/^/      /'
      fi
    else
      alarm "Manifest von $live nicht abrufbar."
    fi

    # --- 4. Signaturen der ausgelieferten Fassung nachrechnen ---
    if command -v minisign >/dev/null 2>&1 && [ -f keys/minisign.pub ] \
       && curl -fsS --max-time 20 "$basis/releases/$live/SHA256SUMS.minisig" -o "$tmp/sig" 2>/dev/null; then
      if minisign -Vm "$tmp/SHA256SUMS" -x "$tmp/sig" -p keys/minisign.pub >/dev/null 2>&1; then
        ok "Ed25519-Signatur der Website gültig (gegen den Schlüssel aus diesem Repository)."
      else
        alarm "Die Ed25519-Signatur der ausgelieferten Fassung ist UNGÜLTIG."
      fi
    fi

    if python3 -c 'import dilithium_py' 2>/dev/null && [ -f keys/omega-mldsa.pub ] \
       && curl -fsS --max-time 20 "$basis/releases/$live/SHA256SUMS.mldsa" -o "$tmp/mldsa" 2>/dev/null; then
      if python3 werkzeug/omega-pqsign.py verify "$tmp/SHA256SUMS" "$tmp/mldsa" keys/omega-mldsa.pub >/dev/null 2>&1; then
        ok "ML-DSA-65-Signatur der Website gültig."
      else
        alarm "Die ML-DSA-Signatur der ausgelieferten Fassung ist UNGÜLTIG."
      fi
    fi
  fi
}

printf '%sAbgleich Website ↔ Repository%s\n' "$fett" "$aus"
printf 'Stand: %s\n' "$(date -u '+%Y-%m-%d %H:%M UTC')"

case "${1:-beide}" in
  wallet) pruefe_eine wallet wallet.omegastack.io ;;
  stack)  pruefe_eine stack  omegastack.io ;;
  beide)  pruefe_eine wallet wallet.omegastack.io; pruefe_eine stack omegastack.io ;;
  *)      echo "Aufruf:  ./pruefe.sh [wallet|stack]"; exit 1 ;;
esac

echo
if [ "$FEHLER" -eq 0 ]; then
  printf '%s✓ Nichts zu beanstanden.%s\n\n' "$gruen" "$aus"
  exit 0
fi
printf '%s✗ %d Punkt(e) zum Ansehen.%s\n\n' "$rot" "$FEHLER" "$aus"
exit 1
