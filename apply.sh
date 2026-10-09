#!/usr/bin/env bash
# Apply font settings for GNOME, fontconfig, Flatpak apps and Brave.
# Safe to run repeatedly; it is also run at every login by font-settings.service.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=settings.env
source "$HERE/settings.env"

log() { printf '[font-settings] %s\n' "$*"; }

install_file() { # src dest
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then return; fi
  if [[ -f "$dest" && ! -f "$dest.font-settings.orig" ]]; then
    cp -p "$dest" "$dest.font-settings.orig"
  fi
  cp "$src" "$dest"
  log "updated $dest"
}

# --- fontconfig + FreeType ------------------------------------------------
install_file "$HERE/files/fontconfig/fonts.conf"     "$HOME/.config/fontconfig/fonts.conf"
install_file "$HERE/files/environment.d/fonts.conf"  "$HOME/.config/environment.d/fonts.conf"

# --- Flatpak: let every app read ~/.config/fontconfig ----------------------
if command -v flatpak >/dev/null; then
  if ! flatpak override --user --show 2>/dev/null | grep -q 'xdg-config/fontconfig:ro'; then
    if flatpak override --user --filesystem=xdg-config/fontconfig:ro; then
      log "granted Flatpak apps read access to fontconfig"
    else
      log "could not set Flatpak override"
    fi
  fi
fi

# --- GNOME -----------------------------------------------------------------
if command -v gsettings >/dev/null && gsettings list-schemas 2>/dev/null | grep -qx org.gnome.desktop.interface; then
  set_gs() { # key value(gvariant)
    if [[ "$(gsettings get org.gnome.desktop.interface "$1")" != "$2" ]]; then
      if gsettings set org.gnome.desktop.interface "$1" "$2"; then
        log "gsettings $1 = $2"
      else
        log "could not set gsettings $1"
      fi
    fi
  }
  set_gs font-name           "'$GNOME_FONT_NAME'"
  set_gs document-font-name  "'$GNOME_DOCUMENT_FONT_NAME'"
  set_gs monospace-font-name "'$GNOME_MONOSPACE_FONT_NAME'"
  set_gs font-antialiasing   "'$GNOME_FONT_ANTIALIASING'"
  set_gs font-hinting        "'$GNOME_FONT_HINTING'"
  set_gs font-rgba-order     "'$GNOME_FONT_RGBA_ORDER'"
  set_gs text-scaling-factor "$GNOME_TEXT_SCALING_FACTOR"
fi

# --- Brave ----------------------------------------------------------------
# Chromium ignores fontconfig aliases for named fonts and takes the generic
# families from its own Preferences, so they are set there directly.
BRAVE_DIRS=(
  "$HOME/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser"  # Flatpak
  "$HOME/.config/BraveSoftware/Brave-Browser"                            # native
)
if pgrep -f '(/app/brave/brave|/opt/brave.com/brave/brave)( |$)' >/dev/null; then
  log "Brave is running; skipping Brave (close it and run again, or log out/in)"
else
  for dir in "${BRAVE_DIRS[@]}"; do
    # Only touch installs that exist (Flatpak installed or profile present).
    if [[ "$dir" == *com.brave.Browser* ]]; then
      flatpak info com.brave.Browser >/dev/null 2>&1 || [[ -d "$dir" ]] || continue
    else
      [[ -d "$dir" ]] || continue
    fi
    python3 - "$dir" "$BRAVE_FONT_STANDARD" "$BRAVE_FONT_SANS" "$BRAVE_FONT_SERIF" "$BRAVE_FONT_FIXED" <<'EOF'
import json, os, shutil, sys, glob
root, standard, sans, serif, fixed = sys.argv[1:]
want = {"standard": standard, "sansserif": sans, "serif": serif, "fixed": fixed}
profiles = [p for p in glob.glob(os.path.join(root, "*")) if os.path.isfile(os.path.join(p, "Preferences"))]
if not profiles:  # fresh install: seed Default so the first launch already uses these fonts
    profiles = [os.path.join(root, "Default")]
for prof in profiles:
    path = os.path.join(prof, "Preferences")
    prefs = {}
    if os.path.exists(path):
        with open(path) as f:
            prefs = json.load(f)
    fonts = prefs.setdefault("webkit", {}).setdefault("webprefs", {}).setdefault("fonts", {})
    if all(fonts.get(k, {}).get("Zyyy") == v for k, v in want.items()):
        continue
    if os.path.exists(path) and not os.path.exists(path + ".font-settings.orig"):
        shutil.copy2(path, path + ".font-settings.orig")
    for k, v in want.items():
        fonts.setdefault(k, {})["Zyyy"] = v
    os.makedirs(prof, exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(prefs, f, separators=(",", ":"))
    os.replace(tmp, path)
    print(f"[font-settings] updated Brave fonts in {path}")
EOF
  done
fi
