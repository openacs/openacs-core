ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case \
    -cats { api smoke } \
    -procs {
        api_library_documentation
    } \
    acs_api_browser_trivial_smoke_test {
        Minimal smoke test for acs-api-browser package.
    } {

        aa_run_with_teardown \
        -rollback \
        -test_code {
            set result [api_library_documentation packages/acs-api-browser/tcl/acs-api-documentation-procs.tcl]
            aa_true "api documentation proc can document itself" \
                [string match "*packages/acs-api-browser/tcl/acs-api-documentation-procs.tcl*" $result]
        }
    }

aa_register_case \
    -cats { api smoke } \
    -procs {
        api_add_to_proc_doc
    } \
    acs_api_browser_api_add_to_proc_doc {
        Check api_add_to_proc_doc
    } {
        set proc_name [ad_generate_random_string]
        set property [ad_generate_random_string]
        set value [ad_generate_random_string]
        set value2 ${value}2
        api_add_to_proc_doc \
            -proc_name $proc_name \
            -property $property \
            -value $value

        aa_true "nsv was created" [nsv_exists api_proc_doc $proc_name]

        aa_true "nsv contains the property" [dict exists [nsv_get api_proc_doc $proc_name] $property]

        aa_true "Property has 1 value" \
            {[llength [dict get [nsv_get api_proc_doc $proc_name] $property]] == 1}
        aa_log "Adding the same value again"
        api_add_to_proc_doc \
            -proc_name $proc_name \
            -property $property \
            -value $value
        aa_true "Property still has 1 value" \
            {[llength [dict get [nsv_get api_proc_doc $proc_name] $property]] == 1}

        aa_log "Adding a different value"
        api_add_to_proc_doc \
            -proc_name $proc_name \
            -property $property \
            -value $value2
        aa_true "Property now has 2 values" \
            {[llength [dict get [nsv_get api_proc_doc $proc_name] $property]] == 2}

        nsv_unset -nocomplain -- $proc_name
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
