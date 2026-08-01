# Interactive zsh config (macOS, Apple Silicon).
# Login-shell PATH bootstrap (Homebrew, pipx) lives in ~/.zprofile.
# Secrets live in ~/.zshrc.secrets (chmod 600, never committed).

# path
# `typeset -U` keeps these deduplicated no matter how many times a directory is
# prepended, including when this file is re-sourced in a nested shell.
typeset -U path fpath
CONDA_BASE="/opt/homebrew/Caskroom/miniconda/base"
path=(
  "$HOME/.grok/bin"          # from the grok installer
  "$CONDA_BASE/bin"          # see the lazy conda block below
  "$CONDA_BASE/condabin"
  $path
)

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
_cached_completion pipx "${commands[register-python-argcomplete]}"   register-python-argcomplete pipx
unset -f _cached_completion

# lazy-loaded runtimes
# nvm and conda each cost ~300 ms to initialize; defer both to first use.

# nvm
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm node npm npx pi
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}
node() { nvm use default >/dev/null; node "$@"; }
npm()  { nvm use default >/dev/null; npm  "$@"; }
npx()  { nvm use default >/dev/null; npx  "$@"; }
pi()   { nvm use default >/dev/null; pi   "$@"; }

# conda
# Replaces the `conda init` managed block, which ran `conda shell.zsh hook` on
# every startup purely to define this function and activate base. $CONDA_BASE/bin
# is on PATH above, so python/python3/pip resolve to base exactly as they did
# before -- including for `#!/usr/bin/env python3` scripts, which never see shell
# functions. Only the hook itself is deferred.
# Caveat: $CONDA_PREFIX and $CONDA_DEFAULT_ENV stay unset until `conda` is called.
# Re-running `conda init zsh` will re-append the old block; delete it if it does.
conda() {
  unset -f conda
  local setup
  if setup="$("$CONDA_BASE/bin/conda" shell.zsh hook 2>/dev/null)"; then
    eval "$setup"
  elif [ -f "$CONDA_BASE/etc/profile.d/conda.sh" ]; then
    . "$CONDA_BASE/etc/profile.d/conda.sh"
  fi
  conda "$@"
}

# environment
export GPG_TTY=$(tty)

# API keys and tokens: XAI, OpenRouter, Hugging Face, Bitwarden.
[ -f "$HOME/.zshrc.secrets" ] && source "$HOME/.zshrc.secrets"

# Claude Code accounts live in the keychain (claude-code-oauth-{primary,secondary});
# `claude-account` picks whichever is not rate-limited. NO_PROBE keeps shell
# startup off the network -- the claude() function below does the real check.
# Needed as an export because cmux's shim and quentinbot inherit it from here.
export CLAUDE_CODE_OAUTH_TOKEN="$(CLAUDE_FAILOVER_NO_PROBE=1 claude-account token 2>/dev/null)"

# claude code
claude() {
  local args=(--dangerously-skip-permissions) dir="$PWD"
  while [[ "$dir" != "/" && -n "$dir" ]]; do
    if [[ -s "$dir/.claude/append-system-prompt.md" ]]; then
      args+=(--append-system-prompt "$(<"$dir/.claude/append-system-prompt.md")")
      break
    fi
    dir="$(dirname "$dir")"
  done
  local tok; tok="$(claude-account token)" || return 1
  CLAUDE_CODE_OAUTH_TOKEN="$tok" command claude "${args[@]}" "$@"
}
alias cc='claude'
# Hit the limit mid-session: park this account and resume the conversation on the other.
ccnext() { claude-account bump && claude -c "$@" }

# codex
alias codex='codex --yolo'

# pi
alias pi-grok='pi --provider xai --model grok-4.5'
alias pi-ollama='pi --model "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:IQ4_XS"'
alias pi-mlx='pi --model "mlx-local/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit"'
alias pi-qwen36='pi --model "hf.co/unsloth/Qwen3.6-27B-MTP-GGUF:Q4_K_M"'

# Start/restart the MLX server in the conservative config that worked best on this Mac.
pi-mlx-start() {
  kill "$(cat ~/.pi/mlx/server.pid 2>/dev/null)" 2>/dev/null || true
  pkill -f 'mlx_lm server.*Qwen3-Coder-30B-A3B-Instruct-MLX-4bit' 2>/dev/null || true
  nohup python3 -m mlx_lm server \
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
