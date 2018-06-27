ad_page_contract {
    Merge two users accounts

    TODO: Support to merge more than two accounts at the same time

    @cvs-id $Id$
} {
    to_user_id:naturalnum,notnull
    from_user_id:naturalnum,notnull
    merge_action
} -properties {
    context:onevalue
} -validate {
    if_diff_authority {        
        set from_authority_id [acs_user::get_user_info -user_id $from_user_id -element authority_id]
        set to_authority_id [acs_user::get_user_info -user_id $to_user_id -element authority_id]
	if { $from_authority_id ne $to_authority_id } {
	    ad_complain "Merge only works for users from the same authority"
	}
    }
}


if {$merge_action eq "0"} {
    set tempid $from_user_id
    set from_user_id $to_user_id
    set to_user_id $tempid
}


set current_user_id [ad_conn user_id]
set context [list [list "./" "Merge"] "Merge"]


# information of from_user_id
set from_user [acs_user::get -user_id $from_user_id]
set from_first_names [dict get $from_user first_names]
set from_last_name   [dict get $from_user last_name]
set from_email       [dict get $from_user email]


# information of to_user_id
set to_user [acs_user::get -user_id $to_user_id]
set to_first_names [dict get $to_user first_names]
set to_last_name   [dict get $to_user last_name]
set to_email       [dict get $to_user email]


# information of user_id one
if { [acs_user::get_portrait_id -user_id $to_user_id] != 0 } {
    set to_img_src "[subsite::get_element -element url]shared/portrait-bits.tcl?user_id=$to_user_id"
} else {
    set to_img_src "/resources/acs-admin/not_available.gif"
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
