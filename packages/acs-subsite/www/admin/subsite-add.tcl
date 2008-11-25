ad_page_contract {
    Create and mount a new Subsite

    @author Steffen Tiedemann Christensen (steffen@christensen.name)
    @creation-date 2003-09-26
} {
    node_id:integer,optional
}

auth::require_login

set page_title "New subsite"
set subsite_pretty_name "Subsite name"

set context [list $page_title]

ad_form -name subsite -cancel_url . -form {
    {node_id:key}}

set subsite_package_options [subsite::util::get_package_options]

if { [llength $subsite_package_options] == 1 } {
    ad_form -extend -name subsite -form {
        {package_key:text(hidden)
            {value "[lindex [lindex $subsite_package_options 0] 1]"}
        }
    }
} else {
    ad_form -extend -name subsite -form {
        {package_key:text(select)
            {label "Subsite Package"}
            {help_text "Choose the subsite package you'd like to mount"}
            {options $subsite_package_options}
        }
    }
}

ad_form -extend -name subsite -form {
    {instance_name:text
        {label $subsite_pretty_name}
        {help_text "The name of the new subsite you're setting up."}
        {html {size 30}}
    }
    {folder:url_element(text),optional
        {label "URL folder name"}
        {help_text "This should be a short string, all lowercase, with hyphens instead of spaces, whicn will be used in the URL of the new application. If you leave this blank, we will generate one for you from name of the application."}
        {html {size 30}}
    }
    {theme:text(select)
        {label "Theme"}
        {help_text "Choose the layout and navigation theme you want for your subsite."}
        {options [subsite::get_theme_options]}
    }
    {visibility:text(select)
        {label "Visible to"}
        {options { { "Members only" "members" } { "Anyone" "any" } }}
    }
    {join_policy:text(select)
        {label "Join policy"}
        {options [group::get_join_policy_options]}
    }
} -on_submit {
    set folder [site_node::verify_folder_name \
                    -parent_node_id [ad_conn node_id] \
                    -current_node_id $node_id \
                    -folder $folder \
                    -instance_name $instance_name]

    if { $folder eq "" } {
        form set_error subsite folder "This folder name is already used"
        break
    }
} -new_data {
    db_transaction {
        # Create and mount new subsite
        set new_package_id [site_node::instantiate_and_mount \
                                -parent_node_id [ad_conn node_id] \
                                -node_name $folder \
                                -package_name $instance_name \
                                -package_key $package_key]
        
        # Set template
        subsite::set_theme -subsite_id $new_package_id -theme $theme

        # Set join policy
        set group(join_policy) $join_policy
        set member_group_id [application_group::group_id_from_package_id -package_id $new_package_id]
        group::update -group_id $member_group_id -array group

        # Add current user as admin
	group::add_member \
            -no_perm_check \
            -member_state "approved" \
            -rel_type "admin_rel" \
            -group_id $member_group_id \
            -user_id [ad_conn user_id]
        
        # Set inheritance (called 'visibility' in form)
        if { $visibility ne "any" } {
            permission::set_not_inherit -object_id $new_package_id
        }
        
    } on_error {
        ad_return_error "Problem Creating Application" "We had a problem creating the subsite."
    }
} -after_submit {
    ad_returnredirect ../$folder
    ad_script_abort
}
