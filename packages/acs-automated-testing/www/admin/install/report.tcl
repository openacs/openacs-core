ad_page_contract {
    Test servers control page.
}

set page_title "Test Servers Control Page"
set context [list]
multirow create servers path url name install_date error_total_count parse_errors

foreach file [glob /var/log/openacs-install/*.xml] {
    parse_test_server_file -name [file tail $file] -array service
    multirow append servers \
	$service(path) \
	"server?[export_vars { { name "$service(filename)" } }]" \
	$service(name) \
	$service(install_end_timestamp) \
	$service(num_errors) \
	$service(parse_errors)
}
