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
    -no_data "There are no users who don't already have access to this object" \
    -bulk_action_export_vars { return_url object_id } \
    -bulk_actions [list \
                       "Add users" "${perm_url}perm-user-add-2" "Add checked users to users who have permissions on your object." \
                      ]  \
    -elements {
        name {
            label "Name"
        }
        email {
            label "Email"
            link_url_eval {mailto:$email}
        }
        add {
            label "Add"
            link_url_col add_url
            link_html { title "Add this user" }
            display_template "Add"
        }
    } -filters {
	object_id {}
	return_url {}
    }

set page_where_clause [list::page_where_clause -name users -and]

db_multirow -extend { add_url } users users_who_dont_have_any_permissions {} {
    set add_url [export_vars -base "${perm_url}perm-user-add-2" { return_url object_id user_id }]
}

set img_path "[ad_conn package_url]images"

set form_export_vars [export_vars -form {object_id return_url }]
