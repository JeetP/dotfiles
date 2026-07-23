# ~/.config/zsh/functions.zsh
#
ask() {
    llm -t ask "$@" | glow
}
