autoload -Uz compinit

# Cache completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Pretty menu
zstyle ':completion:*' menu select

compinit
