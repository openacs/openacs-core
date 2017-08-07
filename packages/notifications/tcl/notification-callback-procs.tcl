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
    set user_notifications [db_list_of_lists user_notification {}]
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
	db_dml upd_notifications {}
	db_dml upd_map {}
	lappend result "Notifications merge is done"
    } 
    return $result
}

ad_proc -public -callback acs_mail_lite::incoming_email -impl notifications {
    -array:required
    -package_id
} {
    Implementation of the interface acs_mail_lite::incoming_email for notifications. Notification
    listens to replies sent out initially from notifications. According to the notification signature
    <EmailReplyAddressPrefix>-$object_id-$type_id@<EmailDomain> it tries to figure out for which notification
    type the email was from. The type corresponds to the service contract implementation. If the object_id
    exists notification creates an entry in the table notification_email_hold and tries to inform implementations
    of acs_mail_lite::incoming_email interested. Since the service contract NotificationType is implemented
    only once for a package the table acs_mail_lite_reply_prefixes is used simply figure out which package corresponds
    to the found type_id and has a valid package key. If a package key is found the callback implementation is
    called.

    @author Nima Mazloumi (nima.mazloumi@gmx.de)
    @creation-date 2005-07-15

    @param array        An array with all headers, files and bodies. To access the array you need to use upvar.
    @param package_id   The package instance that registered the prefix
    @return             nothing
    @error
} {
    upvar $array email

    set is_auto_reply_p 0
    
    #TODO: we need to check if it Auto-Submitted header exists or "Out of Office AutoReply" in Subject
    
    if { $is_auto_reply_p } {
	ns_log Notice "acs_mail_lite::incoming_email -impl notifications: message $email(message-id) is from an auto-responder, skipping"
    }

    set from [notification::email::parse_email_address $email(from)]
    set to [notification::email::parse_email_address $email(to)]
    
    set to_stuff [notification::email::parse_reply_address -reply_address $to]
    # We don't accept a bad incoming email address
    if {$to_stuff eq ""} {
	# This is not an e-mail notification can work with. Maybe bounce ?
	return
    }

    # Find the user_id of the sender
    ns_log Notice "acs_mail_lite::incoming_email -impl notifications: from $from"
    set user_id [party::get_by_email -email $from]
    
    # We don't accept empty users for now
    if {$user_id eq ""} {
	ns_log Notice "acs_mail_lite::incoming_email -impl notifications: Unknown sender with email $from. Bouncing message."
	# bounce message with an informative error.
	notification::email::bounce_mail_message \
	    -to_addr $from \
	    -from_addr $to \
	    -body $email(bodies)  \
	    -message_headers $email(headers) \
	    -reason "Invalid sender.  You must be a member of the site and\nyour From address must match your registered address."
	return
    }
    
    set object_id [lindex $to_stuff 0]
    set type_id [lindex $to_stuff 1]
    set to_addr $to
    set headers $email(headers)
    set bodies $email(bodies)

    db_transaction {
	ns_log Notice "acs_mail_lite::incoming_email -impl notifications: Creating a reply for user: $user_id, object: object_id: $object_id, type_id: $type_id."
	set reply_id [notification::reply::new \
			  -object_id $object_id \
			  -type_id $type_id \
			  -from_user $user_id \
			  -subject $email(subject) \
			  -content $email(bodies)]
	db_dml holdinsert {}
	
	#extending email array for notification callback implementors
	set email(object_id) $object_id
	set email(type_id) $type_id
	set email(reply_id) $reply_id
	set email(user_id) $user_id
	
	if {[db_0or1row select_impl {}]} {
	ns_log Notice "acs_mail_lite::incoming_email -impl notifications: calling notifications::incoming_email implementation for package $package_key"
	    if { [catch {callback -impl $package_key notifications::incoming_email -array email} error] } {
		ns_log Notice "acs_mail_lite::incoming_email -impl notifications: $error"
	    }
	} else {
	    ns_log Notice "acs_mail_lite::incoming_email -impl notifications: No corresponding package registered for type_id $type_id"
	}
	
    } on_error {
	ns_log Error "acs_mail_lite::incoming_email -impl notifications: error inserting incoming email into the queue: $errmsg"
    }
}

ad_proc -public -callback notifications::incoming_email {
    -array:required
} {
} -

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
