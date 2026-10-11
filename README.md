# pbcopy / pbpaste over SSH

`pbcopy` and `pbpaste` for the machines you SSH into. Pipe into `pbcopy` on the
remote host and the text lands on the clipboard of the computer you are
actually sitting at.

```
$ ssh devbox
devbox$ cat ~/.ssh/id_ed25519.pub | pbcopy      # now on your laptop's clipboard
devbox$ pbpaste | wc -l                          # if your terminal allows it
```

## How it works

Terminals support an escape sequence called OSC 52. A program writes
`ESC ] 52 ; c ; <base64 text> BEL` to the tty, and the terminal emulator at the
other end of the SSH connection puts the decoded text on its system clipboard.
No X11 forwarding, no daemon, no agent, nothing installed on your laptop. It
works over any number of SSH hops because the bytes just flow down the tty.

The commands are only added to `PATH` inside SSH sessions (when `SSH_TTY` or
`SSH_CONNECTION` is set). Local shells never see them, so a local machine that
has real clipboard tools keeps using those.

They go on `PATH` rather than being shell aliases so that programs you run from
the shell can find them too: `:w !pbcopy` in vim, `git config` aliases, scripts,
and so on.

## Install

```
./install.sh
```

This copies the scripts to `~/.local/share/pbcopy-remote` (or
`$XDG_DATA_HOME/pbcopy-remote`) and wires up every shell it finds:

| shell | what it adds |
| --- | --- |
| fish | `~/.config/fish/conf.d/pbcopy-remote.fish` |
| bash | a marked block at the end of `~/.bashrc` |
| zsh  | a marked block at the end of `~/.zshrc` |

Re-running the installer is safe. `./install.sh --uninstall` removes all of it,
including the blocks in your rc files.

Run it on each remote host you want this on. Open a new SSH session afterwards.

## Terminal support

Copying (OSC 52 write) works in essentially every modern terminal: iTerm2,
Terminal.app (macOS 14 and later), kitty, Ghostty, WezTerm, Alacritty, foot,
Windows Terminal, Konsole, xterm, and others. Some require a one-time setting:

- **xterm**: `xterm*allowWindowOps: true` in your X resources.
- **Terminal.app**: enabled by default in recent macOS; check the Advanced tab of
  the profile if nothing happens.
- **GNOME Terminal and other VTE terminals**: no support until VTE 0.76 (2024).

Pasting (OSC 52 read) is a different story. A remote program silently reading
your clipboard is a privacy hole, so most terminals refuse the query outright
and `pbpaste` reports that nothing came back. Terminals that can be opted in:

- **kitty**: asks you each time by default (`clipboard_control read-clipboard-ask`).
- **Ghostty**: asks you each time by default (`clipboard-read = ask`).
- **xterm**: with `allowWindowOps` enabled.

Everything else, including iTerm2, WezTerm and Alacritty, cannot read.
`pbpaste` waits `PBPASTE_TIMEOUT` seconds (default 3) before giving up.

## tmux and screen

Inside tmux, either of these in `~/.tmux.conf` lets `pbcopy` reach the outer
terminal:

```
set -g set-clipboard on        # tmux forwards OSC 52 itself
set -g allow-passthrough on    # or: pbcopy wraps it in a passthrough sequence
```

tmux does not forward the terminal's reply to a clipboard query back into the
pane, so inside tmux `pbpaste` prints the tmux paste buffer instead. With
`set-clipboard on`, text you copy with tmux's own copy mode also lands on your
local clipboard, so the two stay close to each other in practice.

GNU screen only passes short device-control strings through, so `pbcopy` chunks
the sequence when `TERM` starts with `screen`.

## Limits

Terminals cap the size of an OSC 52 payload. Many stop somewhere around 100 KB
of base64, so very large copies may be dropped silently. Use `scp` or a file for
those.

## Environment

| variable | default | purpose |
| --- | --- | --- |
| `PBCOPY_TTY` | `/dev/tty` | device `pbcopy` writes to; useful for testing |
| `PBPASTE_TIMEOUT` | `3` | seconds `pbpaste` waits for the terminal's reply |

## Layout

```
bin/pbcopy                POSIX sh
bin/pbpaste               bash (needs read -t)
shell/pbcopy-remote.fish  fish hook, copied to conf.d
shell/pbcopy-remote.sh    bash/zsh hook, sourced from rc files
install.sh                installer / uninstaller
```
