ad_page_contract {
    Typically redirects to the admin index page which displays information about test cases
    on this server. However, if this is an install/test reporting server (see parameter IsInstallReportServer) then
    show the list of installed servers here.
}

if { ![parameter::get -boolean -parameter IsInstallReportServer] } {
    ad_returnredirect admin
    ad_script_abort
}

set page_title "Test Servers Control Page"
set context [list]
multirow create servers path admin_login_url local_url remote_url name description install_date error_total_count parse_errors

set xml_report_dir [aa_test::xml_report_dir]
if { $xml_report_dir ne "" } {
    foreach path [glob -nocomplain $xml_report_dir/*-installreport.xml] {
        aa_test::parse_install_file -path $path -array service

        set test_path [aa_test::test_file_path -install_file_path $path]
        if { [file exists $test_path] } {
            aa_test::parse_test_file -path $test_path -array test
            array set testcase_failure $test(testcase_failure)
            set service(num_errors) [array size testcase_failure]
        } 
	
	set admin_login_url [export_vars -base "$service(url)/register/auto-login" {{email {$service(adminemail)}} {password {$service(adminpassword)}}}]

        multirow append servers \
            $service(path) \
	    $admin_login_url \
            [export_vars -base server { path }] \
	    $service(url) \
            $service(name) \
            $service(description) \
            $service(install_end_timestamp) \
            $service(num_errors) \
            $service(parse_errors)
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
