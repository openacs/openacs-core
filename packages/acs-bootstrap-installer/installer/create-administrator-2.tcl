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

    # Changed this from db_dml to db_exec_plsql (ben - OpenACS)
    # why was this a DML? Thanks to Oracle-only, this didn't make a
    # difference, but it broke our DB API. This new version is correct.
    db_exec_plsql grant_admin {
      begin
        acs_permission.grant_permission (
          object_id => acs.magic_object_id('security_context_root'),
          grantee_id => :user_id,
          privilege => 'admin'
        );
      end;
    }
  }
}
    
ns_returnredirect "site-info?[ad_export_vars email]"
