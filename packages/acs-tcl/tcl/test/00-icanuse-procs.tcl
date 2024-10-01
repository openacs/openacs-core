ad_library {

    Test api defined in tcl/00-icanuse-procs.tcl

}

aa_register_case \
    -cats { api } \
    -procs {
        acs::cmd_has_subcommand
    } \
    acs__command_has_subcommand {

        Check whether we can detect if a command has a subcommand.

    } {
        aa_section "Test a plain Tcl command"
        set subcmds {
            compare
            equal
            first
            index
            is
            last
            length
            map
            match
            range
            repeat
            replace
            reverse
            tolower
            totitle
            toupper
            trim
            trimleft
            trimright
            wordend
            wordstart
        }

        foreach subcmd $subcmds {
            aa_true "string subcommand '$subcmd' is recognized" [acs::cmd_has_subcommand string $subcmd]
        }

        set subcmd [ad_generate_random_string]
        aa_false "string has no subcommand called '$subcmd'" [acs::cmd_has_subcommand string $subcmd]

        aa_section "Test NaviServer subcommands"
        set subcmds {
            get
            set
        }
        foreach subcmd $subcmds {
            aa_true "nsv_array subcommand '$subcmd' is recognized" \
                [acs::cmd_has_subcommand nsv_array $subcmd]
        }
        set subcmd [ad_generate_random_string]
        aa_false "nsv_array has no subcommand called '$subcmd'" \
            [acs::cmd_has_subcommand nsv_array $subcmd]
    }
