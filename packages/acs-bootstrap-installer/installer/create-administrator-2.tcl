ad_page_contract {

    Creates the site-wide administrator.
    @author Jon Salz (jsalz@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$

} {
    email:notnull
    first_names:notnull
    last_name:notnull
    password:notnull
    password_confirmation:notnull
    password_question:notnull
    password_answer:notnull
}

if { [string compare $password $password_confirmation] } {
    install_return 200 "Passwords Don't Match" "
The passwords you've entered don't match. Please <a href=\"javascript:history.back()\">try again</a>.
"
    return
}

if { ![db_string user_exists {
    select count(*) from parties where email = lower(:email)
}] } {

  db_transaction {
    
    set user_id [ad_user_new $email $first_names $last_name $password $password_question $password_answer]
    if { !$user_id } {

	global errorInfo    
	install_return 200 "Unable to Create Administrator" "
    
Unable to create the site-wide administrator:
   
<blockquote><pre>[ns_quotehtml $errorInfo]</pre></blockquote>
    
Please <a href=\"javascript:history.back()\">try again</a>.
    
"
        return
    }

    # stub util_memoize_flush...
    rename util_memoize_flush util_memoize_flush_saved
    proc util_memoize_flush {args} {}
    permission::grant -party_id $user_id -object_id [acs_lookup_magic_object security_context_root] -privilege "admin"
    # nuke stub 
    rename util_memoize_flush {}
    rename util_memoize_flush_saved util_memoize_flush

  }
}
    
ad_returnredirect "site-info?[ad_export_vars email]"
