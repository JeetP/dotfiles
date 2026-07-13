# ~/.config/zsh/functions.zsh

cmd() {
  local system_prompt
  system_prompt='You are a Unix terminal assistant. Return ONLY the exact shell command. No markdown, no code fences, no explanations, and no surrounding text. If multiple commands are required, print only the commands on separate lines.'

  llm -m claude-haiku-4.5 -s "$system_prompt" "$@"
}

ask() {
  local system_prompt
  system_prompt='You are a senior software engineer and mentor. Answer concisely (3-8 sentences by default). Use bullets only when they improve clarity. Do not add unnecessary introductions or conclusions. If the question asks for code, provide only the relevant code with a brief explanation. If the user explicitly asks for a detailed explanation, tutorial, or deep dive, then provide one.'

  llm -m claude-haiku-4.5 -s "$system_prompt" "$@"
}
ai() {
    local command
    command=$(cmd "$@") || return

    echo "Suggested command:"
    echo "$command"
    echo

    read -q "REPLY?Execute? [y/N] "
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        eval "$command"
        return $?
    fi

    return 0
}
