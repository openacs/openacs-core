ad_page_contract {
    Create and mount a new application.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-05-28
    @cvs-id $Id$
} {
    {return_url "."}
}

set page_title "Add Applications"
set context [list [list "." "Applications"] $page_title]

set packages [subsite::get_application_options]

ad_form -name application -cancel_url . -export { return_url } -form {
    {package_key:text(checkbox),multiple
        {label "Select Applications"}
        {options $packages}
        {help_text "If the application is not in the list, you may need to <a href=\"/acs-admin/install/\">install</a> it on the server."}
    }
} -on_submit {
    # Find the package pretty name from the list of packages
    array set package_pretty_name [list]
    foreach elm $packages {
	set package_pretty_name([lindex $elm 1]) [lindex $elm 0]
    }
    if { [catch {
	foreach one_package_key $package_key {
	    set folder [site_node::verify_folder_name \
			    -parent_node_id [ad_conn node_id] \
			    -instance_name $package_pretty_name($one_package_key)]
	    
	    site_node::instantiate_and_mount \
		-parent_node_id [ad_conn node_id] \
		-node_name $folder \
		-package_name $package_pretty_name($one_package_key) \
		-package_key $one_package_key
	}
    } errmsg] } {
	global errorInfo
	ns_log Error "Error creating application: $errmsg\n$errorInfo"
	ad_return_error "Problem Creating Application" "We had a problem creating the application."
    }
} -after_submit {
    ad_returnredirect $return_url
    ad_script_abort
}
