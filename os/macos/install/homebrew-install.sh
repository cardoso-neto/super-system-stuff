/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# brew is not on PATH until this runs. os/macos/dotfiles/.zprofile has the same
# line, so with the dotfiles in place a new login shell is enough.
eval "$(/opt/homebrew/bin/brew shellenv)"

brew tap homebrew/autoupdate
# --greedy also upgrades casks that update themselves, which are skipped
# otherwise. --ac-only means a laptop on battery never wakes up to do this.
brew autoupdate start 1d \
  --upgrade \
  --cleanup \
  --greedy \
  --ac-only \
  --notify-on-error

# Already running?  launchctl list | grep com.github.domt4.homebrew-autoupdate
