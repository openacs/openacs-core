ad_page_contract {
} {
    object_id:integer,notnull
    return_url
    page:integer,optional
}

# check they have read permission on this file

ad_require_permission $object_id admin

# TODO:
# parties, select privilges, css, clean up

#set templating datasources

set user_id [ad_conn user_id]

set perm_url "[site_node_closest_ancestor_package_url]permissions/"

list::create \
    -name users \
    -multirow users \
    -key user_id \
    -page_size 20 \
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
            display_template "[_ acs-subsite.Add]"
        }
    } -filters {
	object_id {}
	return_url {}
    }

db_multirow -extend { add_url } users users_who_dont_have_any_permissions {} {
    set add_url [export_vars -base "${perm_url}perm-user-add-2" { return_url object_id user_id }]
}

set img_path "[ad_conn package_url]images"

set form_export_vars [export_vars -form {object_id return_url }]
