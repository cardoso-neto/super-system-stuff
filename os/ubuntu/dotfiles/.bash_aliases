# Ubuntu-only aliases: each one depends on a binary or desktop service that
# does not exist on macOS. The portable half lives in shared/shell/aliases.sh.

alias cat=lolcat

# xclip is X11-only; the macOS equivalent would be pbcopy
alias cp-file-contents="xclip -sel c <"

# gpustat is an nvidia-smi wrapper
alias gpu='gpustat --interval 0.5 --show-cmd --show-user --show-power'

# set mouse speed when using the Universal Access Mouse Keys feature
alias set-fast-mouse-keys="xkbset ma 60 10 10 20 10"

# better rm: trash files instead. gio is part of GLib/GNOME.
alias tt='gio trash'

alias dad-joke='curl -s https://icanhazdadjoke.com/ | cowsay | lolcat'
