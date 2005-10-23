# packages/acs-mail-lite/tcl/acs-mail-lite-callback-procs.tcl

ad_library {
    
    Callback procs for acs-mail-lite
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-15
    @arch-tag: d9aec4df-102d-4b0d-8d0e-3dc470dbe783
    @cvs-id $Id$
}

ad_proc -public -callback acs_mail_lite::complex_send {
    {-package_id:required}
    {-from_party_id:required}
    {-to_party_id:required}
    {-body}
    {-message_id:required}
    {-subject}
    {-object_id}
    {-file_ids}
} {

    Callback for executing code after an email has been send using the complex send mechanism.
   
    	@param from_party_id Who is sending the email
	
	@param to_party_id to whom did we send this email

	@param subject of the email
	
	@param body Text body of the email
	
	@param package_id Package ID of the sending package
	
	@param file_ids List of file ids to be send as attachments. This will only work with files stored in the file system. The list is actually a string with the ids concated with a ",". 

	@param object_id The ID of the object that is responsible for sending the mail in the first place

	@param message_id the generated message_id for this mail

} -

ad_proc -public -callback acs_mail_lite::send {
    {-package_id:required}
    {-from_party_id:required}
    {-to_party_id:required}
    {-body}
    {-message_id:required}
    {-subject}
} {
}

ad_proc -public -callback acs_mail_lite::incoming_email {
    -array:required
    -package_id
} {
}

ad_proc -public -callback acs_mail_lite::email_form_elements {
    -varname:required
} {
}

ad_proc -public -callback acs_mail_lite::files {
    -varname:required
    -recipient_ids:required
} {
}

ad_proc -public -callback acs_mail_lite::incoming_email -impl acs-mail-lite {
    -array:required
    -package_id:required
} {
    Implementation of the interface acs_mail_lite::incoming_email for acs-mail-lite. This proc
    takes care of emails bounced back from mailer deamons. The required syntax for the To header
    is as follows: EnvelopPrefix-user_id-signature-package_id@myhost.com. This email was set for
    the Return-Path header of the original email. The signature is created by calculating the SHA
    value of the original Message-Id header. Thus an email is valid if the signature is correct and
    the user is known. If this is the case we record the bounce.

    @author Nima Mazloumi (nima.mazloumi@gmx.de)
    @creation-date 2005-07-15

    @param array        An array with all headers, files and bodies. To access the array you need to use upvar.
    @param package_id   The package instance that registered the prefix
    @return             nothing
    @error
} {
    upvar $array email

    set to [acs_mail_lite::parse_email_address -email $email(to)]
    ns_log Notice "acs_mail_lite::incoming_email -impl acs-mail-lite called. Recepient $to"

    util_unlist [acs_mail_lite::parse_bounce_address -bounce_address $to] user_id package_id signature
    
    # If no user_id found or signature invalid, ignore message
    if {[empty_string_p $user_id] || ![acs_mail_lite::valid_signature -signature $signature -message_id $email(message-id)]} {
        if {[empty_string_p $user_id]} {
            ns_log Notice "acs_mail_lite::incoming_email impl acs-mail-lite: No equivalent user found for $to"
        } else {
            ns_log Notice "acs_mail_lite::incoming_email impl acs-mail-lite: Invalid mail signature $signature"
        }
    } else {
	ns_log Notice "acs_mail_lite::incoming_email impl acs-mail-lite: Bounce checking $to, $user_id"
	
	if { ![acs_mail_lite::bouncing_user_p -user_id $user_id] } {
	    ns_log Notice "acs_mail_lite::incoming_email impl acs-mail-lite: Bouncing email from user $user_id"
	    # record the bounce in the database
	    db_dml record_bounce {}
	    
	    if {![db_resultrows]} {
		db_dml insert_bounce {}
	    }
	}
    }
}

ad_proc -public -callback subsite::parameter_changed -impl acs-mail-lite {
        -package_id:required
        -parameter:required
        -value:required
} {
    Implementation of subsite::parameter_changed for acs-mail-lite.
    All packages that implement the callback acs_mail_lite::incoming_email require to provide
    a package parameter called EnvelopePrefix. As soon as a site admin sets this parameter
    this callback here is called to put that information in the mapping table acs_mail_lite_reply_tokens.
    This table allows acs-mail-lite to inform the implementation directly.
    
    In order to allow packages listening to mails sent out by notifications we also listen to the parameter
    ProcessNotificationRepliesP.
    
    @author Nima Mazloumi (nima.mazloumi@gmx.de)
    @creation-date 2005-08-17
    
    @param package_id the package_id of the package the parameter was changed for
    @param parameter  the parameter name
    @param value      the new value
    
} {
    ns_log Debug "subsite::parameter_changed -impl acs-mail-lite called for $parameter"

    set empty_p [empty_string_p $value]

    set package_key [apm_package_key_from_id $package_id]

    if {0} {
#    if {[string equal "EnvelopePrefix" $parameter] || [string equal "EmailReplyAddressPrefix" $parameter]} {
	if {[db_0or1row entry_exists {}]} {
	    if { $empty_p } {
		ns_log Notice "subsite::parameter_changed -impl acs-mail-lite prefix: removing prefix $prefix"
		db_dml remove_entry {}
	    } else {
		ns_log Notice "subsite::parameter_changed -impl acs-mail-lite prefix: changing prefix $prefix to $value"
		db_dml update_entry {}
	    }
	} else {
	    if {!$empty_p} {
		ns_log Notice "subsite::parameter_changed -impl acs-mail-lite prefix: creating new prefix $value for package_id $package_id"
		db_dml insert_entry {}
	    }
	}
    } else {
	ns_log Debug "subsite::parameter_changed -impl acs-mail-lite don't care about $parameter"
    }
}
