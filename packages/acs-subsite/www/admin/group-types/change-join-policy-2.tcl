# /packages/acs-subsite/www/admin/groups/one.tcl

ad_page_contract {
    Change default join policy for a group type.

    @author Oumi Mehrotra (oumi@arsdigita.com)

    @creation-date 2001-02-23
    @cvs-id $Id$
} {
    group_type:notnull
    default_join_policy:notnull
    {return_url ""}
}

if { ![db_0or1row select_pretty_name {
    select t.dynamic_p,
           decode(gt.group_type, null, 0, 1) as group_type_exists_p
      from acs_object_types t, group_types gt
     where t.object_type = :group_type
       and t.object_type = gt.group_type(+)
}] } {
    ad_return_error "Group type doesn't exist" "Group type \"$group_type\" doesn't exist"
    return
}

if {$dynamic_p != "t" } {
    ad_return_error "Cannot administer group type" "Group type \"$group_type\" can only be administered by programmers"
}


if {!$group_type_exists_p} {
    db_dml set_default_join_policy {
	insert into group_types
	(group_type, default_join_policy)
	values
	(:group_type, :default_join_policy)
    }
} else {
    db_dml update_join_policy {
	update group_types
	set default_join_policy = :default_join_policy
	where group_type = :group_type
    }
}

if {$return_url eq ""} {
    set return_url [export_vars -base one group_type]
}

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
