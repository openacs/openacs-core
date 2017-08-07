ad_page_contract {
    Create and mount a new Subsite

    @author Steffen Tiedemann Christensen (steffen@christensen.name)
    @creation-date 2003-09-26
} {
    node_id:naturalnum,optional
}

auth::require_login

set page_title "[_ acs-subsite.New_subsite]"
set subsite_pretty_name "[_ acs-subsite.Subsite_name]"

set context [list $page_title]

ad_form -name subsite -cancel_url . -form {
    {node_id:key}}

set subsite_package_options [subsite::util::get_package_options]

if { [llength $subsite_package_options] == 1 } {
    ad_form -extend -name subsite -form {
        {package_key:text(hidden)
            {value "[lindex $subsite_package_options 0 1]"}
        }
    }
} else {
    ad_form -extend -name subsite -form {
        {package_key:text(select)
            {label "[_ acs-subsite.Subsite_Package]"}
            {help_text "Choose the subsite package you'd like to mount"}
            {options $subsite_package_options}
        }
    }
}

ad_form -extend -name subsite -form {
    {instance_name:text
        {label $subsite_pretty_name}
        {help_text "[_ acs-subsite.The_name_of_the_new_subsite_you_re_setting_up]"}
        {html {size 30}}
    }
    {folder:url_element(text),optional
        {label "[_ acs-subsite.URL_folder_name]"}
        {help_text "[_ acs-subsite.This_should_be_a_short_string]"}
        {html {size 30}}
    }
    {theme:text(select)
        {label "[_ acs-subsite.Theme]"}
        {help_text "[_ acs-subsite.Choose_the_layout_and_navigation]"}
        {options [subsite::get_theme_options]}
    }
    {visibility:text(select)
        {label "[_ acs-subsite.Visible_to]"}
        {options { { "[_ acs-subsite.Members_only]" "members" } { "[_ acs-subsite.Anyone]" "any" } }}
    }
    {join_policy:text(select)
        {label "[_ acs-subsite.Join_policy]"}
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

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
