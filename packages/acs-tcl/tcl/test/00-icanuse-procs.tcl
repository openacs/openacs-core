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
        set flags {
            bytelength
            cat
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

        foreach flag $flags {
            aa_true "string subcommand '$flag' is recognized" [acs::cmd_has_subcommand string $flag]
        }

        set flag [ad_generate_random_string]
        aa_false "string has no subcommand called '$flag'" [acs::cmd_has_subcommand string $flag]

        aa_section "Test NaviServer subcommands"
        set flags {
            get
            set
        }
        foreach flag $flags {
            aa_true "nsv_array subcommand '$flag' is recognized" \
                [acs::cmd_has_subcommand nsv_array $flag]
        }
        set flag [ad_generate_random_string]
        aa_false "nsv_array has no subcommand called '$flag'" \
            [acs::cmd_has_subcommand nsv_array $flag]
    }
