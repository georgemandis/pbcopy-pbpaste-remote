#!/bin/sh
# Install (or remove) pbcopy/pbpaste-over-SSH for fish, bash and zsh.
#
#   ./install.sh              install for every shell found on this machine
#   ./install.sh --uninstall  remove everything it installed
#
# Files go to $XDG_DATA_HOME/pbcopy-remote (default ~/.local/share/pbcopy-remote).
# The commands are only added to PATH inside SSH sessions.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
dest="$data_home/pbcopy-remote"
fish_conf="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/pbcopy-remote.fish"
marker_begin='# >>> pbcopy-remote >>>'
marker_end='# <<< pbcopy-remote <<<'

say() { printf '%s\n' "$*"; }

add_block() {
    rc=$1
    [ -f "$rc" ] || [ "$2" = create ] || return 0
    if [ -f "$rc" ] && grep -qF "$marker_begin" "$rc"; then
        say "  $rc already sourced it"
        return 0
    fi
    {
        printf '\n%s\n' "$marker_begin"
        printf '[ -r "%s/shell/pbcopy-remote.sh" ] && . "%s/shell/pbcopy-remote.sh"\n' "$dest" "$dest"
        printf '%s\n' "$marker_end"
    } >>"$rc"
    say "  added source line to $rc"
}

remove_block() {
    rc=$1
    [ -f "$rc" ] || return 0
    grep -qF "$marker_begin" "$rc" || return 0
    tmp=$(mktemp)
    sed "/^$marker_begin\$/,/^$marker_end\$/d" "$rc" >"$tmp"
    cat "$tmp" >"$rc"
    rm -f "$tmp"
    say "  removed source block from $rc"
}

install() {
    say "Installing to $dest"
    mkdir -p "$dest/bin" "$dest/shell"
    cp "$here/bin/pbcopy" "$here/bin/pbpaste" "$dest/bin/"
    chmod +x "$dest/bin/pbcopy" "$dest/bin/pbpaste"
    cp "$here/shell/pbcopy-remote.sh" "$here/shell/pbcopy-remote.fish" "$dest/shell/"

    if command -v fish >/dev/null 2>&1 || [ -d "$(dirname "$(dirname "$fish_conf")")" ]; then
        mkdir -p "$(dirname "$fish_conf")"
        cp "$here/shell/pbcopy-remote.fish" "$fish_conf"
        say "  fish: $fish_conf"
    fi
    if command -v bash >/dev/null 2>&1 || [ -f "$HOME/.bashrc" ]; then
        say "  bash:"; add_block "$HOME/.bashrc" create
    fi
    if command -v zsh >/dev/null 2>&1 || [ -f "$HOME/.zshrc" ]; then
        say "  zsh:"; add_block "${ZDOTDIR:-$HOME}/.zshrc" create
    fi

    say
    say "Done. Open a new SSH session and run:  echo hello | pbcopy"
    if [ -z "${SSH_TTY:-}${SSH_CONNECTION:-}" ]; then
        say "(You are not in an SSH session right now, so nothing changes in this shell.)"
    fi
}

uninstall() {
    say "Removing $dest"
    rm -rf "$dest"
    [ -f "$fish_conf" ] && rm -f "$fish_conf" && say "  removed $fish_conf"
    remove_block "$HOME/.bashrc"
    remove_block "${ZDOTDIR:-$HOME}/.zshrc"
    say "Done."
}

case "${1:-}" in
    "") install ;;
    --uninstall|-u) uninstall ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) say "unknown option: $1" >&2; exit 2 ;;
esac
