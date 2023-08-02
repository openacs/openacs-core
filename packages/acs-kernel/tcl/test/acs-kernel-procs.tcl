ad_library {
    acs-kernel automated tests.
}

aa_register_case \
    -cats {
        smoke
        production_safe
    } acs_kernel__server_startup_ok {

        Checks that the server has booted without errors.

    } {
        set errors [dict get [ns_logctl stats] Error]
        aa_log "Number of errors: $errors, warnings: [dict get [ns_logctl stats] Warning]"
        aa_equals "No errors detected during startup sequence" $errors 0
    }


