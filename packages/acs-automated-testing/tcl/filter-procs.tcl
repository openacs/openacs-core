ad_page_contract_filter aa_test_view_by { name value } {
  Checks whether a view_by value has a value of "testcase", "package" or
  "category"
} {
    if {$value ni {testcase package}} {
        ad_complain "Invalid view_by name"
        return 0
    }
    return 1
}

ad_page_contract_filter aa_test_category { name value } {
  Checks whether a category value has is valid.
} {
    if {$value ni [nsv_get aa_test categories]} {
        ad_complain "$value is not a valid acs-automated-testing testcase category"
        return 0
    }
    return 1
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
