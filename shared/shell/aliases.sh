# Shell config that works unmodified in both bash and zsh, on any OS.
# Symlinked to ~/.shell_aliases and sourced from the host's rc file.
#
# Anything depending on a Linux-only binary or on GNU-only flags (ls --color,
# grep --color) is deliberately NOT here -- see os/ubuntu/dotfiles/.bash_aliases
# and os/ubuntu/dotfiles/.bashrc. Git log aliases live in the git config, since
# that is where git-related things belong.

alias cd...="cd ../.."

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

# Copy to the system clipboard: `clip file`, or pipe into it.
# Was cp-file-contents, which was too long to ever actually type.
clip() {
    local sink
    if command -v pbcopy >/dev/null 2>&1; then
        sink=(pbcopy)                            # macOS
    elif command -v wl-copy >/dev/null 2>&1; then
        sink=(wl-copy)                           # Wayland, Ubuntu's default now
    elif command -v xclip >/dev/null 2>&1; then
        sink=(xclip -selection clipboard)        # X11
    else
        printf 'clip: no clipboard tool found (pbcopy, wl-copy, xclip).\n' >&2
        return 1
    fi
    if [ $# -gt 0 ]; then
        "${sink[@]}" < "$1"
    else
        "${sink[@]}"
    fi
}

# Remove __pycache__ folders, .pyc/.pyo files, mypy and pytest caches, and
# egg-info build leftovers. Defaults to the current directory.
# https://stackoverflow.com/a/41386937/11615853
#
# Two passes with -prune rather than the old single `find -regex`, because the
# regex flavour differs between GNU and BSD find and would not have worked on
# macOS. `rm` here is the real binary, not the trash function above -- find's
# -exec runs an executable and never sees shell functions. That is what we want
# for caches: they are regenerable, and trashing thousands of .pyc files would
# just fill the bin.
pyclean() {
    local target="${1:-.}"
    find "$target" -type d \
        \( -name '__pycache__' \
        -o -name '.mypy_cache' \
        -o -name '.pytest_cache' \
        -o -name '*.egg-info' \) \
        -prune -exec rm -rf -- {} +
    find "$target" -type f -name '*.py[co]' -exec rm -f -- {} +
}
