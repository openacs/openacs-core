ad_page_contract {
    Sends email confirmation to user after they've been created

    @cvs-id $Id$
} -query {
    email
    message
    first_names
    last_name
    user_id:naturalnum,notnull
    {referer "/acs-admin/users"}
} -properties {
    context:onevalue
    first_names:onevalue
    last_name:onevalue
    export_vars:onevalue
}
    
set admin_user_id [ad_conn user_id]

set context [list [list "./" "Users"] "New user notified"]
set export_vars [export_vars {user_id}]

set admin_email [db_string get_admin_email {}]
set subject "You have been added as a user to [ad_system_name] at [ad_url]"

if {[catch {acs_mail_lite::send -send_immediately -to_addr $email -from_addr $admin_email -subject $subject -body $message} errmsg]} {
    ad_return_error "Mail Failed" [subst {
	<p>The system was unable to send email.  Please notify the user personally.
	This problem is probably caused by a misconfiguration of your email system.
	Here is the error message:</p>
<div><code>
[ns_quotehtml $errmsg]
</code></div>
}]
    return
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
