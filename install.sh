#!/usr/bin/env bash
# Install font settings and re-apply them automatically at every login.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.local/share/font-settings"
UNIT_DIR="$HOME/.config/systemd/user"

# Copy the payload so the login service keeps working if this repo moves.
mkdir -p "$DEST" "$UNIT_DIR"
cp -r "$HERE/apply.sh" "$HERE/settings.env" "$HERE/files" "$DEST/"
chmod +x "$DEST/apply.sh"
cp "$HERE/systemd/font-settings.service" "$UNIT_DIR/"

systemctl --user daemon-reload
systemctl --user enable font-settings.service >/dev/null 2>&1
echo "[font-settings] enabled font-settings.service (runs at every login)"

"$DEST/apply.sh"

echo "[font-settings] done. Log out and back in for FreeType stem darkening to reach all apps."
