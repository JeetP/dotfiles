# ~/.config/zsh/functions.zsh

ai() {
    local command
    command=$(cmd "$*")

    echo "Suggested command:"
    echo "$command"
    echo

    read -q "REPLY?Execute? [y/N] "
    echo

    [[ $REPLY =~ ^[Yy]$ ]] && eval "$command"
}
