ad_page_contract {
    Configuration home page.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id$
}

set page_title [_ acs-subsite.Subsite_Configuration]
set context [list [_ acs-subsite.Configuration]]

set group_id [application_group::group_id_from_package_id]

ad_form -name name -cancel_url [ad_conn url] -mode display -form {
    {instance_name:text
        {label "[_ acs-subsite.Subsite_name]"}
        {html {size 50}}
    }
    {theme:text(select)
        {label "[_ acs-subsite.Theme]"}
        {help_text "Choose the layout and navigation theme you want for your subsite."}
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
    {description:text(textarea),optional
        {label "[_ acs-subsite.Description]"}
        {html { rows 6 cols 80 }}
    }
} -on_request {
    set instance_name [ad_conn instance_name]
    set theme [parameter::get -parameter ThemeKey -package_id [ad_conn package_id]]

    if { [permission::inherit_p -object_id [ad_conn package_id]] } {
        set visibility "any"
    } else {
        set visibility "members"
    }

    set join_policy [group::join_policy -group_id $group_id]
    set description [group::description -group_id $group_id]
} -on_submit {
    apm_package_rename -instance_name $instance_name
    subsite::set_theme -theme $theme
    set group(join_policy) $join_policy
    set group(description) $description
    group::update -group_id $group_id -array group

    switch $visibility {
        any {
            permission::set_inherit -object_id [ad_conn package_id]
        }
        members {
            permission::set_not_inherit -object_id [ad_conn package_id]
        }
    }


} -after_submit {
    ad_returnredirect [ad_conn url]
    ad_script_abort
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
