ad_page_contract {
    Create and mount a new Subsite/Community.

    @author Steffen Tiedemann Christensen (steffen@christensen.name)
    @creation-date 2003-09-26
} {
    node_id:integer,optional
}

if ([string equal [ad_conn package_url] "/"]) {
    set page_title "New community"
    set subsite_pretty_name "Community name"
} else {
    set page_title "New subcommunity"
    set subsite_pretty_name "Subcommunity name"
}
set context [list [list "." "Communities"] $page_title]


set master_template_options [list]
lappend master_template_options [list "Default" "/www/default-master"]
lappend master_template_options [list "Community" "/packages/acs-subsite/www/group-master"]
set current_master [parameter::get -parameter DefaultTemplate]
set found_p 0
foreach elm $master_template_options {
    if { [string equal $current_master [lindex $elm 1]] } {
        set found_p 1
        break
    }
}
if { !$found_p } {
    lappend master_template [list $current_master $current_master]
}


ad_form -name subsite -cancel_url . -form {
    {node_id:key}
    {instance_name:text
        {label $subsite_pretty_name}
        {help_text "The name of the new community you're setting up."}
        {html {size 30}}
    }
    {folder:text,optional
        {label "URL folder name"}
        {help_text "This should be a short string, all lowercase, with hyphens instead of spaces, whicn will be used in the URL of the new application. If you leave this blank, we will generate one for you from name of the application."}
        {html {size 30}}
    }
    {master_template:text(select)
        {label "Template"}
        {help_text "Choose the layout and navigation you want for your community."}
        {options $master_template_options}
    }
} -on_submit {
    set folder [site_node::verify_folder_name \
                    -parent_node_id [ad_conn node_id] \
                    -current_node_id $node_id \
                    -folder $folder \
                    -instance_name $instance_name]

    if { [empty_string_p $folder] } {
        form set_error subsite folder "This folder name is already used"
        break
    }
} -new_data {
    if { [catch {
        set new_package_id [site_node::instantiate_and_mount \
                                -parent_node_id [ad_conn node_id] \
                                -node_name $folder \
                                -package_name $instance_name \
                                -package_key acs-subsite]
        
        parameter::set_value -parameter DefaultMaster -package_id $new_package_id -value $master_template
    } errsmg] } {
        ad_return_error "Problem Creating Application" "We had a problem creating the community."
    }
} -after_submit {
    ad_returnredirect ../$folder
    ad_script_abort
}
