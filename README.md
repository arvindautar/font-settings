# font-settings

Consistent, sharp font rendering on GNOME (Fedora / Bluefin) across GTK apps,
Flatpak apps and Brave, applied with one command and re-applied at every login.

Fonts: **Adwaita Sans** (UI, sans-serif), **JetBrains Mono** (monospace),
**Noto Serif** (serif).

## Install

```bash
git clone <this repo> ~/font-settings
cd ~/font-settings
./install.sh
```

Then log out and back in once. Close Brave before installing, or let the login
service pick it up next time you log in.

`install.sh` copies everything to `~/.local/share/font-settings` and enables a
systemd user service, `font-settings.service`, that runs `apply.sh` at every
login. If GNOME settings get reset or Brave is reinstalled, the settings come
back on the next login without doing anything.

To change a value, edit `settings.env` and run `./install.sh` again.

## What it sets

| Layer | Where | What |
|---|---|---|
| fontconfig | `~/.config/fontconfig/fonts.conf` | Antialiasing, slight hinting, RGB subpixel, LCD filter; `sans-serif`/`system-ui` → Adwaita Sans, `monospace` → JetBrains Mono, `serif` → Noto Serif |
| FreeType | `~/.config/environment.d/fonts.conf` | Stem darkening (slightly heavier text) for GTK and Firefox. Brave bundles its own FreeType and ignores it. |
| Flatpak | `flatpak override --user` | Gives all Flatpak apps read-only access to `~/.config/fontconfig` |
| GNOME | `org.gnome.desktop.interface` | UI, document and monospace fonts, antialiasing, hinting, subpixel order, text scaling |
| Brave | `Preferences` of each profile (Flatpak and native) | Standard, sans-serif, serif and fixed-width fonts |

### Why Brave needs its own step

Chromium-based browsers don't take the generic web fonts (`sans-serif`,
`serif`, `monospace`, and the default for pages that set no font) from
fontconfig. They come from the browser's font settings, which default to Times
New Roman and Arial. Chromium also ignores fontconfig substitutions for named
fonts unless the replacement is metric-compatible, like Arial → Liberation Sans.
So `apply.sh` writes the fonts straight into Brave's `Preferences`, which is
the same as setting them in `brave://settings/fonts`. That step is skipped
while Brave is running, because Brave would overwrite the file on exit.

## Uninstall

```bash
./uninstall.sh
```

This removes the login service, restores any config files that existed before
the first install (saved as `*.font-settings.orig`) or deletes them, removes
the Flatpak override, resets the GNOME font keys to their defaults and clears
Brave's custom fonts.

## Requirements

GNOME, `bash`, `python3`, `systemd --user`. Flatpak and Brave are optional.
The fonts themselves (Adwaita Sans, JetBrains Mono, Noto Serif) ship with
Bluefin. On other distros, install them first.
