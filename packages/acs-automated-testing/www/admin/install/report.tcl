ad_page_contract {
    Test servers control page.
}

set page_title "Test Servers Control Page"
set context [list]
multirow create servers path url name install_date error_total_count parse_errors

set xml_report_dir [aa_test::xml_report_dir]
if { ![empty_string_p $xml_report_dir] } {
    foreach path [glob $xml_report_dir/*-installreport.xml] {
        aa_test::parse_install_file -path $path -array service

        set test_path [aa_test::test_file_path -install_file_path $path]
        if { [file exists $test_path] } {
            aa_test::parse_test_file -path $test_path -array test
            array set testcase_failure $test(testcase_failure)
            set service(num_errors) [llength [array names testcase_failure]]
        } 

        multirow append servers \
            $service(path) \
            [export_vars -base server { path }] \
            $service(name) \
            $service(install_end_timestamp) \
            $service(num_errors) \
            $service(parse_errors)
    }
}