# Navigation
alias ..='cd ..'
alias ...='cd ../..'

# Listing
alias ll='eza -lh'
alias la='eza -lah'
alias lt='eza --tree'

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

# llm
# Brief explanations by default
alias ask='llm -s "You are a senior software engineer and mentor. Answer concisely (3-8 sentences by default). Use bullets only when they improve clarity. \ 
  Do not add unnecessary introductions or conclusions. If the question asks for code, provide only the relevant code with a brief explanation. \
  If the user explicitly asks for a detailed explanation, tutorial, or deep dive, then provide one." \
  -m claude-haiku-4.5'

# Commands only
alias cmd='llm -s "You are a Unix terminal assistant. Return ONLY the exact shell command. \
  No markdown, no code fences, no explanations, and no surrounding text. If multiple commands are required, print only the commands on separate lines." \
  -m claude-haiku-4.5'
