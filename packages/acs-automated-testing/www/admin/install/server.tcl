ad_page_contract {
    Control page for an individual server.
} {
    path:notnull
}

aa_test::parse_install_file -path $path -array service

set test_path [aa_test::test_file_path -install_file_path $path]
set has_test_report_p [file exists $test_path]

multirow create testcase_failures testcase_id count

if { $has_test_report_p } {
    aa_test::parse_test_file -path $test_path -array test

    array set testcase_failure $test(testcase_failure)
    foreach testcase_id [array names testcase_failure] {
	multirow append testcase_failures $testcase_id $testcase_failure($testcase_id)
    }
}

set page_title "Control Page for Server $service(name)"
set context [list $page_title]

set time [ns_time]
set token_id [sec_get_random_cached_token_id]
set token [sec_get_token $token_id]
set hash [ns_sha1 "$time$token_id$token"]

set admin_login_url "[export_vars -base "$service(url)/register" {{email {$service(adminemail)}} {password {$service(adminpassword)}} {__confirmed_p 1} time hash token_id {return_url /admin}}]&form:id=login"
