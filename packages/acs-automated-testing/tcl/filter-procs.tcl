ad_page_contract_filter aa_test_view_by { name value } {
  Checks whether a view_by value has a value of "testcase", "package" or
  "category"
} {
  if {$value ne "testcase" &&
      $value ne "package"} {
    ad_complain "Invalid view_by name"
    return 0
  }
  return 1
}

ad_page_contract_filter aa_test_category { name value } {
  Checks whether a category value has is valid.
} {
  set found 0
  foreach category [nsv_get aa_test categories] {
    if {$value == $category} {
      return 1
    }
  }
  ad_complain "$value is not a valid acs-automated-testing testcase category"
  return 0
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
