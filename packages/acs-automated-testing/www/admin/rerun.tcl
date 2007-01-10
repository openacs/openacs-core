ad_page_contract {
    @cvs-id $Id$
} {
    {package_key ""}
    {category:aa_test_category ""}
    {view_by:aa_test_view_by "package"}
    {testcase_id:nohtml ""}
    {quiet "0"}
    {stress "0"}
    {security_risk "0"}
} -properties {
}

if {$testcase_id eq ""} {
  if {$quiet} {
    aa_runseries -stress $stress -security_risk $security_risk -quiet $package_key $category
  } else {
    aa_runseries -stress $stress -security_risk $security_risk $package_key $category
  }
  ad_returnredirect "index?by_package_key=$package_key&by_category=$category&view_by=$view_by&quiet=$quiet&stress=$stress&security_risk=$security_risk"
} else {
  if {$quiet} {
    aa_runseries -quiet -testcase_id $testcase_id "" ""
  } else {
    aa_runseries -testcase_id $testcase_id "" ""
  }
  ad_returnredirect "testcase?testcase_id=$testcase_id&package_key=$package_key&quiet=$quiet"
}

