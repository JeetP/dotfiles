# Dotfiles

Portable macOS dotfiles managed with GNU Stow.

## Prerequisites

- macOS
- Git
- Homebrew

## Install

```bash
git clone git@github.com:JeetP/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap
```

Bootstrap installs the Brewfile dependencies, stows Git, tmux, Starship,
Neovim, and the Zsh fragments, then appends a guarded loader to the existing
`~/.zshrc`. Existing shell content is preserved. It also runs Lazy.nvim and
requests the Mason tools `stylua`, `shfmt`, and `tree-sitter-cli`.

The `ask` helper's `llm` and `glow` commands are installed as Homebrew
formulae by the Brewfile.

Import the iTerm2 appearance manually from `iterm/JeetP.json` (or import
`iterm/TokyoNightStorm.itermcolors` for colors). See `iterm/README.md`.

Per-machine settings belong in the untracked `~/.zshrc.local`; that file is
sourced after the shared fragments.

The first Neovim launch may finish plugin or Mason installation. Open `:Mason`
to verify the tools.

## Uninstall

```bash
~/.dotfiles/bootstrap --uninstall
```

This removes the managed shell blocks, unstows packages, and restores files
backed up during installation when their targets are still untouched. It does
not uninstall Homebrew packages, fonts, or iTerm2 profiles.

## Structure

`git/`, `nvim/`, `starship/`, `tmux/`, and `zsh/` are GNU Stow packages;
`iterm/` contains the terminal appearance assets.
