ad_page_contract {
    email sending page

    @author Hiro Iwashima <iwashima@mit.edu>
    @creation-date 23 Aug 2000
    @cvs-id $Id$
} {
    email
    email_from
    subject
    message
    return_url
    {show_sent_message_p "f"}
    {sent_title "Email sent"}
    {sent_subject "Email sent"}
    {sent_message "Email was successfully sent"}
    {error_subject "Error sending email"}
    {error_message "There was an error sending email:"}
} -properties {
    sent_title:onevalue
    sent_subject:onevalue
    sent_message:onevalue
    return_url:onevalue
}

if {[catch {acs_mail_lite::send -send_immediately -to_addr $email -from_addr $email_from -subject $subject -body $message} errmsg]} {
    ad_return_error $error_subject "<p>$error_message</p>
    <div><code>[ad_quotehtml $errmsg]</code></div>"
    ad_script_abort
}

if { $show_sent_message_p ne "t" } {
    # Do not show any message. Just go to return url
    ad_returnredirect $return_url
    ad_script_abort
}
