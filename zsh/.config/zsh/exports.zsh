export EDITOR=nvim
export VISUAL=nvim
export PAGER=less

# User binaries
export PATH="$HOME/.local/bin:$PATH"

if [[ -f ~/.dotfiles/secrets/env ]]; then
  source ~/.dotfiles/secrets/env
fi
