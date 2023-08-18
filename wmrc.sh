#!/bin/sh

WMRC_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
export WMRC_DIR

_module='wmrc'
. "$WMRC_DIR/libwmrc.sh"

module_exec() {
    check_dependencies "$1"
    eval "call $*"
}

module_list() {
    debug 'List modules'
    debug 'Test module directory' "$WMRC_CONFIG/modules"
    if ! test -d "$WMRC_CONFIG/modules"; then
        error "Modules directory not found: $WMRC_CONFIG/modules"
        exit 1
    fi
    info "$WMRC_CONFIG"
    modules="$(find "$WMRC_CONFIG/modules" -type f -printf '%P\n')"
    debug 'Found modules' "$(echo "$modules" | sed -z 's/\n/, /g;s/, $/\n/')"
}

get_dependencies() {
    if [ -z "$1" ]; then
        debug 'Get all dependencies'
        module_list
    else
        debug 'Get dependencies for' "$1"
        modules="$1"
    fi
    dependencies=""
    for m in $modules; do
        _deps="$(sh -c ". '$WMRC_CONFIG/modules/$m' && echo \$WMRC_DEPENDENCIES" | sed 's/ \{1,\}/:/g')"
        dependencies="$dependencies${dependencies:+:}$_deps"
    done
    debug 'Found dependencies' "$(echo "$dependencies" | sed 's|:|, |g')"
    dependencies="$(echo "$dependencies" | sed 's|:|\n|g' | sort | uniq)"
}

check_dependencies() {
    debug 'Check dependencies'
    get_dependencies "$1" || return 1
    _missing=""
    for d in $dependencies; do
        if ! command -v "$d" 1>/dev/null; then
            _missing="$_missing${_missing:+, }$d"
        fi
    done
    if [ -n "$_missing" ]; then
        error 'Missing dependencies' "$_missing"
        exit 1
    fi
}

read_config_variables() {
    debug 'Read configuration variables'
    debug 'Test configuration file' "$WMRC_CONFIG/rc.conf"
    if ! test -f "$WMRC_CONFIG/rc.conf"; then
        error 'Configuration file not found' "$WMRC_CONFIG/rc.conf"
        exit 1
    fi
    _vars="$(
        awk 'match($0, /^%(\w+) *= *(.*)$/, line) {
            printf("export WMRC_%s=\"%s\"\n",line[1],line[2]);
        }' "$WMRC_CONFIG/rc.conf"
    )"
    debug 'Load variables'
    eval "$_vars"

}

config_unit_list() {
    debug 'List all units'
    debug 'Test configuration file' "$WMRC_CONFIG/rc.conf"
    if ! test -f "$WMRC_CONFIG/rc.conf"; then
        error 'Configuration file not found' "$WMRC_CONFIG/rc.conf"
        exit 1
    fi
    units="$(awk 'match($0, /^\[(\w+)\]$/, line) {
        print line[1];
    }' "$WMRC_CONFIG/rc.conf")"
}

run_config_unit() {
    debug 'Run configuration unit'
    debug 'Test configuration file' "$WMRC_CONFIG/rc.conf"
    if ! test -f "$WMRC_CONFIG/rc.conf"; then
        error 'Configuration file not found' "$WMRC_CONFIG/rc.conf"
        exit 1
    fi
    if [ -z "$1" ]; then
        error 'Unit name not provided'
        exit 1
    fi
    if ! grep -q "\[$1\]" "$WMRC_CONFIG/rc.conf"; then
        error 'Configuration unit not found' "$1"
        exit 1
    fi
    _unit="$(
        awk -v target="$1" \
        'match($0, /^\[(.+)\]$/, line) {
            section=line[1];
        }
        match($0, /^%.*$/) {
            section="";
        }
        match($0, /^(\w+\/\w+)(::)?(\w+)?(\((.+)\))? *(\w+)?/, line) {
            if (section == target) {
                module=line[1];
                method=line[3] ? line[3] : "init";
                args=line[5];
                call=sprintf("%s::%s(%s)", module, method, args);s
                if (line[6] != "crit") {
                    detach=(line[6] == "wait") ? "" : "&";
                    printf( \
                        "info \"Executing %s call\" \"%s\"\n", \
                        (detach == "") ? "blocking" : "detatched", call \
                    );
                    printf("module_exec \"%s\" \"%s\" %s %s\n", module, method, args, detach);
                } else {
                    printf("info \"Executing critical call\" \"%s\"\n", call);
                    printf("module_exec \"%s\" \"%s\" %s || \\\n", module, method, args);
                    printf("{\n\terror \"Critical task failed, aborting\"\n\texit 1\n}\n");
                }
            }
        }
    ' "$WMRC_CONFIG/rc.conf")"
    read_config_variables
    debug 'Execute unit'
    eval "$_unit"
}

run_method() {
    debug 'Call method'
    if [ -z "$1" ]; then
        error 'Module name not provided'
        exit 1
    fi
    _callee="$1"
    if [ -z "$2" ]; then
        _method="init"
        shift 1
    else
        _method="$2"
        shift 2
    fi
    _params=""
    while [ -n "$1" ]; do
        _params="$_params${_params:+ }'$1'"
        shift 1
    done
    read_config_variables
    info 'Executing method' "$_callee::$_method($_params)"
    eval "module_exec $_callee $_method $_params"
}

print_variable() {
    debug 'Print variable'
    if [ -z "$1" ]; then
        error 'Variable name not provided'
        exit 1
    fi
    read_config_variables
    eval "echo \$WMRC_$1"
}

case "$1" in
    "")
        error 'No command specified'
        ;;
    "-v"|"--version"|"version")
        debug 'Print version'
        echo 'wmrc 2.0.0'
        ;;
    "-h"|"--help"|"help")
        debug 'Print version'
        printf 'wmrc 2.0.0\nFilip Parag <filip@parag.rs>\n\nCommands:\n'
        printf '\tcall <group>/<module> <method> [args...]\n'
        printf '\tvar <variable>\n'
        printf '\tunit <unit>\n'
        printf '\tunits\n'
        printf '\tmodules\n'
        printf '\tdeps\n'
        printf '\tcheck-deps\n'
        printf '\thelp\n'
        printf '\tversion\n'
        ;;
    "call")
        shift 1
        _params=""
        while [ -n "$1" ]; do
            _params="$_params${_params:+ }'$( printf '%q' "$1")'"
            shift 1
        done
        eval "run_method $_params"
        ;;
    "var")
        shift 1
        eval "print_variable $1"
        ;;
    "unit")
        shift 1
        eval "run_config_unit $1"
        ;;
    "units")
        config_unit_list
        echo "$units"
        ;;
    "modules")
        module_list
        echo "$modules"
        ;;
    "deps")
        get_dependencies
        echo "$dependencies"
        ;;
    "check-deps")
        check_dependencies
        ;;
    *)
        error 'Unknown command'
        ;;
esac

