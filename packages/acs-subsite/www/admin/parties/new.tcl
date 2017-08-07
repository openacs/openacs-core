# /packages/subsite/www/admin/parties/new.tcl

ad_page_contract {

    Adds a new party

    @author oumi@arsdigita.com
    @creation-date 2000-02-07
    @cvs-id $Id$

} {
    party_type:notnull
    { party_type_exact_p:boolean t }
    { party_id:naturalnum "" }
    { party.email ""}
    { return_url:localurl "" }
    {add_to_group_id:naturalnum ""}
    {add_with_rel_type "membership_rel"}
    {group_rel_type_list ""}
} -properties {
    context:onevalue
    party_type_pretty_name:onevalue
    attributes:multirow
}

set context [list [list "" "Parties"] "Add a party"]

if {$add_to_group_id eq ""} {
    set add_to_group_id [application_group::group_id_from_package_id]
}

set export_var_list [list \
	party_id party_type add_to_group_id add_with_rel_type \
	return_url party_type_exact_p group_rel_type_list]

db_1row group_info {
    select group_name as add_to_group_name, 
           join_policy as add_to_group_join_policy
    from groups
    where group_id = :add_to_group_id
}

# We assume the group is on side 1... 
db_1row rel_type_info {}

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


# Select out the party name and the party's object type. Note we can
# use 1row because the validate filter above will catch missing parties

db_1row select_type_info {
    select t.pretty_name as party_type_pretty_name,
           t.table_name
      from acs_object_types t
     where t.object_type = :party_type
}

# Check if the new party needs to first be added in other segments before
# being added to $add_to_group_id using $add_with_rel_type.

if {$group_rel_type_list eq ""} {
    set required_group_rel_type_list [relation_required_segments_multirow \
	    -datasource_name required_segments \
	    -group_id $add_to_group_id \
	    -rel_type $add_with_rel_type]

    if {[llength $required_group_rel_type_list] > 0} {
	# There are required segments that the soon-to-exist party must be in
	# before it can be added to $add_to_group_id with rel type 
	# $add_with_rel_type.  We'll return a notice to the user, and give
	# them a link to begin the process of adding the party in the right
	# segments.
	
	# set up variables for template
	set rel_type_pretty_name [subsite::util::object_type_pretty_name $add_with_rel_type]
	set group_name [acs_object_name $add_to_group_id]
	set object_type_pretty_name $party_type_pretty_name
	
	# We're going to have to pass the required_group_rel_type_list to the
	# next page.  The easiest way I see to do this is just encode the list
	# in a variable, since the list is just a string anyways.
	
	# We don't care about the first group/rel_type combo, because we'll pass
	# that information explicitly in other variables.
	set group_rel_type_list [lrange $required_group_rel_type_list 1 end]
	
	# We also want to make sure that the user is finally returned to a page
	# where they can put the new party in the original group they were 
	# attempting, and with the original relationship type they wanted.
	# We can't use return_url because we don't yet know the party_id.  So
	# we'll just add to group_rel_type_list
	lappend group_rel_type_list [list $add_to_group_id $add_with_rel_type]
	
	lappend export_var_list group_rel_type_list
	
	set export_url_vars [export_vars -exclude {add_to_group_id add_with_rel_type} $export_var_list]
	
	ad_return_template new-list-required-segments
	return
    }
}


### This page redirects to different pages for groups or rel_segments.
### We have to check whether the party_type is a type of group or rel_segment.

# Get a list of types in the type hierarchy that are in the path between
# 'party' and $party_type
set object_type_path_list [subsite::util::object_type_path_list $party_type party]

set redirects_for_type [list \
	group "groups/new?group_id=$party_id&group_type_exact_p=$party_type_exact_p&group_type=$party_type&[export_vars -exclude {party_id party_type_exact_p party_type} $export_var_list]" \
	rel_segment "rel-segments/new?segment_id=$party_id&group_id=$add_to_group_id" \
	user "users/new?user_id=$party_id&[export_vars -exclude {party_id party_type_exact_p party_type} $export_var_list]"]

foreach {type url} $redirects_for_type {
    if {[lsearch $object_type_path_list $type] != -1} {
	ad_returnredirect [ad_conn package_url]admin/$url
    }
}


if { $party_type_exact_p == "f" 
     && [subsite::util::sub_type_exists_p $party_type] } {

    # Sub party-types exist... select one
    set party_type_exact_p "t"
    set export_url_vars [export_vars -exclude party_type $export_var_list ]

    party::types_valid_for_rel_type_multirow -datasource_name object_types -start_with $party_type -rel_type $add_with_rel_type

    set object_type_pretty_name $party_type_pretty_name
    set this_url [ad_conn url]
    set object_type_variable party_type

    ad_return_template add-select-type
    return
}

template::form create add_party

if { [template::form is_request add_party] } {
    
    foreach var $export_var_list {
	template::element create add_party $var \
		-value [set $var] \
		-datatype text \
		-widget hidden
    }

    # Set the object id for the new party
    template::element set_properties add_party party_id \
	    -value [db_nextval "acs_object_id_seq"]

}

attribute::add_form_elements -form_id add_party -variable_prefix party -start_with party -object_type $party_type

attribute::add_form_elements -form_id add_party -variable_prefix rel -start_with relationship -object_type $add_with_rel_type


if { [template::form is_valid add_party] } {

    db_transaction {
	set party_id [party::new \
                          -email ${party.email} \
                          -form_id add_party \
                          -variable_prefix party \
                          -party_id $party_id \
                          -context_id [ad_conn package_id] \
                          $party_type]

	relation_add -member_state $member_state $add_with_rel_type $add_to_group_id $party_id
    }

    # there may be more segments to put this new party in before the
    # user's original request is complete.   So build a return_url stack
    foreach group_rel_type $group_rel_type_list {
	lassign $group_rel_type next_group_id next_rel_type
	lappend return_url_list \
	    [export_vars -base "../relations/add" {
		{group_id $next_group_id}
		{rel_type $next_rel_type}
		party_id
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


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
