# packages/acs-mail-lite/tcl/acs-mail-lite-callback-procs.tcl

ad_library {
    
    Callback procs for acs-mail-lite
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-15
    @arch-tag: d9aec4df-102d-4b0d-8d0e-3dc470dbe783
    @cvs-id $Id$
}

ad_proc -public -callback acs_mail_lite::send {
    -package_id:required
    -message_id:required
    -from_addr:required
    -to_addr:required
    -body:required
    {-mime_type "text/plain"}
    {-subject}
    {-cc_addr}
    {-bcc_addr}
    {-file_ids}
    {-filesystem_files}
    {-delete_filesystem_files_p}
    {-object_id}
    {-status ok}
    {-errorMsg ""}
} {

    Callback for executing code after an email has been send using the send mechanism.
    
	@param package_id Package ID of the sending package
	@param message_id the generated message_id for this mail
	@param from_addr email of the sender
	@param to_addr list of emails to whom did we send this email
	@param body Text body of the email
        @param mime_type Mime type of the email body
	@param subject of the email
	@param cc_addr list of emails to whom did we send this email in CC
	@param bcc_addr list of emails to whom did we send this email in BCC
	@param file_ids List of file ids sent as attachments.
        @param object_id The ID of the object that is responsible for sending the mail in the first place
        @param status Status of the send operation ("ok" or "error")
        @param errorMsg Error Details
} -

ad_proc -public -callback acs_mail_lite::incoming_email {
    -array:required
    -package_id
} {
    Callback that is executed for incoming e-mails if the email is *NOT* like $object_id@servername
} -

ad_proc -public -callback acs_mail_lite::incoming_object_email {
    -array:required
    -object_id:required
} {
    Callback that is executed for incoming e-mails if the email is like $object_id@servername
} - 

ad_proc -public -callback acs_mail_lite::email_form_elements {
    -varname:required
} {
} -

ad_proc -public -callback acs_mail_lite::files {
    -varname:required
    -recipient_ids:required
} {
} -

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

    # for email_queue, header info is already parsed
    if { [info exists email(aml_to_addrs)] } {
        set to $email(aml_to_addrs)
    } else {
        set to [acs_mail_lite::parse_email_address -email $email(to)]
    }
    ns_log Debug "acs_mail_lite::incoming_email -impl acs-mail-lite called. Recipient $to"

    if { ![info exists email(aml_user_id)] } {
        # Traditional call parses here. Queue case is pre-parsed.
        lassign [acs_mail_lite::parse_bounce_address -bounce_address $to] user_id package_id signature
    } else {
        set user_id $email(aml_user_id)
        set package_id $email(aml_package_id)
        # signature could come from a number of headers. Pre-parsing
        # makes signature obsolete here.
        set signature ""
    }
    # The above adaptions make this proc usable with newer versions of
    # code in the legacy paradigm.
    # Sadly, this bounces all cases with a user_id so it is not
    # usable for the new inbound email callback scheme.
    # If no user_id found or signature invalid, ignore message
    if {$user_id eq ""} {
      ns_log Debug "acs_mail_lite::incoming_email impl acs-mail-lite: No equivalent user found for $to"
    } else {
        ns_log Debug "acs_mail_lite::incoming_email impl acs-mail-lite: Bounce checking $to, $user_id"
        acs_mail_lite::record_bounce -user_id $user_id
    }
}

ad_proc -public -callback acs_mail_lite::email_inbound {
    -headers_array_name:required
    -parts_array_name:required
    {-package_id ""}
    {-object_id ""}
    {-party_id ""}
    {-other ""}
    {-datetime_cs ""}
} {
    Callback that is executed for inbound e-mails that are queued.
    package_id, object_id, party_id, other, and datetime_cs are populated 
    only when information provided via a signed unique_id via
    acs_mail_lite::unique_id_create
} -


ad_proc -public -callback acs_mail_lite::email_inbound -impl acs-mail-lite {
    -headers_array_name:required
    -parts_array_name:required
    {-package_id ""}
    {-object_id ""}
    {-party_id ""}
    {-other ""}
    {-datetime_cs ""}
} {
    Example Implementation of acs_mail_lite::email_inbound.
    This is where documentation for callback goes.

    @creation-date 2017-10-17

    @param headers_array_name  An array with all email headers.
    @param parts_array_name   An array with info on files and bodies. 
    @see acs_mail_lite::inbound_queue_pull_one

    @param package_id   The package_id of package that sent the original email.
    @param object_id
    @param party_id
    @param other
    @param datetime_cs

    Not all inbound email are expected to be replies.
} {
    upvar $headers_array_name headers_arr
    upvar $parts_array_name parts_arr
    set no_errors_p 1
    # ------------------- Do Not change code above this line in your copy ---
    # Use this callback implementation as a template for other packages.
    # Be sure to change 'impl acs-mail-lite' to a reference relevant to 
    # package implementation is used in. 
    # For example: -impl super-package-now-with-email
    #
    # This proc is called whenever an inbound email is pulled from the queue.
    #
    # System-wide bounces, vacation notices and other noise have already been
    # filtered out.
    #
    # A package developer should just need to confirm input for their specific
    # package. 
    #
    # When supplied, package_id, object_id and party_id, other and datetime_cs
    # are passed in headers via a signed unique_id. 
    # Values default to empty string. 

    # headers_arr is an array of header values indexed by header name.
    # header names are in original upper and lower case, which may
    # have some significance in filtering cases. Although case should
    # should not be relied on for obtaining a value.
    # Some header indexes are created by ACS Mail Lite procs during 
    # processing. For example these indexes may be populated via
    # a unique id header created using acs_mail_lite::unique_id_create :
    #
    # aml_package_id contains package_id
    # 
    # aml_object_id contains object_id
    # 
    # aml_party_id contains party_id (usually same as user_id) 
    # 
    # aml_other contains other data useful as input
    # 
    # aml_datetime_cs contains approx time in seconds since epoch when sent.
    #
    #
    # Other header names, and a description of their values, includes:
    #
    # aml_received_cs approx time in seconds since epoch when email received.
    # aml_subject     contains subject value.
    # aml_to          contents of 'to' header
    # aml_to_addrs    email address of 'to' header
    # aml_from        contents of 'from' header
    # aml_from_addrs  email address of 'from' header

    # For other created headers, see: acs_mail_lite::inbound_queue_pull_one
    # Header indexes may not exist for all cases.
    #

    # parts_arr  is an array that contains all the information about attached
    # or inline files and body contents. 
    # For details, see acs_mail_lite::inbound_queue_pull_one
    #

    ns_log Debug "acs_mail_lite::email_inbound -impl acs-mail-lite called. Sender $headers_arr(aml_from_addrs)"

    # Important: If your implementation has an error,
    # set no_errors_p to 0, so that the email remains
    # in the queue for later examination, even though it is also
    # marked as 'processed' so it will not be re-processed later.
    # 

    # ------------------- Do Not change code below this line in your copy ---
    return $no_errors_p
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
