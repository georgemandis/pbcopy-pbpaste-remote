# pbcopy / pbpaste over SSH, via OSC 52. Installed by pbcopy-pbpaste-remote.
# Only takes effect inside an SSH session, so local shells are untouched.
if set -q SSH_TTY; or set -q SSH_CONNECTION
    set -l dir (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo ~/.local/share)/pbcopy-remote/bin
    if test -d $dir; and not contains -- $dir $PATH
        set -gx PATH $dir $PATH
    end
end
