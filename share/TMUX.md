# Tmux reference

This repository uses a plugin-free tmux configuration for tmux 3.3 or newer. The entry point is `~/.config/tmux/tmux.conf`; options, keys, themes, and scripts live in the adjacent directories.

## Start tmux

The shell aliases cover common session operations:

```sh
tc NAME  # create a session
ta NAME  # attach to a session
tl       # list sessions
tk NAME  # kill a session
```

You can also create or attach to a named session directly:

```sh
tmux new-session -A -s main
```

The prefix is `Ctrl-Space`.

## Key bindings

| Binding | Action |
| --- | --- |
| `prefix`, `Ctrl-Space` | Send the prefix to a nested tmux session |
| `prefix`, `r` | Reload the complete configuration |
| `prefix`, `\|` | Split right in the active directory |
| `prefix`, `-` | Split below in the active directory |
| `prefix`, `c` | Create a window in the active directory |
| `prefix`, `x` | Close the current pane after confirmation |
| `prefix`, `q` | Close the current pane immediately |
| `prefix`, `H/J/K/L` | Resize a pane; repeat without pressing the prefix again |
| `Ctrl-h/j/k/l` | Navigate across Neovim splits and tmux panes |
| `Ctrl-Shift-h/j/k/l` | Resize Neovim splits or tmux panes |
| `prefix`, `z` | Zoom or restore the active pane |
| `prefix`, `f` | Search sessions, windows, and panes with fzf |
| `prefix`, `p` | Create or switch to a project session with fzf |
| `prefix`, `T` | Toggle Catppuccin Frappé and Latte |
| `prefix`, `S` | Cycle the status line through bottom, top, and hidden |
| `prefix`, `[` | Enter Vi-style copy mode |

Killing the last pane also closes its window.

## Copy mode and clipboard

Press `v` in copy mode to begin a selection, `Ctrl-v` to toggle a rectangle, and `y` to copy. Tmux writes the selection to its paste buffer and to the first available desktop provider:

- `pbcopy` on macOS
- `wl-copy` on Wayland
- `xclip` or `xsel` on X11

OSC 52 clipboard support remains enabled for compatible terminals.

## Status and themes

The status line shows the session, windows, and `user@host:~/current/path`. Windows running Pi, OpenCode, or Claude Code are named `pi`, `opencode`, or `claude code`; other windows use their active command.

Frappé is the default theme. Theme and status-position changes apply to all clients attached to the same tmux server and survive a configuration reload. They reset when the server exits.

## Project discovery

The project launcher combines zoxide's ranked directories with immediate child directories under configured roots. The defaults scan `~/code` and `~/src` and include `~/.dotfiles` or `~/dotfiles` directly when either directory exists.

Set a colon-separated root list before starting tmux to override the defaults:

```sh
export TMUX_PROJECT_DIRS="$HOME/code:$HOME/src"
```

Update an existing server with:

```sh
tmux set-environment -g TMUX_PROJECT_DIRS "$TMUX_PROJECT_DIRS"
```

## Terminal capabilities

Ghostty and Kitty keep their native `xterm-ghostty` and `xterm-kitty` values outside tmux. Applications inside tmux see `tmux-256color`. Do not force `TERM=xterm-256color`; doing so hides capabilities that tmux uses for colors, keys, clipboard access, and hyperlinks.

Install the local terminal's terminfo entry when a remote host does not recognize it. The remote host must provide `tic`, usually from `ncurses-bin` on Ubuntu or `ncurses` on Arch. Check it before sending an entry:

```sh
ssh HOST 'command -v tic'
infocmp -x xterm-ghostty | ssh HOST 'tic -x -'
infocmp -x xterm-kitty | ssh HOST 'tic -x -'
```

The configuration enables `allow-passthrough` so trusted applications can use terminal graphics protocols. Passthrough also lets visible panes send wrapped escape sequences to the outer terminal. Do not run untrusted terminal applications in these panes.

If colors or modified keys are incorrect, check the versions and terminfo entry:

```sh
tmux -V
infocmp tmux-256color
```

Tmux 3.5 or newer can emit CSI-u sequences for distinct `Ctrl-Shift` keys. The configuration remains compatible with tmux 3.3 and 3.4.

## Reload or restart

Reload configuration changes with `prefix`, `r`. If you replaced an older plugin-based setup, restart the server after saving active work:

```sh
tmux kill-server
```

This command closes every tmux session.

## References

- [tmux manual](https://github.com/tmux/tmux/blob/master/tmux.1)
- [fzf reference](https://junegunn.github.io/fzf/reference/)
- [Catppuccin palette](https://github.com/catppuccin/catppuccin)
