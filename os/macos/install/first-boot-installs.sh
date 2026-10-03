# macOS setup that does not come from Homebrew.

uv python install 3.14 --default
uv tool update-shell

# Puts kitty.app in /Applications, not ~/.local like the Linux installer does.
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# grok cli: ~/.grok/bin and ~/.grok/completions/zsh, both wired up in .zshrc.
curl -fsSL https://x.ai/cli/install.sh | bash

claude mcp add chrome-devtools npx chrome-devtools-mcp@latest

# mpv DUMMY
curl -fL https://github.com/vitorgalvao/mpv-dummy/releases/download/2023.2/mpv.DUMMY.dmg -o /tmp/mpv.DUMMY-2023.2.dmg
hdiutil attach /tmp/mpv.DUMMY-2023.2.dmg -nobrowse -readonly
ditto '/Volumes/mpv DUMMY/mpv.app' /Applications/mpv.app
hdiutil detach '/Volumes/mpv DUMMY'
