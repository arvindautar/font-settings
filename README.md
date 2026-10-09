# font-settings

**Sharp, consistent fonts everywhere on a GNOME desktop: GNOME apps, Flatpak
apps and the Brave browser. Set up with one command and restored on every
login.**

## What it does

Out of the box on Fedora / Bluefin, fonts look different from app to app:

- GNOME apps follow your font settings, but **Flatpak apps** (Firefox, Brave,
  and so on) run in a sandbox and ignore them. They fall back to other fonts
  and blurrier rendering.
- **Brave** ignores the system font settings for websites and uses its own
  defaults (Times New Roman and Arial). So most web pages show up in
  Liberation fonts instead of your desktop font.

This repo fixes both. It gives every app the same fonts:

| Used for | Font |
|---|---|
| Interface and regular text | **Adwaita Sans** |
| Code and terminals | **JetBrains Mono** |
| Serif text | **Noto Serif** |

It also sets the same rendering everywhere: smooth edges, light hinting and
RGB subpixel rendering for LCD screens. On top of that, letters are drawn
slightly heavier so small text is easier to read.

**Automatic restore:** after installing, a small background service applies
the settings again every time you log in. If GNOME resets your settings, or you
reinstall Brave, the fonts come back on the next login.

## Install

1. **Close Brave.** Brave overwrites its settings file when it exits, so the
   installer skips Brave while it's running. If you forget, the next login
   will catch it.

2. **Download and install:**

   ```bash
   git clone https://github.com/arvindautar/font-settings.git ~/font-settings
   cd ~/font-settings
   ./install.sh
   ```

3. **Log out and log back in** so every app picks up the new settings.

That's it. To check: open `brave://settings/fonts` in Brave. It should show
Adwaita Sans, Noto Serif and JetBrains Mono.

## Change a setting

All choices live in **`settings.env`**: fonts, sizes, smoothing, text scaling
and Brave's fonts. Edit that file, then run the installer again:

```bash
cd ~/font-settings
nano settings.env      # or any editor
./install.sh
```

For example, set `GNOME_TEXT_SCALING_FACTOR="1.25"` for 25% larger text, which
helps on dense laptop screens.

## Uninstall

```bash
cd ~/font-settings
./uninstall.sh
```

This switches off the login service and puts everything back to the defaults.
Close Brave first so its fonts can be reset too.

## What gets changed (details)

| Part | Where | What |
|---|---|---|
| Font matching and rendering | `~/.config/fontconfig/fonts.conf` | Smoothing, hinting and subpixel settings; maps the generic `sans-serif`, `system-ui`, `monospace` and `serif` names to the fonts above |
| Heavier text | `~/.config/environment.d/fonts.conf` | FreeType "stem darkening". Affects GNOME apps and Firefox. Brave uses its own renderer and ignores it. |
| Flatpak apps | `flatpak override --user` | Lets all Flatpak apps read your font settings (read-only) |
| GNOME | Settings → Appearance / Accessibility | Interface, document and monospace fonts, smoothing, hinting and text size |
| Brave (Flatpak or regular install) | Each profile's `Preferences` file | Same as setting the fonts in `brave://settings/fonts` |
| Login service | `~/.config/systemd/user/font-settings.service` | Runs the settings again at every login, from a copy in `~/.local/share/font-settings` |

The first time a config file is replaced, the old version is saved next to it
as `*.font-settings.orig`. Uninstalling puts it back.

### Why Brave needs its own step

Chromium-based browsers take the default web fonts (`sans-serif`, `serif`,
`monospace`, and the font for pages that don't set one) from their own
settings, not from the system. They also ignore system font substitutions
unless the replacement has the same letter widths, like Arial → Liberation
Sans. The only reliable fix is to write the fonts straight into Brave's
settings, which is what the installer does.

## Requirements

- GNOME with `systemd` (Fedora, Bluefin, Silverblue and similar)
- `bash` and `python3`
- Fonts: Adwaita Sans, JetBrains Mono and Noto Serif. All three come with
  Bluefin; on other systems, install them first.
- Flatpak and Brave are optional. Those steps are skipped if they're missing.
