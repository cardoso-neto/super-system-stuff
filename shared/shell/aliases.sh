# Aliases that work unmodified in both bash and zsh, on any OS.
# Source this from the host's rc file.
#
# Anything depending on a Linux-only binary (xclip, gio, xkbset, notify-send,
# gpustat) or on GNU flags (ls --color, find -regex) is deliberately NOT here --
# see os/ubuntu/dotfiles/.bash_aliases and os/ubuntu/dotfiles/.bashrc.

# git log, in increasing order of detail
alias gg='git log --oneline --graph'
alias ggg='git log --oneline --graph --pretty="format:%>|(12)%C(auto)%h%C(reset) %C(magenta)%<(12,trunc)%aE%C(reset) %C(green)%<(15,trunc)%ar%C(reset) %C(red)%G?%C(reset) %C(auto)%d%C(reset) %C(white)%<(50,trunc)%s%C(reset)"'
alias ggs='git log --oneline --graph --pretty="format:%>|(12)%C(auto)%h%C(reset) %C(magenta)%<(12,trunc)%aE%C(reset) %C(green)%<(12,trunc)%ar%C(reset) %C(auto)%d%C(reset) %C(white)%<(30,trunc)%s%C(reset)"'

alias cd...="cd ../.."

# have rm ask for confirmation everytime
alias rm="rm -i"

# Does not actually work: aliases do not take positional parameters, so ${1} is
# always empty. Kept for the intent -- it wants to be a function.
alias save-alias='echo alias"${1}"'
