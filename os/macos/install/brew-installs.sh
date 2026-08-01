# Everything I install through Homebrew on macOS. The rough equivalent of
# os/ubuntu/install/apt-installs.sh + snaps.sh, and organised the same way:
# one line each, with a comment saying what it is for.
#
# Getting brew itself: homebrew-install.sh.

# cli tools
brew install pipx  # install python applications into isolated venvs
brew install uv  # python package and project manager
brew install pandoc  # convert documents between markup formats
brew install librsvg  # rsvg-convert, rasterises SVG; pandoc uses it for PDFs

# essentials
brew install --cask bitwarden  # password manager
brew install --cask visual-studio-code

# apps
brew install --cask miniconda  # lands in /opt/homebrew/Caskroom/miniconda/base
brew install --cask ghostty  # terminal
brew install --cask spotify
brew install --cask whatsapp
brew install --cask basictex  # small TeX distribution; prompts for a password

# ai tools
brew install --cask claude
brew install --cask codex-app
brew tap manaflow-ai/cmux
brew install --cask cmux
