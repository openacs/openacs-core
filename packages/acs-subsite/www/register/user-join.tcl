# /packages/acs-subsite/www/admin/relations/add.tcl

ad_page_contract {
    Add the user to the subsite application group.

    @author oumi@arsdigita.com
    @author Randy O'Meara <omeara@got.net>

    @creation-date 2000-2-28
    @cvs-id $Id$
} {
    {group_id:naturalnum,notnull {[application_group::group_id_from_package_id]}}
    {rel_type:notnull "membership_rel"}
    {return_url {}}
} -properties {
    context:onevalue
    role_pretty_name:onevalue
    group_name:onevalue
    export_form_vars:onevalue
} -validate {
    rel_type_valid_p {
        if { ![relation_type_is_valid_to_group_p -group_id $group_id $rel_type] } {
            ad_complain "[_ acs-subsite.lt_Cannot_join_this_grou]"
        }
    }
}

set user_id [auth::require_login]

group::get -group_id $group_id -array group_info

# Need these as local vars for some of the message keys below
set group_name $group_info(group_name)
set join_policy $group_info(join_policy)


if { $return_url ne "" } {
    set ret_link [subst {<a href="[ns_quotehtml $return_url]">Return to previous page.</a>}]
} else {
    set ret_link ""
}

if {$join_policy eq "closed"} {
    ad_return_error [_ acs-subsite.Closed_group] "[_ acs-subsite.This_group_is_closed]<p>$ret_link"
    ad_script_abort
}

set context [list "[_ acs-subsite.Join_group_name]"]

#----------------------------------------------------------------------
# Build up a form asking for relevant attributes
#----------------------------------------------------------------------

template::form create join

relation_required_segments_multirow \
-datasource_name required_segments \
        -group_id $group_id \
        -rel_type $rel_type

set num_required_segments [multirow size required_segments]
if { [form is_request join] } {
    for { set rownum 1 } { $rownum <= $num_required_segments } { incr rownum } {
        set required_seg [multirow get required_segments $rownum]
        if { ![group::member_p -group_id $required_segments(group_id)] } {

            if {$required_segments(join_policy) eq "closed"} {
                ad_return_error [_ acs-subsite.Closed_group] "[_ acs-subsite.This_group_is_closed]<p>$ret_link"
                ad_script_abort
            }
            # we need to add a rel_id element for the relation to
            # create because add_form_elements only adds elements for
            # attributes and id_column is not an attribute
            element create join seg_$required_segments(segment_id).rel_id \
                -widget hidden \
                -optional
            # add any additional attributes we want to capture when a
            # user joins
            attribute::add_form_elements \
                -form_id join \
                -variable_prefix seg_$required_segments(segment_id) \
                -start_with relationship \
                -object_type $required_segments(rel_type)
        }
    }
}

# don't show the form if all elements are hidden
set not_hidden 0

attribute::add_form_elements \
    -form_id join \
    -start_with relationship \
    -object_type $rel_type

if { [form size join] > 0 } {
    foreach var { group_id rel_type return_url } {
        template::element create join $var \
            -value [set $var] \
            -datatype text \
            -widget hidden
    }
    foreach elm [form get_elements join] {
        if {[element get_property join $elm widget] ne "hidden"} {
            incr not_hidden
        }
    }
}

# Empty form means nothing to ask for, don't have to submit first
if { $not_hidden == 0 || [template::form is_valid join] } {

    db_transaction {
        
        #----------------------------------------------------------------------
        # Join all required segments
        #----------------------------------------------------------------------

        for { set rownum 1 } { $rownum <= $num_required_segments } { incr rownum } {
            set required_seg [template::multirow get required_segments $rownum]
            
            if { ![group::member_p -group_id $required_segments(group_id)] } {
                switch $required_segments(join_policy) {
                    "needs approval" {
                        set member_state "needs approval"
                    }
                    "open" {
                        set member_state "approved"
                        set return_url [ad_conn package_url]
                    }
                    default {
                        # Should have been caught above
                        ad_return_error [_ acs-subsite.Closed_group] "[_ acs-subsite.This_group_is_closed]<p>$ret_link"
                        ad_script_abort
                    }
                }

                set rel_id [relation_add \
                                -form_id join \
                                -variable_prefix seg_$required_segments(segment_id) \
                                -member_state $member_state \
                                $required_segments(rel_type) \
                                $required_segments(group_id) \
                                $user_id]
            }
        }
        
        #----------------------------------------------------------------------
        # Join the actual group
        #----------------------------------------------------------------------

        if { [permission::permission_p -object_id $group_id -privilege "admin"] } {
            set member_state "approved"
            if {$rel_type eq "membership_rel"} {
                # If they already have admin, bump them to an admin_rel
                set rel_type "admin_rel"
            }
        } else {
            if {$join_policy eq "needs approval"} {
                set member_state "needs approval"
            } else {
                set member_state "approved"
            }
        }

        group::add_member \
            -group_id $group_id \
            -user_id $user_id \
            -rel_type $rel_type \
            -member_state $member_state

    } on_error {
        global errorInfo
        ns_log Error "user-join: Error when adding user to group: $errmsg\n$errorInfo"
        
        ad_return_error "Error Joining" "We experienced an error adding you to the group."
        ad_script_abort
    }
    
    switch $member_state {
        "approved" { set message "You have joined the group \"$group_name\"." }
        "needs approval" { set message "Your request to join group \"$group_name\" has been submitted." }
    }


    ad_returnredirect -message $message $return_url
    ad_script_abort
}
