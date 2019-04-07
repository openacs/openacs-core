ad_page_contract {
    @cvs-id $Id$
} {
    {package_key:token ""}
    {category:aa_test_category ""}
    {view_by:aa_test_view_by "package"}
    {testcase_id:word,notnull ""}
    {quiet:boolean "0"}
    {stress:boolean "0"}
    {security_risk:boolean "0"}
} -properties {
}

if {$testcase_id eq ""} {
    if {$quiet} {
        aa_runseries -stress $stress -security_risk $security_risk -quiet $package_key $category
    } else {
        aa_runseries -stress $stress -security_risk $security_risk $package_key $category
    }

    set return_url [export_vars -base index {
        {by_package_key $package_key}
        {by_category $category}
        view_by quiet stress security_risk}]
} else {
    #
    # Rerun of a single test case always resources the definition.
    #
    foreach c [nsv_get aa_test cases] {
        if {[lindex $c 0] eq $testcase_id} {
            set absolute_file_path [lindex $c 2]
            ns_log notice "Sourcing test definition file $absolute_file_path"
            apm_source $absolute_file_path
            break
        }
    }

    if {$quiet} {
        aa_runseries -quiet -testcase_id $testcase_id "" ""
    } else {
        aa_runseries -testcase_id $testcase_id "" ""
    }
    set return_url [export_vars -base testcase {
        testcase_id package_key quiet
    }]
}

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
