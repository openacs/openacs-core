# /packages/mbryzek-subsite/www/admin/groups/new.tcl

ad_page_contract {

    Adds a new group

    @author mbryzek@arsdigita.com
    @creation-date Wed Nov  8 19:29:22 2000
    @cvs-id $Id$

} {
    group_type:notnull
    { group_type_exact_p:boolean t }
    { group_name "" }
    { group_id:naturalnum "" }
    {add_to_group_id:integer ""}
    {add_with_rel_type "composition_rel"}
    { return_url "" }
    {group_rel_type_list ""}
} -properties {
    context:onevalue
    group_type_pretty_name:onevalue
    attributes:multirow
} -validate {
    double_click -requires {group_id:notnull} {
	if { [db_string group_exists_p {
	    select count(*) from groups where group_id = :group_id
	}] } {
	    ad_complain "The specified group already exists... Maybe you double-clicked?"
	}
    }
}

set context [list [list "[ad_conn package_url]admin/groups/" "Groups"] "Add a group"]

if {$add_to_group_id eq ""} {
    set add_to_group_id [application_group::group_id_from_package_id]
}

db_1row group_info {
    select group_name as add_to_group_name, 
           join_policy as add_to_group_join_policy
    from groups
    where group_id = :add_to_group_id
}

# We assume the group is on side 1... 
db_1row rel_type_info {
    select object_type as ancestor_rel_type
      from acs_object_types
     where supertype = 'relationship'
       and object_type in (
               select object_type from acs_object_types
               start with object_type = :add_with_rel_type
               connect by object_type = prior supertype
           )
}

set create_p [group::permission_p -privilege create $add_to_group_id]

# Membership relations have a member_state attribute that gets set
# based on the group's join policy.
if {$ancestor_rel_type eq "membership_rel"} {
    if {$add_to_group_join_policy eq "closed" && !$create_p} {
	ad_complain "You do not have permission to add elements to $add_to_group_name"
	return
    }

    set member_state [group::default_member_state -join_policy $add_to_group_join_policy -create_p $create_p]
} else {
    set member_state ""
}

db_1row select_type_info {
    select t.pretty_name as group_type_pretty_name,
           t.table_name
      from acs_object_types t
     where t.object_type = :group_type
}

set export_var_list [list group_id group_type \
	    add_to_group_id add_with_rel_type return_url]

## ISSUE / TO DO: (see also admin/users/new.tcl)
##
## Should there be a check here for required segments, as there is
## in parties/new.tcl? (see parties/new.tcl, search for 
## "relation_required_segments_multirow).
##
## Tentative Answer: we don't need to repeat that semi-heinous check on this
## page, because (a) the user should have gotten to this page through
## parties/new.tcl, so the required segments check should have already 
## happened before the user reaches this page.  And (b) even if the user
## somehow bypassed parties/new.tcl, they can't cause any relational 
## constraint violations in the database because the constraints are enforced
## by triggers in the DB.

if { $group_type_exact_p == "f" 
     && [subsite::util::sub_type_exists_p $group_type] } {

    # Sub rel-types exist... select one
    set group_type_exact_p "t"
    set export_url_vars [export_vars -exclude group_type $export_var_list ]

    party::types_valid_for_rel_type_multirow -datasource_name object_types -start_with $group_type -rel_type $add_with_rel_type

    set object_type_pretty_name $group_type_pretty_name
    set this_url [ad_conn url]
    set object_type_variable group_type

    ad_return_template ../parties/add-select-type
    return
}

template::form create add_group

attribute::add_form_elements -form_id add_group -variable_prefix group -start_with group -object_type $group_type
attribute::add_form_elements -form_id add_group -variable_prefix rel -start_with relationship -object_type $add_with_rel_type

if { [template::form is_request add_group] } {
    
    foreach var $export_var_list {
	template::element create add_group $var \
		-value [set $var] \
		-datatype text \
		-widget hidden
    }

    # Set the object id for the new group
    template::element set_properties add_group group_id \
	    -value [db_nextval "acs_object_id_seq"]

}

if { [template::form is_valid add_group] } {
    db_transaction {
	group::new -form_id add_group -variable_prefix group -group_id $group_id -context_id [ad_conn package_id] $group_type 
	relation_add -member_state $member_state $add_with_rel_type $add_to_group_id $group_id
    }

    # there may be more segments to put this new group in before the
    # user's original request is complete.   So build a return_url stack
    set package_url [ad_conn package_url]

    foreach group_rel_type $group_rel_type_list {
	lassign $group_rel_type next_group_id next_rel_type
	lappend return_url_list \
	    [export_vars -base "${package_url}admin/relations/add" {
		{group_id $next_group_id}
		{rel_type [ad_urlencode $next_rel_type]}
		{party_id $group_id}
		{allow_out_of_scope_p t}
	    }]
    }

    # Add the original return_url as the last one in the list
    lappend return_url_list $return_url

    set return_url_stacked [subsite::util::return_url_stack $return_url_list]

    ad_returnredirect $return_url_stacked
    ad_script_abort
}


ad_return_template

