# Interactive zsh config (macOS, Apple Silicon).
# Login-shell PATH bootstrap (Homebrew, ~/.local/bin) lives in ~/.zprofile.
# Secrets live in ~/.zshrc.secrets (chmod 600, never committed).

# path
# `typeset -U` keeps these deduplicated no matter how many times a directory is
# prepended, including when this file is re-sourced in a nested shell.
# Tools whose installers append their own PATH lines belong here instead; link
# single binaries into ~/.local/bin rather than adding their directories.
typeset -U path fpath
path=("$HOME/.local/bin" "$HOME/.grok/bin" "$HOME/.bun/bin" $path)

# prompt
# Deliberately not exported: PS1 is shell-local, and leaking zsh's %{...%}
# escapes into non-zsh children is a footgun.
PS1="%{%F{green}%}%n@%m:%{%F{blue}%}%~%{%F{red}%}\$ %{%f%}"

# eternal history
# Own file because /etc/zshrc points HISTFILE at ~/.zsh_history with SAVEHIST=1000,
# and sessions rewrite that file wholesale on exit.
HISTFILE="$HOME/.zsh_eternal_history"
HISTSIZE=1000000
SAVEHIST=1000000
setopt EXTENDED_HISTORY       # timestamp + duration per entry
setopt INC_APPEND_HISTORY_TIME  # write on completion, don't wait for exit
setopt APPEND_HISTORY         # never truncate a concurrent shell's writes
setopt HIST_FIND_NO_DUPS      # hide dupes while searching, but keep them on disk
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# keybindings
bindkey "\e[A" history-search-backward
bindkey "\e[B" history-search-forward

# completions
# One compinit for the whole file: every fpath entry has to be registered above
# this point. compaudit reports no insecure directories, so no -u is needed.
fpath=("$HOME/.grok/completions/zsh" $fpath)   # from the grok installer
autoload -Uz compinit
compinit

# Generating completions shells out (~350 ms combined at startup), so cache the
# output and regenerate only when the generating binary is newer than its cache.
ZSH_CACHE_DIR="$HOME/.cache/zsh"
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p "$ZSH_CACHE_DIR"
_cached_completion() {
  local name=$1 bin=$2; shift 2
  local cache="$ZSH_CACHE_DIR/$name.zsh"
  if [[ -n $bin && ( ! -s $cache || $bin -nt $cache ) ]]; then
    "$@" >| "$cache" 2>/dev/null || return
  fi
  [[ -s $cache ]] && source "$cache"
}
_cached_completion uv   "${commands[uv]}"                            uv generate-shell-completion zsh
unset -f _cached_completion
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"   # from the bun installer

# environment
export GPG_TTY=$(tty)

# API keys and tokens: XAI, OpenRouter, Hugging Face, Bitwarden.
[ -f "$HOME/.zshrc.secrets" ] && source "$HOME/.zshrc.secrets"

unset CLAUDE_CODE_OAUTH_TOKEN

# shared shell config
# Symlink to super-system-stuff/shared/shell/aliases.sh -- git log aliases,
# cd..., and an rm that trashes instead of unlinking. Because it is a symlink,
# editing it edits the repo, so drift shows up in `git status` instead of
# silently. The -f test is false for a dangling link, so a missing repo just
# means no aliases rather than a startup error.
[ -f "$HOME/.shell_aliases" ] && source "$HOME/.shell_aliases"

