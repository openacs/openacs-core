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
}

ad_proc -public -callback acs_mail_lite::send {
    {-package_id:required}
    {-from_party_id:required}
    {-to_party_id:required}
    {-body}
    {-message_id:required}
    {-subject}
} {
}


ad_proc -public -callback IncomingEmail {
     -from:required
     -to:required
     -subject:required
     -bodies:required
     -headers:required
     -files
} {
      Interface for all packages that are interested in incoming
								      # emails

     @author Nima Mazloumi (nima.mazloumi@gmx.de)
     @creation-date 2005-07-15

     @param subject      the subject of the incoming email
     @param bodies       list of all bodies of the incoming email as
										 # content-type content pairs
     @param headers      all the headers of the email as an array
     @param from         sender email
     @param to           recepient email
     @param files        optional list of attachments with four
									 # elements: content-type encoding filename content
     @return             nothing
     @error
}

ad_proc -public -callback IncomingEmail -impl acs-mail-lite {
     -from:required
     -to:required
     -subject:required
     -bodies:required
     -headers:required
     -files
} {
     Implementation of the interface email::incoming::handle for
									     # acs-mail-lite

     @author Nima Mazloumi (nima.mazloumi@gmx.de)
     @creation-date 2005-07-15

     @param subject      the subject of the incoming email
     @param bodies       the bodies of the incoming email as
									 # content-type content pairs
     @param headers      all the headers of the email as an array
     @param from         sender email
     @param to           recepient email
     @param files        optional list of attachments with four
									 # elements: content-type encoding filename content
     @return             nothing
     @error
} {
    set to [parse_email_address -email $to]
     ns_log Debug "acs-mail-lite: To: $to"
    util_unlist [parse_bounce_address -bounce_address $to] user_id package_id signature

     # If no user_id found or signature invalid, ignore message
    if {[empty_string_p $user_id] || ![valid_signature -signature $signature -msg $body]} {
	if {[empty_string_p $user_id]} {
             ns_log Notice "acs-mail-lite: No user id $user_id found"
	} else {
             ns_log Notice "acs-mail-lite: Invalid mail signature"
	}
	if {[catch {ns_unlink $msg} errmsg]} {
             ns_log Notice "acs-mail-lite: couldn't remove message"
	}
         continue
    }

     ns_log Debug "Bounce checking: $to, $user_id"

    if { ![bouncing_user_p -user_id $user_id] } {
         ns_log Notice "acs-mail-lite: Bouncing email from user $user_id"
         # record the bounce in the database
	db_dml record_bounce {}

	if {![db_resultrows]} {
	    db_dml insert_bounce {}
	}
    }
}