# Shell config that works unmodified in both bash and zsh, on any OS.
# Symlinked to ~/.shell_aliases and sourced from the host's rc file.
#
# Anything depending on a Linux-only binary (xclip, xkbset, notify-send,
# gpustat) or on GNU flags (ls --color, find -regex) is deliberately NOT here --
# see os/ubuntu/dotfiles/.bash_aliases and os/ubuntu/dotfiles/.bashrc.

# git log, in increasing order of detail
alias gg='git log --oneline --graph'
alias ggg='git log --oneline --graph --pretty="format:%>|(12)%C(auto)%h%C(reset) %C(magenta)%<(12,trunc)%aE%C(reset) %C(green)%<(15,trunc)%ar%C(reset) %C(red)%G?%C(reset) %C(auto)%d%C(reset) %C(white)%<(50,trunc)%s%C(reset)"'
alias ggs='git log --oneline --graph --pretty="format:%>|(12)%C(auto)%h%C(reset) %C(magenta)%<(12,trunc)%aE%C(reset) %C(green)%<(12,trunc)%ar%C(reset) %C(auto)%d%C(reset) %C(white)%<(30,trunc)%s%C(reset)"'

alias cd...="cd ../.."

# Does not actually work: aliases do not take positional parameters, so ${1} is
# always empty. Kept for the intent -- it wants to be a function.
alias save-alias='echo alias"${1}"'

# Send files to the trash rather than unlinking them, and never prompt --
# agents invoke rm far more often than I do interactively, so a confirmation
# would just block them while a recoverable delete costs nothing.
#
# A function rather than an alias because the trash tools reject rm's flags:
# `trash -rf x` is an error on macOS. Flags are parsed off and discarded, since
# both backends are already recursive and neither ever prompts.
#
# `command rm` still does a real, permanent delete when that is what you want.
rm() {
    local paths=() endopts=0 force=0 arg
    for arg in "$@"; do
        if [ "$endopts" = 1 ]; then
            paths+=("$arg")
        elif [ "$arg" = "--" ]; then
            endopts=1
        elif [ "${arg#-}" != "$arg" ] && [ -n "${arg#-}" ]; then
            # an rm flag (-r, -f, -i, -v...); the trash tools take none of them,
            # but -f changes what we owe the caller, so note it
            case "$arg" in
                --force) force=1 ;;
                --*) ;;
                -*f*) force=1 ;;
            esac
        else
            paths+=("$arg")
        fi
    done
    # -f promises "ignore nonexistent operands, never fail". The trash tools
    # error out instead, which would break `rm -f maybe-missing` under set -e.
    if [ "$force" = 1 ] && [ ${#paths[@]} -gt 0 ]; then
        local existing=() p
        for p in "${paths[@]}"; do
            if [ -e "$p" ] || [ -L "$p" ]; then existing+=("$p"); fi
        done
        paths=("${existing[@]}")
    fi
    [ ${#paths[@]} -eq 0 ] && return 0
    if command -v trash >/dev/null 2>&1; then
        command trash "${paths[@]}"          # macOS ships /usr/bin/trash
    elif command -v gio >/dev/null 2>&1; then
        gio trash "${paths[@]}"              # GLib/GNOME, i.e. the Ubuntu box
    else
        printf 'rm: no trash tool found; refusing to delete. Use `command rm`.\n' >&2
        return 1
    fi
}
