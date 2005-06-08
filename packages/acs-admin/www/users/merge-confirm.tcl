ad_page_contract {
    Merge two users accounts

    TODO: Support to merge more than two accounts at the same time

    @cvs-id $Id$
} {
    to_user_id:integer
    from_user_id:integer
    merge_action
} -properties {
    context:onevalue
} -validate {
    if_diff_authority {
	set from_authority_id [db_string gettoa "select authority_id from cc_users where user_id = :from_user_id"]
	set to_authority_id [db_string getfroma "select authority_id from cc_users where user_id = :to_user_id"]
	if { ![string equal $from_authority_id $to_authority_id] } {
	    ad_complain "Merge only works for users from the same authority"
	}
    }
}


if { [string equal $merge_action "0"] } {
    set tempid $from_user_id
    set from_user_id $to_user_id
    set to_user_id $tempid
}


set current_user_id [ad_conn user_id]
set context [list [list "./" "Merge"] "Merge"]


# information of from_user_id
db_1row from_get_info { *SQL* }


# information of to_user_id
db_1row to_get_info { *SQL* }

# information of user_id one
if { [db_0or1row to_user_portrait { *SQL* }] } {
    set to_img_src "[subsite::get_element -element url]shared/portrait-bits.tcl?user_id=$to_user_id"
} else {
    set to_img_src "/resources/acs-admin/not_available.gif"
}