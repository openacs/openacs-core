# /packages/acs-subsite/www/admin/relations/add.tcl

ad_page_contract {
    Add the user to the subsite application group.

    @author oumi@arsdigita.com
    @creation-date 2000-2-28
    @cvs-id $Id$
} {
    {group_id:integer {[application_group::group_id_from_package_id]}}
    {rel_type:notnull "membership_rel"}
    { return_url "" }
} -properties {
    context:onevalue
    role_pretty_name:onevalue
    group_name:onevalue
    export_form_vars:onevalue
} -validate {
    rel_type_valid_p {
	if {![relation_type_is_valid_to_group_p -group_id $group_id $rel_type]} {
	    ad_complain "Cannot join this group."
	}
    }
}


db_1row group_info {
    select group_name, join_policy
    from groups
    where group_id = :group_id
}

if {[string equal $join_policy closed]} {
    ad_complain "Cannot join this group."
}

set export_var_list [list group_id rel_type return_url]

set party_id [ad_conn user_id]

set context [list "Join $group_name"]

template::form create join

relation_required_segments_multirow \
	-datasource_name required_segments \
	-group_id $group_id \
	-rel_type $rel_type


set num_required_segments [template::multirow size required_segments]

if {[template::form is_request join]} {

    for {set rownum 1} {$rownum <= $num_required_segments } {incr rownum} {
	set required_seg [template::multirow get required_segments $rownum]
	
	if {[string equal $required_segments(join_policy) closed]} {
	    ad_complain "Cannot join this group."
	    return
	}
    
	set segment_id $required_segment(segment_id)
	set cur_group_id $required_segment(group_id)
	set cur_rel_type $required_segment(rel_type)

	attribute::add_form_elements -form_id join -variable_prefix seg_$segment_id -start_with relationship -object_type $cur_rel_type

    }
}  

attribute::add_form_elements -form_id join -start_with relationship -object_type $rel_type

if {[template::form::size join] == 0} {
    # There's no attributes to ask the user for, so just add the user to
    # the group (instead of displaying a 0 element form).
    set just_do_it_p 1
}

foreach var $export_var_list {
    template::element create join $var \
	    -value [set $var] \
	    -datatype text \
	    -widget hidden
}

if {$just_do_it_p || [template::form is_valid join]} {

    db_transaction {
	for {set rownum 1} {$rownum <= $num_required_segments } {incr rownum} {
	    set required_seg [template::multirow get required_segments $rownum]
	    
	    if {[string equal $required_segments(join_policy) closed]} {
		ad_complain "Cannot join this group."
		return
	    }
	    
	    if {[string equal $required_segments(join_policy) "needs approval"]} {
		set member_state "needs approval"
	    } else {
		set member_state "approved"
	    }

	    set segment_id $required_segment(segment_id)
	    set cur_group_id $required_segment(group_id)
	    set cur_rel_type $required_segment(rel_type)

	    set rel_id [relation_add -form_id join -variable_prefix seg_$segment_id -member_state $member_state $cur_rel_type $cur_group_id $party_id]

	}
    
	if {[string equal $join_policy "needs approval"]} {
	    set member_state "needs approval"
	} else {
	    set member_state "approved"
	}

	set rel_id [relation_add -form_id join -member_state $member_state $rel_type $group_id $party_id]

	if { [empty_string_p $return_url] } { 
	    set return_url [ad_conn package_url]
	}
	
    } on_error {
	ad_return_error "Error creating the relation" "We got the following error message while trying to create this relation: <pre>$errmsg</pre>"
	ad_script_abort
    }

    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template
