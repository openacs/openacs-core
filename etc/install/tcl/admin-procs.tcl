# Procs to support testing OpenACS with Tclwebtest.
#
# Procs related to OpenACS admin (APM, parameters, site map etc.)
# A few of these procs are no longer so important now that we have
# the install.xml files for mounting packages and setting parameter values.
#
# @author Peter Marklund

namespace eval ::twt::admin {}

ad_proc ::twt::admin::install_all_packages { server_url } {

    ::twt::do_request "$server_url/acs-admin/apm/packages-install?checked_by_default_p=1"
    #assert text "Package Installation"
    # If there are no new packages to install, just return
    if { [regexp -nocase {no new packages to install} [response body] match] } {
        return
    }

    form submit

    # Sometimes there are failed dependencies for certain packages    
    # In this case we ignore those packages and continue
    if { [regexp {.*packages-install-2} "$::tclwebtest::url" match]} {
        form submit
    }

    #assert text "Select Data Model Scripts to Run"
    # Source SQL scripts (took 68s)
    form submit
}

ad_proc ::twt::admin::add_main_site_folder { server_url folder_name } {

	::twt::do_request "$server_url/admin/site-map"

	link follow ~c "new sub folder" 
	form find ~a new 
	field find ~n name
	field fill "$folder_name"
	form submit
}

ad_proc ::twt::admin::mount_main_site_package { server_url folder_name instance_name package_key } {

    ::twt::do_request "$server_url/admin/site-map"

    # Follow the link to add a new application at the first matching folder name
    link find ~c $folder_name
    link follow ~c "new application"

    # Add the package instance
    form find ~a "package-new"
    field find ~n instance_name
    field fill "$instance_name"
    # package_key
    field select "$package_key"
    form submit
}

# FIXME: This proc is very vulnerable since the parameter-set form in
# the site-map uses parameter_id to identify parameters
# We should put a db-exec.tcl file on the server instead to be able to retrieve
# the parameter_id of the parameter.
ad_proc ::twt::admin::submit_acs_param_internal { old_parameter_value new_parameter_value } {

    form find ~a "parameter-set-2"
    field find ~v "$old_parameter_value"
    field fill "$new_parameter_value"
    form submit
}

ad_proc ::twt::admin::set_acs_subsite_param { server_url old_parameter_value parameter_value } {

    ::twt::do_request "$server_url/admin/site-map"
    link follow ~u {parameter-set\?package%5fid=[0-9]+&package%5fkey=acs%2dsubsite&instance%5fname=Main%20Site}

    submit_acs_param_internal $old_parameter_value $parameter_value
}

ad_proc ::twt::admin::set_acs_kernel_param { server_url param_section old_parameter_value parameter_value } {

    ::twt::do_request "$server_url/admin/site-map"
    link follow ~u {parameter-set\?package%5fid=[0-9]+&package%5fkey=acs%2dkernel}

    if { $param_section ne "acs-kernel" } {
	link follow ~c "$param_section"
    }

    submit_acs_param_internal $old_parameter_value $parameter_value
}
