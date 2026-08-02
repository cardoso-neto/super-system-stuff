# macOS setup that does not come from Homebrew.

# No-ops if os/macos/dotfiles/.zprofile is in place; it already puts
# ~/.local/bin on PATH.
pipx ensurepath
sudo pipx ensurepath --global

# Do not append `eval "$(uv generate-shell-completion zsh)"` or the pipx
# equivalent to ~/.zshrc. It is handled there already, cached rather than
# regenerated per startup, and ~/.zshrc is a symlink into this repo.

# Puts kitty.app in /Applications, not ~/.local like the Linux installer does.
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# grok cli: ~/.grok/bin and ~/.grok/completions/zsh, both wired up in .zshrc.
curl -fsSL https://x.ai/cli/install.sh | bash

claude mcp add chrome-devtools npx chrome-devtools-mcp@latest
