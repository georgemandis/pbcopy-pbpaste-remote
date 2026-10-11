# pbcopy / pbpaste over SSH, via OSC 52. Installed by pbcopy-pbpaste-remote.
# Only takes effect inside an SSH session, so local shells are untouched.
# Sourced by bash and zsh.
if [ -n "${SSH_TTY:-}${SSH_CONNECTION:-}" ]; then
    _pbr_dir="${XDG_DATA_HOME:-$HOME/.local/share}/pbcopy-remote/bin"
    if [ -d "$_pbr_dir" ]; then
        case ":$PATH:" in
            *":$_pbr_dir:"*) ;;
            *) PATH="$_pbr_dir:$PATH"; export PATH ;;
        esac
    fi
    unset _pbr_dir
fi
