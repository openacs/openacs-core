# /packages/mbryzek-subsite/www/admin/group-types/delete.tcl

ad_page_contract {

    Confirms deletion of a group type

    @author mbryzek@arsdigita.com
    @creation-date Wed Nov  8 18:22:04 2000
    @cvs-id $Id$

} {
    group_type:notnull
    { return_url:localurl "" }
} -properties {
    subtypes:multirow
    context:onevalue
    export_url_vars:onevalue
    export_form_vars:onevalue
    group_type:onevalue
    group_type_pretty_name:onevalue
    groups_of_this_type:onevalue
    relations_to_this_type:onevalue
} -validate {
    user_can_delete_type -requires {group_type:notnull} {
	if { ![group_type::drop_all_groups_p $group_type] } {
	    ad_complain "Groups exist that you do not have permission to delete. All groups must be deleted before you can remove a group type. Please contact the site administrator."
	}
    }
}

set context [list \
         [list "[ad_conn package_url]admin/group-types/" "Group types"] \
         [list [export_vars -base one {group_type}] "One group type"] \
         "Delete group type"]

if { ![db_0or1row select_pretty_name {
    select t.pretty_name as group_type_pretty_name
      from acs_object_types t
     where t.object_type = :group_type
}] } {
    ad_return_error "Group type doesn't exist" "Group type \"$group_type\" doesn't exist"
    return
}

set subtypes_exist_p [db_string number_subtypes {}]

if { $subtypes_exist_p } {
    set return_url "[ad_conn url]?[ad_conn query]"

    # Just grab direct children... 
    template::multirow create subtypes pretty_name export_vars

    db_foreach select_subtypes {
	select t.object_type as group_type, t.pretty_name
          from acs_object_types t
         where t.supertype = :group_type
    } {
	template::multirow append subtypes $pretty_name [export_vars {group_type return_url}]
    }
    ad_return_template "delete-subtypes-exist"
    return
}

# Now let's check if any relationship types depend on this group type
set rel_types_depend_p [db_string rel_type_exists_p {}]

if { $rel_types_depend_p } {
    set return_url "[ad_conn url]?[ad_conn query]"

    # Grab the rel types that depend on this one
    template::multirow create rel_types pretty_name export_vars

    db_foreach select_rel_types {
	select rel.rel_type, t.pretty_name
          from acs_rel_types rel, acs_object_types t
         where (rel.object_type_one = :group_type 
                or rel.object_type_two = :group_type)
	   and rel.rel_type = t.object_type
    } {
	template::multirow append rel_types $pretty_name [export_vars {rel_type return_url}]
    }
    ad_return_template "delete-rel-types-exist"
    return
}

set export_form_vars [export_vars -form {group_type return_url}]

set groups_of_this_type [util_commify_number [db_string groups_of_this_type {
    select count(o.object_id) 
      from acs_objects o
     where o.object_type = :group_type
}]]

set relations_to_this_type [util_commify_number [db_string relations_to_this_type {
    select count(r.rel_id)
      from acs_rels r
     where r.rel_type in (select t.rel_type
                            from acs_rel_types t
                           where t.object_type_one = :group_type
                              or t.object_type_two = :group_type)
}]]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
