#!/usr/bin/env bash
# Remove font settings and the login service, restoring defaults or the
# originals saved on first apply (*.font-settings.orig).
set -euo pipefail

log() { printf '[font-settings] %s\n' "$*"; }

systemctl --user disable font-settings.service >/dev/null 2>&1 || true
rm -f "$HOME/.config/systemd/user/font-settings.service"
systemctl --user daemon-reload
rm -rf "$HOME/.local/share/font-settings"
log "removed login service"

restore_file() {
  local f="$1"
  if [[ -f "$f.font-settings.orig" ]]; then mv -f "$f.font-settings.orig" "$f"; log "restored $f"
  elif [[ -f "$f" ]]; then rm -f "$f"; log "removed $f"; fi
}
restore_file "$HOME/.config/fontconfig/fonts.conf"
restore_file "$HOME/.config/environment.d/fonts.conf"

if command -v flatpak >/dev/null; then
  flatpak override --user --nofilesystem=xdg-config/fontconfig || true
  log "removed Flatpak fontconfig override"
fi

if command -v gsettings >/dev/null; then
  for k in font-name document-font-name monospace-font-name font-antialiasing \
           font-hinting font-rgba-order text-scaling-factor; do
    gsettings reset org.gnome.desktop.interface "$k" || true
  done
  log "reset GNOME font settings to defaults"
fi

if pgrep -f '(/app/brave/brave|/opt/brave.com/brave/brave)( |$)' >/dev/null; then
  log "Brave is running; close it and run uninstall again to reset Brave fonts"
  exit 0
fi
for root in "$HOME/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser" \
            "$HOME/.config/BraveSoftware/Brave-Browser"; do
  [[ -d "$root" ]] || continue
  python3 - "$root" <<'EOF'
import json, os, glob, sys
for path in glob.glob(os.path.join(sys.argv[1], "*", "Preferences")):
    with open(path) as f:
        prefs = json.load(f)
    webprefs = prefs.get("webkit", {}).get("webprefs", {})
    if webprefs.pop("fonts", None) is None:
        continue
    with open(path + ".tmp", "w") as f:
        json.dump(prefs, f, separators=(",", ":"))
    os.replace(path + ".tmp", path)
    print(f"[font-settings] reset Brave fonts in {path}")
EOF
done
