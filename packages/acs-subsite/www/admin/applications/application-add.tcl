ad_page_contract {
    Create and mount a new application.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-05-28
    @cvs-id $Id$
} {
    node_id:naturalnum,optional
    {return_url:localurl "."}
}

set page_title "[_ acs-subsite.New_Application]"
set context [list [list "." "Applications"] $page_title]

set packages [subsite::get_application_options]

if { [ad_form_new_p -key node_id] } {
    set focus application.package_key
} else {
    set focus application.instance_name
}


set main_subsite_id [site_node::get_node_id -url "/"]
set main_subsite_p [expr {[info exists node_id] && $node_id == $main_subsite_id}]

set multiple_add_url [export_vars -base multiple-add { return_url }]

ad_form -name application -cancel_url . -form {
    {return_url:text(hidden),optional}
    {node_id:key}
    {package_key:text(select)
        {label "[_ acs-subsite.Application]"}
        {options $packages}
        {help_text "The type of application you want to add.  If the application is not in the list, you may need to <a href=\"/acs-admin/install/\">install</a> it on the server."}
        {mode {[expr {[ad_form_new_p -key node_id] ? "" : "display"}]}}
    }
    {instance_name:text,optional
        {label "[_ acs-subsite.Application_name]"}
        {help_text "The human-readable name of your application. If blank, the name of the application is used (e.g. 'Forums')."}
        {html {size 50}}
    }
    {folder:text,optional
        {label "[_ acs-subsite.URL_folder_name]"}
        {help_text "The partial URL of the new application.  This should be a short string, all lowercase, with hyphens instead of spaces. If blank, the package name is used (e.g. 'forum')."}
        {html "size 30 [expr {$main_subsite_p ? {disabled {}} : {}}]"}
    }
} -new_request {
    # Sets return_url
} -edit_request {
    array set node [site_node::get -node_id $node_id]
    set package_key $node(package_key)
    set instance_name $node(instance_name)
    set folder $node(name)
} -on_submit {
    if { $instance_name eq "" } {
        # Find the package pretty name from the list of packages

        foreach elm $packages {
            if {[lindex $elm 1] eq $package_key} {
                set instance_name [lindex $elm 0]
                break
            }
        }
        if { $instance_name eq "" } {
            error "Couldn't find package_key '$package_key' in list of system applications"
        }

    }
    
    if { [ad_form_new_p -key node_id] } {
        set current_node_id {}
    } else {
        set current_node_id $node_id
    }
    
    set folder [site_node::verify_folder_name \
                    -parent_node_id [ad_conn node_id] \
                    -current_node_id $current_node_id \
                    -folder $folder \
                    -instance_name $instance_name]

    if { $folder eq "" } {
        form set_error application folder "This folder name is already used"
        break
    }
    
} -new_data {
    ad_try {
        site_node::instantiate_and_mount \
            -parent_node_id [ad_conn node_id] \
            -node_name $folder \
            -package_name $instance_name \
            -package_key $package_key
    } on error {errorMsg} {
        ad_log warning "Problem creating application: $errorMsg"
        ad_return_error \
            "Problem Creating Application" \
            "We had a problem creating the application."
        ad_script_abort
    }
    
} -edit_data {
    # this is where we would rename ...
    
    array set node [site_node::get -node_id $node_id]
    set package_id $node(object_id)

    db_transaction {
        apm_package_rename -package_id $node(package_id) -instance_name $instance_name
        # Renaming the main subsite URL would make the system unusable
        if {$main_subsite_p} {
            set folder ""
        }
        site_node::rename -node_id $node_id -name $folder
    }

} -after_submit {
    ad_returnredirect $return_url
    ad_script_abort
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
