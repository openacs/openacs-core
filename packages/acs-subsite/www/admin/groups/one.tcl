# /packages/acs-subsite/www/admin/groups/one.tcl

ad_page_contract {
    View one group.

    @author Michael Bryzek (mbryzek@arsdigita.com)

    @creation-date 2000-12-05
    @cvs-id $Id$
} {
    group_id:integer,notnull
} -properties {
    context:onevalue
    group_id:onevalue
    group_name:onevalue
    write_p:onevalue
    admin_p:onevalue
    return_url_enc:onevalue
    attributes:multirow
    more_relationship_types_p:onevalue
    join_policy:onevalue
} -validate {
    groups_exists_p -requires {group_id:notnull} {
	if { ![group::permission_p $group_id] } {
	    ad_complain "The group either does not exist or you do not have permission to view it"
	}
    }
    group_in_scope_p -requires {group_id:notnull} {
	if { ![application_group::contains_party_p -include_self -party_id $group_id]} {
	    ad_complain "The group either does not exist or does not belong to this subsite."
	}
    }
}

set user_id [ad_conn user_id]
set write_p [permission::permission_p -object_id $group_id -privilege "write"]
set admin_p [permission::permission_p -object_id $group_id -privilege "admin"]

set return_url "[ad_conn url]?[ad_conn query]"
set return_url_enc [ad_urlencode $return_url]

# Select out the group name and the group's object type. Note we can
# use 1row because the validate filter above will catch missing groups

db_1row group_info {
    select g.group_name, g.join_policy,
           o.object_type as group_type
      from groups g, acs_objects o, acs_object_types t
     where g.group_id = o.object_id
       and o.object_type = t.object_type
       and g.group_id = :group_id
}

set context [list [list "[ad_conn package_url]admin/groups/" "Groups"] "One Group"]

attribute::multirow \
	-start_with group \
	-datasource_name attributes \
	-object_type $group_type \
	$group_id

if {[apm_package_installed_p categories]} {
    set category_url [site_node::get_package_url -package_key categories]

    set mapped_trees [category_tree::get_mapped_trees $group_id]
    foreach mapped_tree $mapped_trees {
	lassign $mapped_tree tree_id tree_name subtree_id
	if {$subtree_id ne ""} {
	    set tree_name "${tree_name}::[category::get_name $subtree_id]"
	}
	lappend category_trees $tree_name
    }
    if {$mapped_trees eq ""} {
	set category_trees "None"
    }
    set category_trees [join $category_trees ,]
}

ad_return_template
