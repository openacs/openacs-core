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

aa_register_case \
    -cats { api smoke } \
    -procs {
        api_apropos_functions
    } \
    acs_api_browser_api_apropos_functions {
        Check api_apropos_functions
    } {
        set all_ad_procs [nsv_array names api_proc_doc]

        aa_true "Searching for the empty string returns every ad_proc" \
            {[llength [api_apropos_functions ""]] == [llength $all_ad_procs]}

        while {[set bogus_proc [ad_generate_random_string]] in $all_ad_procs} {}
        aa_true "A bogus proc returns no result" \
            {[llength [api_apropos_functions $bogus_proc]] == 0}

        set proc ns_write
        set found_p false
        foreach r [api_apropos_functions $proc] {
            lassign $r name etc
            if {$name eq $proc} {
                set found_p true
                break
            }
        }
        aa_false "Other non ad_* api is not returned" $found_p

        set proc api_apropos_functions
        set found_p false
        foreach r [api_apropos_functions $proc] {
            lassign $r name etc
            if {$name eq $proc} {
                set found_p true
                break
            }
        }
        aa_true "This same proc is retrieved correctly" $found_p
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
