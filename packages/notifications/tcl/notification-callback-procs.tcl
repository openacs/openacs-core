ad_library {

    Library for Notification's callback implementations

    @creation-date July 19, 2005
    @author Enrique Catalan <quio@galileo.edu>
    @cvs-id $Id$
}

ad_proc -callback merge::MergeShowUserInfo -impl notifications {
    -user_id:required
} {
    Show the notifications of user_id
} {
    set result [list "Notifications of $user_id"]
    set user_notifications [db_list_of_lists user_notification { *SQL* }]
    lappend result $user_notifications
    return $result
}

ad_proc -callback merge::MergePackageUser -impl notifications {
    -from_user_id:required
    -to_user_id:required
} {
    Merge the notifications of two users.
} {
    set msg "Merging notifications"
    set result [list $msg]
    ns_log Notice $msg
    
    db_transaction {
	db_dml upd_notifications { *SQL* }
	db_dml upd_map { *SQL* }
	lappend result "Notifications merge is done"
    } 
    return $result
}

