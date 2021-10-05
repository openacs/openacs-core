ad_library {

    Automated tests for procs in tcl/authority-procs.tcl

}

aa_register_case \
    -cats {api} \
    -procs {
        auth::authority::get_sc_impl_columns
    } \
    authority__get_sc_impl_columns {
        Test authority::get_sc_impl_columns
    } {
        set columns {
            auth_impl_id
            pwd_impl_id
            register_impl_id
            user_info_impl_id
            get_doc_impl_id
            process_doc_impl_id
        }
        if {[apm_version_names_compare [ad_acs_version] 5.5.0] > -1} {
            lappend columns search_impl_id
        }

        aa_equals "Proc returns expected result" \
            $columns [auth::authority::get_sc_impl_columns]
    }


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
