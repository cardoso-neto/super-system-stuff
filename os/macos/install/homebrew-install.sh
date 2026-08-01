# Homebrew itself, plus the daily auto-update job. Everything installed *with*
# brew is in brew-installs.sh.
#
# Apple Silicon puts the prefix at /opt/homebrew, not /usr/local -- most
# tutorials online still say the latter.

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# brew is not on PATH until the shell environment is set up. The tracked
# os/macos/dotfiles/.zprofile already contains this line, so if the dotfiles
# are in place there is nothing to append -- just start a new login shell, or
# run it once by hand for the current one:
eval "$(/opt/homebrew/bin/brew shellenv)"

# Keep formulae and casks current once a day, but only on AC power so it never
# wakes up and drains the battery. --greedy includes casks that auto-update
# themselves, which are otherwise skipped.
brew tap homebrew/autoupdate
brew autoupdate start 1d \
  --upgrade \
  --cleanup \
  --greedy \
  --ac-only \
  --notify-on-error

# Already running? This is the launchd label to look for:
#   launchctl list | grep com.github.domt4.homebrew-autoupdate
