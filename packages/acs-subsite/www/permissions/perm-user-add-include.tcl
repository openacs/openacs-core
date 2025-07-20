ad_page_contract {
} {
    object_id:naturalnum,notnull
    return_url:localurl
    page:naturalnum,optional
    {search ""}
}

#
# Check if the current user has read permission on this object_id.
#
permission::require_permission -object_id $object_id -privilege admin

# TODO:
# parties, select privileges, css, clean up

#set templating datasources

set user_id [ad_conn user_id]

set perm_url "[lindex [site_node::get_url_from_object_id -object_id [site_node::closest_ancestor_package -include_self -package_key [subsite::package_keys]]] 0]permissions/"

ad_form \
    -name filter \
    -edit_buttons [list [list "Go" go]] \
    -has_submit 1 \
    -html { class foo } \
    -export {return_url object_id page} \
    -form {
        {search:text,optional
            {label ""}
            {html {length 30 placeholder "[_ acs-kernel.common_Search]"} }
            {value $search}
        }
    } -on_submit {}

list::create \
    -name users \
    -multirow users \
    -key user_id \
    -page_size 10 \
    -page_query_name users_who_dont_have_any_permissions_paginator \
    -no_data "[_ acs-subsite.lt_There_are_no_users_wh]" \
    -bulk_action_export_vars { return_url object_id } \
    -bulk_actions [list \
                       "[_ acs-subsite.Add_users]" "${perm_url}perm-user-add-2" "[_ acs-subsite.lt_Add_checked_users_to_]" \
                      ]  \
    -elements {
        name {
            label "[_ acs-subsite.Name]"
        }
        email {
            label "[_ acs-subsite.Email]"
            link_url_eval {mailto:$email}
        }
        add {
            label "[_ acs-subsite.Add]"
            link_url_col add_url
            link_html { title "[_ acs-subsite.Add_this_user]" }
            display_template "<adp:icon name='add-new-item' title='[_ acs-subsite.Add_this_user]'>"
        }
    } -filters {
        object_id {}
        return_url {}
        search {
            hide_p 1
            where_clause {
                (:search is null
                 or upper(u.first_names || ' ' || u.last_name) like '%' || upper(:search) || '%'
                 or upper(u.email) like '%' || upper(:search) || '%'
                 )
            }
        }
    }

db_multirow -extend { add_url } users users_who_dont_have_any_permissions {} {
    set add_url [export_vars -base "${perm_url}perm-user-add-2" { return_url object_id user_id }]
}

set img_path "[ad_conn package_url]images"

set form_export_vars [export_vars -form {object_id return_url }]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
