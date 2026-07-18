# Navigation
alias ..='cd ..'
alias ...='cd ../..'

# Listing
alias ls='eza --icons=auto'
alias l='eza --icons=auto'
alias ll='eza -lh --git --icons=auto'
alias la='eza -lah --git --icons=auto'
alias lt='eza --tree --level=2 --icons=auto'
alias lta='eza --tree --all --level=2 --icons=auto'
alias lg='eza -lah --git --icons=auto'
alias lm='eza -lah --sort=modified --reverse --git --icons=auto'
alias ld='eza -lD --icons=auto'

# Editor
alias v='nvim'
alias vim='nvim'

# Git
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'

# tmux
alias ta='tmux attach'
alias tls='tmux ls'
