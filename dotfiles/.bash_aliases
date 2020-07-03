alias cat=lolcat

alias cp-file-contents="xclip -sel c <"


alias gg='git log --oneline --graph'
alias ggg='git log --oneline --graph --pretty="format:%>|(12)%C(auto)%h%C(reset) %C(magenta)%<(12,trunc)%aE%C(reset) %C(green)%<(15,trunc)%ar%C(reset) %C(red)%G?%C(reset) %C(auto)%d%C(reset) %C(white)%<(50,trunc)%s%C(reset)"'
alias ggs='git log --oneline --graph --pretty="format:%>|(12)%C(auto)%h%C(reset) %C(magenta)%<(12,trunc)%aE%C(reset) %C(green)%<(12,trunc)%ar%C(reset) %C(auto)%d%C(reset) %C(white)%<(30,trunc)%s%C(reset)"'

alias gpu='gpustat --interval 0.5 --show-cmd --show-user --show-power'

alias cd...="cd ../.."

alias save-alias='echo alias"${1}"'

# set mouse speed when using the Universal Access Mouse Keys feature
alias set-fast-mouse-keys="xkbset ma 60 10 10 20 10"
