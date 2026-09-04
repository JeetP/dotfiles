# iTerm2 appearance

Import `TokyoNightStorm.json` through iTerm2's Profiles → Other Actions → Import JSON.

The profile uses Tokyo Night Storm (`#24283B` background and `#C0CAF5`
foreground), JetBrainsMonoNF-Regular 15, and powerline glyphs. Light/dark color
separation is disabled so the same Storm palette is used in both macOS modes.

Close iTerm2 before changing preferences when possible. iTerm2 rewrites its
preferences plist on quit; use the GUI import and relaunch if a direct preference
change does not stick. `bootstrap --uninstall` does not remove or revert iTerm2
profiles automatically; remove the imported profile in iTerm2 settings.
