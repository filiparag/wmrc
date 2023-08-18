#!/bin/sh

WMRC_LOG_LEVEL="${WMRC_LOG_LEVEL:-warn}"
LOG_FILE="/tmp/wmrc@$(whoami)${DISPLAY}.log"
WMRC_CONFIG="$HOME/.config/wmrc"

export _module
export WMRC_LOG_LEVEL
export WMRC_CONFIG

error() {
    echo "$WMRC_LOG_LEVEL" | grep -qi 'error\|warn\|info\|debug' || return 0
    _title="$1"
    shift 1
    _message="$*"
    printf '\033[1;37m[%s] \033[1;31m%s\033[0m%s %s\n' "$_module" "$_title" "${_message:+:}" "$_message" | \
    xargs -0 printf '[%s] %s' "$(date '+%Y-%m-%dT%H:%M:%S')" | tee -a "$LOG_FILE"
}

warn() {
    echo "$WMRC_LOG_LEVEL" | grep -qi 'warn\|info\|debug' || return 0
    _title="$1"
    shift 1
    _message="$*"
    printf '\033[1;37m[%s] \033[1;33m%s\033[0m%s %s\n' "$_module" "$_title" "${_message:+:}" "$_message" | \
    xargs -0 printf '[%s] %s' "$(date '+%Y-%m-%dT%H:%M:%S')" | tee -a "$LOG_FILE"
}

info() {
   echo "$WMRC_LOG_LEVEL" | grep -qi 'info\|debug' || return 0
   _title="$1"
    shift 1
    _message="$*"
    printf '\033[1;37m[%s] \033[1;32m%s\033[0m%s %s\n' "$_module" "$_title" "${_message:+:}" "$_message" | \
    xargs -0 printf '[%s] %s' "$(date '+%Y-%m-%dT%H:%M:%S')" | tee -a "$LOG_FILE"
}

debug() {
    echo "$WMRC_LOG_LEVEL" | grep -qi 'debug' || return 0
    _title="$1"
    shift 1
    _message="$*"
    printf '\033[1;37m[%s] \033[1;34m%s\033[0m%s %s\n' "$_module" "$_title" "${_message:+:}" "$_message" | \
    xargs -0 printf '[%s] %s' "$(date '+%Y-%m-%dT%H:%M:%S')" | tee -a "$LOG_FILE"
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
    sh -c "_module='$_callee' && . '$WMRC_DIR/libwmrc.sh' && . '$WMRC_CONFIG/modules/$_callee' && $_params"
    _status="$?"
    if [ "$_status" != 0 ]; then
        error 'Error executing call' "$_callee::$(echo "$_params" | sed "s/^\(\w\) ?.*$/\1/;s:'::g")"
        return 1
    else
        debug 'Call executed successfully'
    fi
}

init() {
    warn "Initialization method not defined for $_module"
}

start() {
    warn "Start method not defined for $_module"
}

stop() {
    warn "Stop method not defined for $_module"
}

restart() {
    info "Restarting module $_module"
    if ! stop; then
        error 'Error stopping module' "$_module"
        return 1
    fi
    if ! start; then
        error 'Error starting module' "$_module"
        return 1
    fi
}
