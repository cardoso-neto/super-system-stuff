# macOS things that do not come from Homebrew, plus the shell wiring they
# expect. Same role as os/ubuntu/install/first-boot-installs.sh.
#
# Order matters only in that pipx and uv come from brew-installs.sh first.

# pipx needs ~/.local/bin on PATH. The tracked os/macos/dotfiles/.zprofile
# already has that line, so with the dotfiles in place this is a no-op; run it
# on a machine that is not using them.
pipx ensurepath
sudo pipx ensurepath --global

# Shell completions for uv and pipx are NOT appended to .zshrc. The tracked
# .zshrc loads them through its own _cached_completion helper, which writes the
# generated completion to ~/.cache/zsh and re-runs the generator only when the
# binary is newer than the cache. Appending the usual
# `eval "$(uv generate-shell-completion zsh)"` would shell out on every single
# startup -- that plus a few similar evals was most of a 790ms -> 170ms
# regression. Also note ~/.zshrc is a symlink into this repo, so anything
# appending to it edits tracked files.

# kitty terminal. Installs to ~/.local/kitty.app rather than /Applications.
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# grok cli. Puts binaries in ~/.grok/bin and zsh completions in
# ~/.grok/completions/zsh -- the tracked .zshrc adds both to path and fpath.
curl -fsSL https://x.ai/cli/install.sh | bash

# Give Claude Code a browser it can drive.
claude mcp add chrome-devtools npx chrome-devtools-mcp@latest
