ad_page_contract {
    Control page for an individual server.
} {
    path:notnull
}

aa_test::parse_install_file -path $path -array service

set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin]

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

set admin_login_url [export_vars -base "$service(url)/register/auto-login" {{email {$service(adminemail)}} {password {$service(adminpassword)}}}]

set rebuild_url [export_vars -base rebuild-server { { server $service(name) } }]
set rebuild_log_url "/rebuild-$service(name).log"

template::add_confirm_handler \
    -id "action-rebuild" \
    -message "Are you sure you want to wipe and rebuild this server?"


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
