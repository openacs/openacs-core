# /packages/mbryzek-subsite/www/admin/rel-segments/constraints/new.tcl

ad_page_contract {

    Form to add a constraint

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 11:45:21 2000
    @cvs-id $Id$

} {
    rel_segment:notnull,integer
    constraint_name:optional
    rel_side:optional
    required_rel_segment:optional
    { return_url "" }
} -properties {
    context:onevalue
    segment_name:onevalue
    return_url_enc:onevalue
    violations:onerow
} -validate {
    rel_segment_in_scope_p -requires {rel_segment:notnull} {
	if { ![application_group::contains_segment_p -segment_id $rel_segment]} {
	    ad_complain "The relational segment either does not exist or does not belong to this subsite."
	}
    }
    segment_in_scope_p -requires {required_rel_segment:notnull} {
	if { ![application_group::contains_segment_p -segment_id $required_rel_segment]} {
	    ad_complain "The required relational segment either does not exist or does not belong to this subsite."
	}
    }

}

set return_url_enc [ad_urlencode "[ad_conn url]?[ad_export_vars {rel_segment constraint_name rel_side required_rel_segment return_url}]"]

set context [list [list "../" "Relational segments"] [list "../one?segment_id=$rel_segment" "One Segment"] "Add constraint"]

set package_id [ad_conn package_id]

db_1row select_rel_properties {
    select s.segment_name, 
           acs_rel_type.role_pretty_name(t.role_one) as role_one_name,
           acs_rel_type.role_pretty_name(t.role_two) as role_two_name
      from rel_segments s, acs_rel_types t
     where s.rel_type = t.rel_type
       and s.segment_id = :rel_segment
}

template::form create constraint_new

template::element create constraint_new rel_segment \
	-value $rel_segment \
	-datatype text \
	-widget hidden

template::element create constraint_new return_url \
	-optional \
	-value $return_url \
	-datatype text \
	-widget hidden

template::element create constraint_new constraint_name \
	-label "Constraint name" \
	-datatype text \
	-widget text \
	-html {maxlength 100}

set option_list [list \
	[list "-- Select --" ""] \
	[list "$role_one_name (Side 1)" one] \
	[list "$role_two_name (Side 2)" two]]

template::element create constraint_new rel_side \
	-datatype "text" \
	-widget select \
	-options $option_list \
	-label "Add constraint for which side?"

set segment_list [db_list_of_lists select_segments {
    select s.segment_name, s.segment_id
      from application_group_segments s
     where s.segment_id <> :rel_segment
       and s.package_id = :package_id

     order by lower(s.segment_name)
}]

if { [llength $segment_list] == 0 } {
    ad_return_complaint 1 "<li> There are currently no other segments. You must have at least two segments before you can create a constraint"
    return
}

template::element create constraint_new required_rel_segment \
	-datatype "text" \
	-widget select \
	-options $segment_list \
	-label "Select segment"

if { [template::form is_valid constraint_new] } {
    # To what should we set context_id?
    set creation_user [ad_conn user_id]
    set creation_ip [ad_conn peeraddr]
    set ctr 0
    db_transaction {
	set constraint_id [db_exec_plsql add_constraint {
	 BEGIN
	  :1 := rel_constraint.new(constraint_name => :constraint_name,
                                   rel_segment => :rel_segment,
                                   rel_side => :rel_side,
                                   required_rel_segment => :required_rel_segment,
                                   creation_user => :creation_user,
                                   creation_ip => :creation_ip
                                  );
	 END;
	}]

	# check for violations
	template::multirow create violations rel_id name
	db_foreach select_violated_rels {
	    select viol.rel_id, acs_object.name(viol.party_id) as name
	      from rel_constraints_violated_one viol
	     where viol.constraint_id = :constraint_id
	    UNION ALL
	    select viol.rel_id, acs_object.name(viol.party_id) as name
	      from rel_constraints_violated_two viol
	     where viol.constraint_id = :constraint_id
	} {
	    template::multirow append violations $rel_id $name
	    incr ctr
	} 
	if { $ctr > 0 } {
	    # there are violations... abort the transaction then show
	    # the user the erroneous relations
	    db_abort_transaction
	}
    } on_error {
	if { $ctr == 0 } {
	    # Return the error message
	    ad_return_error "Error creating the constraint" "We got the following error while trying to create the constraint: <pre>$errmsg</pre>"
	    return
	} 
    }
    if { $ctr > 0 } {
	# show the user the erroneous relations, then abort
	ad_return_template violations
	return
    }
    if { [empty_string_p $return_url] } {
	set return_url "../one?segment_id=$rel_segment"
    }
    ad_returnredirect $return_url
    ad_script_abort
}

