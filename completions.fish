#!/usr/bin/env fish

function __fish_wmrc_root_command
    set cmd (commandline -opc)
    if [ (count $cmd) -eq 1 -a $cmd[1] = wmrc ]
        return 0
    end
    return 1
end

function __fish_wmrc_using_command
    set cmd (commandline -opc)
    if [ (count $cmd) -eq 2 ]
        if [ $argv[1] = $cmd[2] ]
            return 0
        end
    end
    return 1
end

function __fish_complete_wmrc
    set __units (WMRC_LOG_LEVEL=none wmrc units)
    set __modules (WMRC_LOG_LEVEL=none wmrc modules)
    set __running (WMRC_LOG_LEVEL=none wmrc ps | awk 'NR>1 {print $2}')
    complete -c wmrc -f
    complete -c wmrc -n __fish_wmrc_root_command -a version -x -d 'Print version'
    complete -c wmrc -n __fish_wmrc_root_command -a help -x -d 'Print help'
    complete -c wmrc -n __fish_wmrc_root_command -a deps -x -d 'List of external dependencies required by all modules'
    complete -c wmrc -n __fish_wmrc_root_command -a check-deps -x -d 'List of missing modules and external dependencies'
    complete -c wmrc -n __fish_wmrc_root_command -a units -x -d 'List all units'
    complete -c wmrc -n __fish_wmrc_root_command -a modules -x -d 'List all modules'
    complete -c wmrc -n __fish_wmrc_root_command -a ps -x -d 'List all daemons running in the background'
    complete -c wmrc -n __fish_wmrc_root_command -a var -x -d 'Print value of variable'
    complete -c wmrc -n __fish_wmrc_root_command -a call -x -d 'Call module\'s method with arguments'
    complete -c wmrc -n __fish_wmrc_root_command -a unit -x -d 'Runs all method calls in the unit'
    complete -c wmrc -n __fish_wmrc_root_command -a start -x -d 'Start module\'s background daemon'
    complete -c wmrc -n __fish_wmrc_root_command -a stop -x -d 'Stop module\'s background daemon'
    complete -c wmrc -n __fish_wmrc_root_command -a restart -x -d 'Restart module\'s background daemon'
    complete -c wmrc -n __fish_wmrc_root_command -a status -x -d 'Get module\'s background daemon status'
    complete -c wmrc -n __fish_wmrc_root_command -a logs -x -d 'Print the log of the current session'
    for cmd in call start
        complete -c wmrc -f -n "__fish_wmrc_using_command $cmd" -a "$__modules"
    end
    for cmd in stop restart status
        complete -c wmrc -f -n "__fish_wmrc_using_command $cmd" -a "$__running"
    end
    complete -c wmrc -f -n '__fish_wmrc_using_command unit' -a "$__units"
    complete -c wmrc -f -n '__fish_wmrc_using_command logs' -s f -l follow -d 'Attach to the log of the current session'
end

__fish_complete_wmrc
