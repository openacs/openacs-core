# /packages/acs-subsite/www/admin/relations/add.tcl

ad_page_contract {
    Add the user to the subsite application group.

    @author oumi@arsdigita.com
    @author Randy O'Meara <omeara@got.net>

    @creation-date 2000-2-28
    @cvs-id $Id$
} {
    {group_id:integer {[application_group::group_id_from_package_id]}}
    {rel_type:notnull "membership_rel"}
    { return_url "[ad_conn package_url]" }
} -properties {
    context:onevalue
    role_pretty_name:onevalue
    group_name:onevalue
    export_form_vars:onevalue
} -validate {
    rel_type_valid_p {
        if {![relation_type_is_valid_to_group_p -group_id $group_id $rel_type]} {
            ad_complain "[_ acs-subsite.lt_Cannot_join_this_grou]"
        }
    }
}


# Randy O'Meara - 8/6/03 - Changes:
#    o added ad_maybe_redirect_for_registration as we must have a valid user_id
#      to join to the specified (or defaulted)  group.
#    o changed ad_complain calls to ad_return_complaint with a 'return' to the
#      caller. These ad_complain calls were outside the ad_page_contract 'validate'
#      block so they did nothing at all.
#    o any failure now generates a slightly more descriptive reason for the
#      failure.
#    o added a link to each ad_return_complaint error message that allows the user
#      to click and return to the calling page. That is, only if return_url was
#      passed in the query vars.
#    o added code to check for and display an error regarding joining a group in which
#      the user is already a member. This code simply checks for for a unique constraint
#      violation message contained in the received error message.

# Must have a valid user_id. The Unregistered User can't join groups.
ad_maybe_redirect_for_registration

db_1row group_info {}

if {![empty_string_p $return_url]} {
    set ret_link "<a href=\"$return_url\">Return to previous page.</a>"
} else {
    set ret_link ""
}

if {[string equal $join_policy closed]} {
    ad_complain "[_ acs-subsite.lt_Cannot_join_this_grou] $ret_link"
}

set export_var_list [list group_id rel_type return_url]

set party_id [ad_conn user_id]

set context [list "[_ acs-subsite.Join_group_name]"]

template::form create join

relation_required_segments_multirow \
        -datasource_name required_segments \
        -group_id $group_id \
        -rel_type $rel_type


set num_required_segments [template::multirow size required_segments]

if {[template::form is_request join]} {

    for {set rownum 1} {$rownum <= $num_required_segments } {incr rownum} {
        set required_seg [template::multirow get required_segments $rownum]
        
        if { [string equal $required_segments(join_policy) closed] && ![group::member_p -group_id $required_segments(group_id)] } {
            ad_return_complaint 1 "Cannot join this group - segment closed to all applicants. $ret_link"
            return
        }
    
        set segment_id $required_segments(segment_id)
        set cur_group_id $required_segments(group_id)
        set cur_rel_type $required_segments(rel_type)

        attribute::add_form_elements -form_id join -variable_prefix seg_$segment_id -start_with relationship -object_type $cur_rel_type

    }
}  

attribute::add_form_elements -form_id join -start_with relationship -object_type $rel_type

if { [template::form::size join] == 0 } {
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

if { $just_do_it_p || [template::form is_valid join] } {

    db_transaction {
        for {set rownum 1} {$rownum <= $num_required_segments } {incr rownum} {
            set required_seg [template::multirow get required_segments $rownum]
            
            if { ![group::member_p -group_id $required_segments(group_id)] } {
                if { [string equal $required_segments(join_policy) closed] } {
                    ad_return_complaint 1 "[_ acs-subsite.lt_Cannot_join_this_grou]"
                    return
                }
                
                if {[string equal $required_segments(join_policy) "needs approval"]} {
                    set member_state "needs approval"
                } else {
                    set member_state "approved"
                }

                set segment_id $required_segments(segment_id)
                set cur_group_id $required_segments(group_id)
                set cur_rel_type $required_segments(rel_type)
                
                set rel_id [relation_add -form_id join -variable_prefix seg_$segment_id -member_state $member_state $cur_rel_type $cur_group_id $party_id]
            }
        }
    
        if { [permission::permission_p -object_id $group_id -privilege "admin"] } {
            set member_state "approved"
            if { [string equal $rel_type "membership_rel"] } {
                # If they already have admin, bump them to an admin_rel
                set rel_type "admin_rel"
            }
        } else {
            if { [string equal $join_policy "needs approval"]  } {
                set member_state "needs approval"
            } else {
                set member_state "approved"
            }
        }

        set rel_id [relation_add -form_id join -member_state $member_state $rel_type $group_id $party_id]

    } on_error {
        set err {}
        regexp {\n\nERROR:\s\s(\S.*?)\n.*?\nSQL:\s\n\n\t.*?(\S.*?)\n.*} $errmsg junk err sql
        if {[regexp {duplicate.*?unique} $err]} {
            set reason "Your application for membership to this group has been previously accepted. "
            append reason "It is possible that your application is still awaiting approval. $ret_link"
        } else {
            set reason "An error was encountered while attempting to add you to this group. "
            append reason "<pre>$errmsg</pre> $ret_link"
        }
        ad_return_complaint 1 $reason
        ad_script_abort
    }

    ad_returnredirect $return_url
    ad_script_abort
}
