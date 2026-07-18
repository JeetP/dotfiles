# ~/.config/zsh/functions.zsh

# Internal common entry point. It deliberately inherits stdin, so every helper
# can accept piped data without special plumbing.
_llm_prompt() {
  local system_prompt=$1 prompt=$2
  llm -s "$system_prompt" "$prompt" | glow
}

llmhelp() {
  print -r -- $'LLM shell helpers\n\nCore\n  ask <question>                         Concise answer\n  cmd <intent>                           Generate a shell command; never runs it\n  ai <intent>                            Generate, show, and confirm before running\n\nDebugging and data\n  explain <command>                      Explain a command, flags, and risks\n  <error output> | fix                   Diagnose an error and suggest a fix\n  debugai <file> [error/question]        Inspect a source file for likely bugs\n  <error output> | debugai <file>        Include piped test or compiler output\n  debugai <file> ... | fix <file>        Generate a minimal unified diff; no auto-edit\n  <data> | pipeai <question>             Analyze logs, JSON, or arbitrary text\n  <data> | dataai <intent>               Generate a data-processing command\n  ctxai <question>                       Troubleshoot with directory, OS, and Git context\n  manai <tool> <question>                Answer using local man page or --help\n\nGit and writing\n  gitai <question>                       Review current Git status and diff\n  commit                                 Draft a commit message from staged changes\n  pr [context]                           Draft a PR title and body against main/master\n  note <text>                            Format rough text as a Markdown note\n  <text> | note                          Format piped text as a Markdown note\n  renameai <file...>                     Preview consistent filename suggestions\n\nSafety and configuration\n  ai asks before execution; no helper edits files automatically.\n  fix <file> returns a diff: review it, then use git apply --check <patch>.\n  LLM_MODEL=<model> <helper> ...         Override the model for one command.\n  DEBUGAI_MAX_BYTES=<bytes> debugai ...  Raise the 200000-byte file limit.\n\nExamples\n  pytest 2>&1 | debugai src/app.py "find the failure" | fix src/app.py\n  journalctl -n 200 | pipeai "identify likely causes"\n  LLM_MODEL=claude-sonnet-4.5 gitai "review for regressions"'
}

# The three primary entry points:
#   ask "question"  -> concise answer
#   cmd "intent"    -> command text only, never executed
#   ai "intent"     -> cmd plus an explicit execution confirmation
cmd() {
  local system_prompt
  system_prompt='You are a Unix terminal assistant. Return ONLY the exact shell command. No markdown, no code fences, no explanations, and no surrounding text. Prefer portable, non-destructive commands. If multiple commands are required, print only the commands on separate lines.'

  _llm_prompt "$system_prompt" "$*"
}

ask() {
  local system_prompt
  system_prompt='Answer directly and concisely (3-8 sentences by default). Use bullets only when they improve clarity. Do not add unnecessary introductions or conclusions. If the question asks for code, provide only the relevant code with a brief explanation. If the user explicitly asks for a detailed explanation, tutorial, or deep dive, then provide one. State uncertainty rather than inventing facts.'

  _llm_prompt "$system_prompt" "$*"
}

# Generate a command, show it, and execute it in a clean child shell only after
# confirmation. A child shell avoids eval altering the current shell session.
ai() {
  local generated_command
  generated_command=$(cmd "$@") || return

  print -r -- 'Suggested command:'
  print -r -- "$generated_command"
  print

  read -q 'REPLY?Execute? [y/N] '
  print

  if [[ $REPLY =~ '^[Yy]$' ]]; then
    command zsh -fc "$generated_command"
    return $?
  fi

  return 0
}

explain() {
  local system_prompt
  system_prompt='Explain the supplied shell command for a developer. Cover what it does, each non-obvious option, side effects or risks, and a safer alternative when relevant. Be concise.'
  _llm_prompt "$system_prompt" "$*"
}