# claude code
claude-switch() (
  local dir="$HOME/.claude" target="${1-}" current credential
  if (( $# > 1 )) || [[ -n "$target" && "$target" != personal && "$target" != work && "$target" != quentin ]]; then
    print -u2 'Usage: claude-switch [personal|work|quentin]'
    return 1
  fi

  zmodload zsh/system || return
  umask 077
  : >> "$dir/.credentials.switch.lock" || return
  integer lock_fd
  zsystem flock -t 10 -f lock_fd "$dir/.credentials.switch.lock" || {
    print -u2 'Could not lock Claude credentials.'
    return 1
  }

  if [[ -r "$dir/.credentials.active" ]]; then
    IFS= read -r current < "$dir/.credentials.active" || return
  fi
  case "$current" in
    personal|work|quentin) ;;
    *) print -u2 'Cannot identify the active Claude account.'; return 1 ;;
  esac

  if [[ -z "$target" ]]; then
    case "$current" in
      personal) target=work ;;
      work) target=quentin ;;
      quentin) target=personal ;;
    esac
  fi
  if [[ "$current" == "$target" ]]; then
    print "Already selected: $current."
    return 0
  fi

  credential="$(security find-generic-password -a "$USER" -s "Claude Code-credentials-$target" -w 2>/dev/null)" || {
    print -u2 "No saved Claude credentials for $target."
    return 1
  }
  security add-generic-password -U -a "$USER" -s 'Claude Code-credentials' -w "$credential" >/dev/null || return
  unset credential

  umask 077
  print -r -- "$target" > "$dir/.credentials.active.tmp" || return
  mv -f -- "$dir/.credentials.active.tmp" "$dir/.credentials.active" || return
  print "Switched to $target credentials. Start a new Claude Code session."
)

claude() {
  local args=(--dangerously-skip-permissions) dir="$PWD"
  while [[ "$dir" != "/" && -n "$dir" ]]; do
    if [[ -s "$dir/.claude/append-system-prompt.md" ]]; then
      args+=(--append-system-prompt "$(<"$dir/.claude/append-system-prompt.md")")
      break
    fi
    dir="$(dirname "$dir")"
  done
  # local tok; tok="$(claude-account token)" || return 1
  # CLAUDE_CODE_OAUTH_TOKEN="$tok" command claude "${args[@]}" "$@"
  command claude "${args[@]}" "$@"
}
alias cc='claude'
# Bypass cliproxy: --settings outranks the proxy URL and apiKeyHelper in
# ~/.claude/settings.json, so auth falls back to the keychain OAuth account
# that claude-switch selects.
claude-direct() (
  unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN
  claude --settings '{"env":{"ANTHROPIC_BASE_URL":"https://api.anthropic.com"},"apiKeyHelper":""}' "$@"
)
alias ccd='claude-direct'
ccnext() { claude-switch && claude -c "$@" }

# codex
alias codex='codex --yolo'
# Bypass cliproxy: the built-in openai provider authenticates with
# ~/.codex/auth.json (`codex login`) instead of the proxy's client key.
codex-direct() { codex -c model_provider=openai "$@" }
alias cxd='codex-direct'

# pi
alias pi-grok='pi --provider xai --model grok-4.5'
alias pi-ollama='pi --model "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:IQ4_XS"'
alias pi-mlx='pi --model "mlx-local/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit"'
alias pi-qwen36='pi --model "hf.co/unsloth/Qwen3.6-27B-MTP-GGUF:Q4_K_M"'

# Start/restart the MLX server in the conservative config that worked best on this Mac.
pi-mlx-start() {
  kill "$(cat ~/.pi/mlx/server.pid 2>/dev/null)" 2>/dev/null || true
  pkill -f 'mlx_lm server.*Qwen3-Coder-30B-A3B-Instruct-MLX-4bit' 2>/dev/null || true
  nohup mlx_lm server \
    --model lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit \
    --host 127.0.0.1 \
    --port 8080 \
    --max-tokens 1024 \
    --decode-concurrency 1 \
    --prompt-concurrency 1 \
    --prefill-step-size 512 \
    --prompt-cache-size 0 \
    > ~/.pi/mlx/server-qwen3-coder-30b-4bit.log 2>&1 &
  echo $! > ~/.pi/mlx/server.pid
  echo "MLX server started with PID $(cat ~/.pi/mlx/server.pid)"
}

# misc
alias ta-quick='uvx --from "git+ssh://git@bitbucket.org/thoughtfulautomation/ta-quick.git" quick'
