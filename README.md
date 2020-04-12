## About
**wmrc** is shell utility for extending window manager capabilities using modules with dependency and error checking.

By using wmrc, you can declutter your *.profile* and window manager's configuration file, while gaining modularity and portability. If set up correctly, a single wmrc configuration can have modules which work across multiple window managers and init deamons.

## Installation

### Generic instructions
```bash
git clone 'https://github.com/filiparag/wmrc'
cd 'wmrc'
sudo install -Dm 775 'wmrc' '/usr/bin/wmrc'
sudo install -d -m 775 '/usr/share/wmrc'
sudo install -Dm 664 'rc.conf' '/usr/share/wmrc/'
sudo install -Dm 664 'usage.txt' '/usr/share/wmrc/'
sudo install -Dm 664 'wmrc.man' '/usr/share/man/man1/wmrc'
sudo cp -r --preserve=mode 'modules' '/usr/share/wmrc/'
```

This utility uses *dash* shell by default due to it's speed, but it can be replaced by any other POSIX-compliant shell.

### Arch Linux (AUR)
```bash
yay -Sy wmrc
```

## Usage
```shell
wmrc [-l, --dry-run] [-g, --debug] <section>
wmrc -r, --run-module <module> | -v, --vars <variable>
wmrc -d, --deps | -m, --missing-deps | -h, --help
```

### Options
#### Initialize
Initialize current user's wmrc configuration directory using default values.

`-i, --init`

#### Dry run
Show defined variables and section's module execution order insead of running them.

`-l, --dry-run`

#### Debug
Debugging mode in which all modules are loaded sequentualy (as if they all had *async_lock* flag enabled). This mode is useful for debugging.

`-g, --debug`

#### Run module
Run specified module in wmrc environment. Syntax for parameters is same as in the configuration file.

`-r, --run-module`

#### All dependencies
List of all commands required by modules. This will not show software package names that provide respective commands in *$PATH*.

`-d, --deps`

#### Missing dependencies
Similar to previous option, but for only displaying missing commands.

`-m, --missiong-deps`

#### Variables
Get values of variables defined in the configuration file.

`-v, --vars`

#### Help
Show usage manual.

`-h, --help`


## Configuration file:

Configuration file is located at `$HOME/.confg/wmrc/rc.conf`.

### Environment variable:
```
%variable_name = value
```
Values (Perl regex): `[a-zA-Z0-9_]`

### Section:
```ini
[section@hostname:position]
directory1/module1(parameters...),module2
directory2/module3,*
directory3/*
```
Positions: *before*, *after*, *replace*

Parameters (Perl regex): `[a-zA-Z0-9_-]`, `'String with spaces'`
### Comments:
```bash
# Example comment
```

### Example configuration file:

`$HOME/.confg/wmrc/rc.conf`
```ini
%WM = bspwm
%TERMINAL = xterm

[init]
wm/bspwm
hid/sxhkd
ui/polybar,*
screen/wallpaper

[init@home_pc:after]
screen/wallpaper(home)

[reload]
wm/bspwm(workspaces)
hid/sxhkd(reload)
ui/polybar(restart)
ui/notify(info,'Configuration reloaded')

[lock]
screen/lock

[suspend]
screen/lock,backlight(equ,100)
```

## Modules:

Modules are located inside directory located at `$HOME/.confg/wmrc/modules`.

### Dependencies:
Include a comment at the top of the module formatted as:
```bash
# WMRC_DEPS: dependencies ...
```
### Flags:
Include a comment at the top of the module formatted as:
```bash
# WMRC_FLAGS: flags ...
```
### Supported flags:
- `async_lock` - prevent subsequent modules from loading until the script finishes
- `required` - prevent subsequent modules from loading if the script fails

### Example module:

`$HOME/.config/wmrc/modules/hid/sxhkd`
```bash
#! /usr/bin/env dash
# WMRC_DEPS: pgrep, sxhkd
# WMRC_FLAGS:

reload() {
  pgrep -u "$(whoami)" sxhkd || \
    error "Sxhkd is not running!" fatal 2
  pkill -USR1 -x sxhkd
}

start() {
  pgrep -u "$(whoami)" sxhkd && \
    error "Sxhkd is already running!" fatal 2
  sxhkd &
}

stop() {
  pgrep -u "$(whoami)" sxhkd || \
    error "Sxhkd is not running!" fatal 3
  killall -u "$(whoami)" -9 sxhkd > /dev/null
}

. "$WMRC_MODULES/init"
```

## Configuring X11 startup

To connect wmrc with the window manager, you need to call wmrc after your window manager starts. It will set up two environment variables: *WMRC_DIR* and *WMRC_MODULES* which point to user's wmrc configuration.

Example X11 init file:

`$HOME/.xinitrc`
```bash
#! /usr/bin/env dash

! command -v wmrc >/dev/null && \
    >&2 echo "wmrc not found in PATH!" && exit 1

DEPS="$(wmrc -m | tr '\n' ' ')"

[ -n "$DEPS" ] && \
    >&2 echo "wmrc has missing dependencies:\n$DEPS" && exit 1

WM="$(wmrc -v | perl -n -e'/^WM=(.+)/ && print $1')"

exec "$WM"
```