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

    set to [acs_mail_lite::parse_email_address -email $email(to)]
    ns_log Debug "acs_mail_lite::incoming_email -impl acs-mail-lite called. Recipient $to"

    lassign [acs_mail_lite::parse_bounce_address -bounce_address $to] user_id package_id signature
    
    # If no user_id found or signature invalid, ignore message
    if {$user_id eq ""} {
      ns_log Debug "acs_mail_lite::incoming_email impl acs-mail-lite: No equivalent user found for $to"
    } else {
        ns_log Debug "acs_mail_lite::incoming_email impl acs-mail-lite: Bounce checking $to, $user_id"
        acs_mail_lite::record_bounce -user_id $user_id
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