# Diagnose errors passed as arguments or through stdin. When its first argument
# is a file, turn a debug report into a reviewable patch instead:
# debugai src/widget.py "failing test" | fix src/widget.py
fix() {
  local input system_prompt file size max_bytes
  if [[ -f $1 ]]; then
    file=$1
    shift
    if (( $# )); then
      input="$*"
    else
      input=$(cat)
    fi
    if [[ -z $input ]]; then
      print -u2 -- 'fix: provide a debug report as an argument or on standard input'
      return 2
    fi

    max_bytes=${DEBUGAI_MAX_BYTES:-200000}
    size=$(wc -c < "$file")
    if (( size > max_bytes )); then
      print -u2 -- "fix: $file is ${size} bytes (limit: ${max_bytes}); narrow the file or set DEBUGAI_MAX_BYTES"
      return 1
    fi

    system_prompt='You are a careful code-fix assistant. Use the debug report and source file from standard input to create the smallest correct improvement. Return ONLY a unified diff that applies to the supplied file, with no Markdown or explanation. Preserve unrelated code and do not make speculative refactors. If the report or source does not justify a safe change, return an empty response.'
    {
      print -- '--- debug report ---'
      print -r -- "$input"
      print
      print -- "--- source file: $file ---"
      cat -- "$file"
    } | _llm_prompt "$system_prompt" "Create a minimal patch for $file."
    return
  fi

  if (( $# )); then
    input="$*"
  else
    input=$(cat)
  fi
  system_prompt='You diagnose Unix and developer-tool failures. Identify the most likely cause, give the smallest safe fix, and include one verification command. Do not invent unavailable tools or facts.'
  print -r -- "$input" | _llm_prompt "$system_prompt" 'Diagnose the error text from standard input.'
}

# Ask about any piped input: logs, JSON, command output, or text.
pipeai() {
  local system_prompt
  system_prompt='Analyze the data supplied on standard input. Answer the user request directly, distinguish facts from inference, and be concise. Never claim to have inspected data not present in the input.'
  _llm_prompt "$system_prompt" "$*"
}

# Turn data from stdin into a reproducible shell data-processing command.
dataai() {
  local system_prompt
  system_prompt='Given sample data on standard input and the user request, return a single safe, reproducible command using standard Unix tools, jq, awk, sed, or rg where appropriate. Return only the command, with no Markdown or explanation. Do not modify input files.'
  _llm_prompt "$system_prompt" "$*"
}

# Diagnose a source file without modifying it. Supply an error as an argument or
# pipe it in: pytest 2>&1 | debugai src/widget.py "why does this fail?"
debugai() {
  local file=$1 question size max_bytes piped_error system_prompt
  shift || true

  if [[ -z $file ]]; then
    print -u2 -- 'usage: debugai <file> [question or error message]'
    return 2
  fi
  if [[ ! -f $file ]]; then
    print -u2 -- "debugai: not a regular file: $file"
    return 1
  fi

  max_bytes=${DEBUGAI_MAX_BYTES:-200000}
  size=$(wc -c < "$file")
  if (( size > max_bytes )); then
    print -u2 -- "debugai: $file is ${size} bytes (limit: ${max_bytes}); narrow the file or set DEBUGAI_MAX_BYTES"
    return 1
  fi

  if [[ ! -t 0 ]]; then
    piped_error=$(cat)
  fi
  question=${*:-'Find likely bugs or errors in this file.'}
  system_prompt='You are a precise debugging assistant. Inspect only the source file and error context supplied on standard input. Return a concise report with: (1) likely root cause, (2) relevant file line or code section, (3) minimal fix, and (4) one verification command. If evidence is insufficient, say what is missing. Do not modify files or claim to run code.'

  {
    print -- "--- file: $file ---"
    cat -- "$file"
    if [[ -n $piped_error ]]; then
      print
      print -- '--- piped error output ---'
      print -r -- "$piped_error"
    fi
  } | _llm_prompt "$system_prompt" "$question"
}

_llm_git_context() {
  git status --short
  print
  print -- '--- staged diff ---'
  git diff --cached
  print
  print -- '--- unstaged diff ---'
  git diff
}

# Ask questions with the current repository status and diff attached as stdin.
gitai() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 -- 'gitai: not inside a Git work tree'
    return 1
  fi

  local system_prompt
  system_prompt='You are a careful code-review and Git assistant. Use only the repository context supplied on standard input. Point out correctness, security, and maintainability concerns in priority order. Be concise and never suggest running destructive Git commands unless specifically asked.'
  _llm_git_context | _llm_prompt "$system_prompt" "$*"
}

# Draft a conventional commit message from staged changes; it never commits.
commit() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 -- 'commit: not inside a Git work tree'
    return 1
  fi
  if git diff --cached --quiet; then
    print -u2 -- 'commit: no staged changes'
    return 1
  fi

  local system_prompt
  system_prompt='Write a conventional commit message from the staged diff on standard input. Return only a subject line of at most 72 characters followed by an optional concise body. Do not use Markdown, quotes, or code fences.'
  git diff --cached | _llm_prompt "$system_prompt" 'Draft the commit message.'
}

# Draft a pull-request title and body from the current branch diff. It never
# creates a pull request.
pr() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 -- 'pr: not inside a Git work tree'
    return 1
  fi

  local base base_ref candidate system_prompt
  base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  base=${base#origin/}
  for candidate in "$base" main master; do
    [[ -n $candidate ]] || continue
    if git show-ref --verify --quiet "refs/heads/$candidate"; then
      base=$candidate
      base_ref=$candidate
      break
    elif git show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
      base=$candidate
      base_ref="origin/$candidate"
      break
    fi
  done
  if [[ -z $base_ref ]]; then
    print -u2 -- 'pr: could not find a local main or master base branch'
    return 1
  fi

  system_prompt='Write a pull-request title and concise Markdown body from the Git context on standard input. Include Summary and Testing sections. State uncertainty when testing evidence is absent. Do not claim tests were run unless the context proves it.'
  {
    print -- "--- base branch: $base ---"
    git diff --stat "$base_ref...HEAD"
    print
    git diff "$base_ref...HEAD"
  } | _llm_prompt "$system_prompt" "Draft a PR for changes against $base. $*"
}

# Convert rough text into a concise Markdown note. Example: pbpaste | note
note() {
  local input system_prompt
  if (( $# )); then
    input="$*"
  else
    input=$(cat)
  fi
  system_prompt='Turn the supplied rough text into a concise, well-structured Markdown note. Preserve decisions, dates, owners, and action items. Do not add facts that are not present.'
  print -r -- "$input" | _llm_prompt "$system_prompt" 'Format the text from standard input as a note.'
}

# Include lightweight machine and repository context for troubleshooting.
ctxai() {
  local system_prompt git_context
  git_context='not a Git work tree'
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_context=$(git status --short)
  fi
  system_prompt='You are a terminal troubleshooting assistant. Use the supplied environment context and user question. Give safe, concrete next steps and clearly label assumptions.'
  {
    print -- "directory: $PWD"
    print -- "shell: $ZSH_VERSION"
    print -- "os: $(uname -srm)"
    print -- 'git status:'
    print -r -- "$git_context"
  } | _llm_prompt "$system_prompt" "$*"
}

# Suggest filename mappings for one or more existing files. This is deliberately
# preview-only; review the mapping before doing any rename yourself.
renameai() {
  if (( $# == 0 )); then
    print -u2 -- 'usage: renameai <file> [file ...]'
    return 2
  fi

  local file files=() system_prompt
  for file in "$@"; do
    if [[ ! -e $file ]]; then
      print -u2 -- "renameai: file not found: $file"
      return 1
    fi
    files+=("$file")
  done

  system_prompt='Suggest consistent, descriptive filenames for the supplied paths. Preserve each extension unless changing it is essential. Return only one tab-separated mapping per line in the form original-path<TAB>suggested-new-basename. Do not include commands, Markdown, explanations, or paths not supplied. This is a preview, not a request to rename files.'
  print -rl -- "$files[@]" | _llm_prompt "$system_prompt" 'Propose safe filename mappings for the paths from standard input.'
}

# Consult local documentation before recommending a command for a tool.
manai() {
  local tool=$1
  shift || true
  if [[ -z $tool ]]; then
    print -u2 -- 'usage: manai <tool> <what you want to do>'
    return 2
  fi

  local docs system_prompt
  if (( $+commands[man] )); then
    docs=$(MANPAGER=cat man "$tool" 2>/dev/null)
  fi
  if [[ -z $docs ]]; then
    if (( ! $+commands[$tool] )); then
      print -u2 -- "manai: command not found: $tool"
      return 1
    fi
    docs=$(command "$tool" --help 2>&1)
  fi
  if [[ -z $docs ]]; then
    print -u2 -- "manai: no local documentation found for $tool"
    return 1
  fi

  system_prompt='Use only the supplied local documentation to answer the user question. Recommend the minimal command, explain any risky flags, and say when the documentation does not establish an answer.'
  print -r -- "$docs" | _llm_prompt "$system_prompt" "Tool: $tool. Request: $*"
}
