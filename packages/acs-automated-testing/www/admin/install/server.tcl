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

set page_title "Control Page For $service(name)"
set context [list $page_title]
