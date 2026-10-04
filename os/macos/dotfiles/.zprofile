eval "$(/opt/homebrew/bin/brew shellenv)"

# User tools win over Homebrew; installers link their binaries here.
export PATH="$HOME/.local/bin:$PATH"
