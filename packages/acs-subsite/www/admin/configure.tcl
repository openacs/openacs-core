ad_page_contract {
    Configuration home page.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id$
}

set page_title "Subsite Configuration"

set context [list "Configuration"]


ad_form -name name -cancel_url [ad_conn url] -mode display -form {
    {instance_name:text
        {label "Subsite name"}
        {html {size 50}}
    }
    {master_template:text(select)
        {label "Template"}
        {help_text "Choose the layout and navigation you want for your subsite."}
        {options [subsite::get_template_options]}
    }
    {visibility:text(select)
        {label "Visible to"}
        {options { { "Members only" "members" } { "Anyone" "any" } }}
    }
    {join_policy:text(select)
        {label "Join policy"}
        {options [group::get_join_policy_options]}
    }
} -on_request {
    set instance_name [ad_conn instance_name]
    set master_template [parameter::get -parameter DefaultMaster -package_id [ad_conn package_id]]

    if { [permission::inherit_p -object_id [ad_conn package_id]] } {
        set visibility "any"
    } else {
        set visibility "members"
    }

    set join_policy [group::join_policy -group_id [application_group::group_id_from_package_id]]

} -on_submit {
    apm_package_rename -instance_name $instance_name
    parameter::set_value -parameter DefaultMaster -package_id [ad_conn package_id] -value $master_template
    set group(join_policy) $join_policy
    group::update -group_id [application_group::group_id_from_package_id] -array group

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
