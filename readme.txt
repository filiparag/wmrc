NAME
    WMRC - window manager modules

SYNOPSIS
    wmrc [-l, --dry-run] section | -d, --deps | -m, --missing-deps

DESCRIPTION
    WMRC is a shell utility for extending window manager
    capabilities using modules with dependency and error
    checking.

OPTIONS
    -l, --dry-run
        Show defined variables and section's module
        execution order insead of running them.
    -d, --deps
        List of all commands required by modules.
        This will not show software package names
        that provide respective commands in $PATH.
    -m, --missiong-deps
        Similar to previous option, but for only
        displaying missing commands.

CONFIGURATION:
    Environment variable:
        %variable_name = value
    Values:
        [a-zA-Z0-9_]
    Section:
        [section@hostname:position]
        directory1/module1(parameters...),module2
        directory2/module3,*
        directory3/*
    Positions:
        before, after, replace
    Parameters (Perl regex):
        [a-zA-Z0-9_-], 'String with spaces'
    Comments:
        # Example comment

MODULES:
    Dependencies:
        Include a comment formatted as:
        # WMRC_DEPS: dependencies ...
        at the top of the module.
    Flags:
        Include a comment formatted as:
        # WMRC_FLAGS: flags ...
        at the top of the module.
    Supported flags:
        async_lock - prevent subsequent modules 
          from loading until the script finishes
