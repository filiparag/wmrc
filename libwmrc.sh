#!/bin/sh

WMRC_VERSION='2.1.2'
WMRC_LOG_LEVEL="${WMRC_LOG_LEVEL:-warn}"
WMRC_CHECK_DEPS="${WMRC_CHECK_DEPS:-true}"
LOG_FILE="/tmp/wmrc@$(whoami)${DISPLAY}.log"
WMRC_CONFIG="$HOME/.config/wmrc"
_pid_file="/tmp/wmrc::$(echo "$_module" | sed 's,/,::,g')@$(whoami)${DISPLAY}.pid"

export _module
export DAEMON_PID
export WMRC_VERSION
export WMRC_LOG_LEVEL
export WMRC_CHECK_DEPS
export WMRC_CONFIG

_stderr() {
    >&2 printf '%s\n' "$*"
    printf '[%s] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" >> "$LOG_FILE"
}

error() {
    echo "$WMRC_LOG_LEVEL" | grep -qi 'error\|warn\|info\|debug' || return 0
    _title="$1"
    shift 1
    _message="$*"
    _stderr "$(
        printf '\033[1;37m[%s] \033[1;31m%s\033[0m%s %s\n' "$_module" "$_title" "${_message:+:}" "$_message"
    )"
}

warn() {
    echo "$WMRC_LOG_LEVEL" | grep -qi 'warn\|info\|debug' || return 0
    _title="$1"
    shift 1
    _message="$*"
    _stderr "$(
        printf '\033[1;37m[%s] \033[1;33m%s\033[0m%s %s\n' "$_module" "$_title" "${_message:+:}" "$_message"
    )"
}

info() {
   echo "$WMRC_LOG_LEVEL" | grep -qi 'info\|debug' || return 0
   _title="$1"
    shift 1
    _message="$*"
    _stderr "$(
        printf '\033[1;37m[%s] \033[1;32m%s\033[0m%s %s\n' "$_module" "$_title" "${_message:+:}" "$_message"
    )"
}

debug() {
    echo "$WMRC_LOG_LEVEL" | grep -qi 'debug' || return 0
    _title="$1"
    shift 1
    _message="$*"
    _stderr "$(
        printf '\033[1;37m[%s] \033[1;34m%s\033[0m%s %s\n' "$_module" "$_title" "${_message:+:}" "$_message"
    )"
}

_module_libraries() {
    debug 'Module libraries' "$1"
    if ! test -f "$WMRC_CONFIG/modules/$1"; then
        error 'Module not found' "$WMRC_CONFIG/modules/$1"
        exit 1
    fi
    libraries="$(
        sh -c ". '$WMRC_CONFIG/modules/$1' && echo \$WMRC_LIBRARIES" | sed 's/ \{1,\}/\n/g'
    )"
    if [ -n "$libraries" ]; then
        debug 'Found libraries' "$(echo "$libraries" | sed -z 's/\n/, /g;s/, $/\n/')"
        if [ "$WMRC_CHECK_DEPS" != 'false' ]; then
            for l in $libraries; do
                debug 'Test library file' "$WMRC_CONFIG/libs/$l"
                if ! test -f "$WMRC_CONFIG/libs/$l"; then
                    error 'Library not found' "$WMRC_CONFIG/libs/$l"
                    exit 1
                fi
            done
        fi
    fi
}

call() {
    if [ -z "$1" ]; then
        error 'Module name not provided'
        return 1
    else
        _callee="$1"
        shift 1
    fi
    debug 'Test module file' "$WMRC_CONFIG/modules/$_callee"
    if ! test -f "$WMRC_CONFIG/modules/$_callee"; then
        error 'Module not found' "$_callee"
        exit 1
    fi
    _params=""
    while [ -n "$1" ]; do
        _params="$_params${_params:+ }'$1'"
        shift 1
    done
    _libs=''
    _module_libraries "$_callee"
    if [ -n "$libraries" ]; then
        _libs="$(echo "$libraries" | xargs printf ". '$WMRC_CONFIG/libs/%s' &&")"
    fi
    sh -c "_module='$_callee' && . '$WMRC_DIR/libwmrc.sh' && $_libs. '$WMRC_CONFIG/modules/$_callee' && $_params"
    _status="$?"
    if [ "$_status" != 0 ]; then
        error 'Error executing call' "$_callee::$(echo "$_params" | sed "s/^\(\w\) ?.*$/\1/;s:'::g")"
        return 1
    else
        debug 'Call executed successfully'
    fi
}

init() {
    error "Initialization method not defined"
    return 1
}

start() {
    error "Start method not defined"
    return 1
}

stop() {
    daemon_kill "$1"
}

restart() {
    info "Restarting module $_module"
    if ! stop ''; then
        error 'Error stopping module'
    fi
    if ! start; then
        error 'Error starting module'
        return 1
    fi
}

status() {
    if daemon_get_pid; then
        info "Daemon is running" "Process id $DAEMON_PID"
    else
        info "No daemon running"
    fi
}

daemon_set_pid() {
    if [ -z "$1" ]; then
        error 'Daemon pid not provided'
        return 1
    fi
    if test -f "$_pid_file" && ps "$(cat "$_pid_file")" >/dev/null 2>/dev/null; then
        error 'Daemon is already running'
        return 2
    elif ! ps "$1" >/dev/null 2>/dev/null; then
        error 'Provided pid is of a dead process' "$1"
        return 3
    else
        info 'Set daemon' "$_module => $1"
        echo "$1" > "$_pid_file"
    fi
}

daemon_get_pid() {
    if ! test -f "$_pid_file" || ! kill -0 "$(cat "$_pid_file")" >/dev/null 2>/dev/null; then
        debug 'Daemon is not running'
        return 1
    else
        DAEMON_PID="$(cat "$_pid_file")"
        debug 'Get daemon pid' "$DAEMON_PID"
    fi
}

daemon_kill() {
    if ! daemon_get_pid; then
        error 'No daemon to kill'
        return 1
    else
        DAEMON_PID="$(cat "$_pid_file")"
        info 'Kill daemon' "$DAEMON_PID"
        debug 'Kill signal code' "${1:-15}"
        if kill "-${1:-15}" "$DAEMON_PID"; then
            debug 'Clear daemon pid' "$DAEMON_PID"
            echo > "$_pid_file"
        else
            error 'Failed to kill daemon' "$_module"
            return 1
        fi
    fi
}
