/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# brew is not on PATH until this runs. os/macos/dotfiles/.zprofile has the same
# line, so with the dotfiles in place a new login shell is enough.
eval "$(/opt/homebrew/bin/brew shellenv)"

bash "$(dirname "$0")/../../../hosts/mbp/install/autoupdate-install.sh"
