## About
**wmrc** is a shell script framework for extending window manager capabilities
using modules with dependency and error checking.


The goal of this utility is to help you maintain a set of concise and ergonomic
scripts (modules) for configuring and customizing various aspects of a custom
desktop environment. It comes with only a few batteries included, in order to
provide maximum portability and modularity across different operating systems,
window managers and init daemons.

## Installation

### Arch Linux ([AUR](https://aur.archlinux.org/packages/wmrc))
```shell
paru -S aur/wmrc
```

### Generic instructions
```shell
git clone 'https://github.com/filiparag/wmrc'
cd ./wmrc
sudo make install
```

## Modules

Modules are groups of arbitrary POSIX-compliant shell scripts located in
`$HOME/.config/wmrc/modules/<group>/<module>`. Each module should be responsible
for one functionality of the desktop environment — for instance, module
`polybar` in group `screen` is tasked with configuring and running all bars.

Modules can invoke special [`libwmrc`](./libwmrc.sh) functions and access global
variables which are injected into them before execution. These functions
implement common functionality for interfacing with `wmrc`, logging and daemon
control. Their implementation can be overridden when necessary.

Each module can have `WMRC_DEPENDENCIES` global variable declaring needed system
executables and wmrc modules it calls. If multiple modules share functionality,
they can import custom wmrc libraries by declaring them in the `WMRC_LIBRARIES`
variable. These libraries are sources from `$HOME/.config/wmrc/modules/libs`.
Dependencies and libraries are checked before module execution, in order to
prevent errors and undefined behavior.

### Example module

Module `screen/vnc` for controlling VNC server:
```sh
#!/bin/sh

export WMRC_DEPENDENCIES='x0vncserver'

start() {
  if ! [ -f "$HOME/.vnc/passwd" ]; then
    error "Password for VNC server is not set!"
    return 1
  fi
  if daemon_get_pid; then
    error "VNC server is already running!"
    return 1
  fi
  x0vncserver --PasswordFile="$HOME/.vnc/passwd" >/dev/null &
  daemon_set_pid "$!"
}
```

This module uses injected `libwmrc` functions for logging and control of the
spawned background process. Functionality for stopping and restarting module is
inherited and doesn't need to be explicitly declared.

Service can be started implicitly as `wmrc start screen/vnc`
or explicitly as a method call: `wmrc call screen/vnc start`.

Implicit method calls are
available for functions `start`, `stop`, `restart` and `status`.

## Configuration file

Configuration file is located at `$HOME/.config/wmrc/rc.conf` and contains
global variables and execution units.

### Variables

Variables declared here are visible in all modules with `WMRC_` prefix.
They can be assigned any constant value or shell expression.

### Execution units

Execution unit is a sequence of method calls to wmrc modules.
Their purpose is to group execution of various methods which
should always be executed together.

Mehod calls in units are executed in parallel, but can be executed conditionally
in sequence using `wait` and `crit` flags.

### Example configuration
```ini
%LOCKSCREEN_COVER = '$HOME/Pictures/bliss.jpg'

[lock]
screen/lock::start crit
screen/brightness::set(100%)
audio/playerctl::pause
```

Now, hotkey daemon can call `wmrc unit lock` and the lock unit will be executed.
