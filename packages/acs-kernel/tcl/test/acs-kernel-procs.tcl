ad_library {
    acs-kernel automated tests.
}

aa_register_case \
    -cats {
        smoke
        production_safe
    } acs_kernel__server_startup_ok {

        Checks that the server has booted without errors.

        @author Antonio Pisano

    } {
        set logfile [ns_config ns/parameters serverlog [acs_root_dir]/log/error.log]

        set logfile_exists_p [file exists $logfile]
        aa_true "Logfile exists" $logfile_exists_p
        if {!$logfile_exists_p} {
            return
        }

        #
        # Find the latest startup sequence in the logfile and see if
        # any error was reported before its conclusion.
        #

        set start_pattern "^.*: [ns_info name]/[ns_info patchlevel] .* starting.*$"
        set end_pattern "^.*: [ns_info name]/[ns_info patchlevel] .* running.*$"
        set error_pattern "^.*Error: .*$"

        set found_start_p false
        set found_end_p false
        set found_error_p false

        set rfd [open $logfile r]
        while {[gets $rfd line] >= 0} {
            if {[regexp $start_pattern $line]} {
                # We found the start of a sequence, forget all the
                # stuff we might have found earlier.
                set found_start_p true
                set found_end_p false
                set found_error_p false
            } elseif {[regexp $end_pattern $line]} {
                set found_end_p true
            } elseif {!$found_error_p &&
                      !$found_end_p &&
                      [regexp $error_pattern $line]} {
                # Errors found after startup do not count.
                set found_error_p true
            }
        }
        close $rfd

        aa_true "Start of startup sequence was found" $found_start_p
        aa_true "End of startup sequence was found" $found_end_p
        aa_false "No errors detected during startup sequence" $found_error_p
    }

