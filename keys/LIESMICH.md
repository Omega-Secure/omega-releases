# Öffentliche Schlüssel

Dieser Ordner ist noch leer. Die beiden öffentlichen Schlüssel legt
`uebernehmen.sh` beim ersten Release von selbst hier ab:

    minisign.pub        Ed25519
    omega-mldsa.pub     ML-DSA-65 (FIPS 204)

Beide sind öffentlich und gehören hierher — mit ihnen prüft man Signaturen,
man kann damit keine erzeugen. Die **privaten** Gegenstücke liegen
ausschliesslich auf dem Rechner, auf dem signiert wird (`~/.minisign/`),
und dürfen nie in ein Repository geraten.

Ändern sich diese Dateien je, ist das ein Ereignis: entweder wurde ein
Schlüssel bewusst gewechselt — dann gehört das in den Changelog der
Websites — oder etwas stimmt nicht.
