# NOTE:
# Comment out below two lines to use this page
#
ns_return 200 text/html "Forbidden"
return


sec_login_handler

set session_id {}
catch { set session_id [ad_get_signed_cookie_with_expr "ad_session_id"] } session_id

set ad_user_login {}
catch { set ad_user_login [ad_get_signed_cookie "ad_user_login"] } ad_user_login

set ad_user_login_secure {}
catch { set ad_user_login_secure [ad_get_signed_cookie "ad_user_login_secure"] } ad_user_login_secure

set ad_secure_token {}
catch { set ad_secure_token [ad_get_signed_cookie "ad_secure_token"] } ad_secure_token

set auth_expires_in "N/A"

catch {
    set login_list [split [ad_get_signed_cookie "ad_user_login"] ","]
    set login_expr [lindex $login_list 1]
    set auth_expires_in [expr [sec_login_timeout] - ([ns_time] - $login_expr)]
}


set page "<html><body>

<h1>Debug Page For Security Cookies</h1>

<h2>Cookies</h2>

<table border=1>
<tr><th>Cookie name</th><th>Value</th><th>Explanation</th></tr>
<tr><td>session_id<td><code>$session_id</code><td>session_id, user_id, login_level expiration</tr>
<tr><td>ad_user_login<td><code>$ad_user_login</code><td>user_id, issue_time, auth_token</tr>
<tr><td>ad_user_login_secure<td><code>$ad_user_login_secure</code><td>...</tr>
<tr><td>ad_secure_token<td><code>$ad_secure_token</code><td>...</tr>
</table>

<p> Cookie HTTP header: </p> <pre>"

foreach elm [split [ns_set iget [ad_conn headers] Cookie] ";"] {
    append page [string trim $elm] ";" \n
}

append page "
<h2>ad_conn</h2>

<p> user_id: <code>[ad_conn user_id]</code> </p>

<p> untrusted_user_id: <code>[ad_conn untrusted_user_id]</code> </p>

<p> auth_level: <code>[ad_conn auth_level]</code> </p>

<p> account_status: <code>[ad_conn account_status]</code> </p>

<h2>Authentication</h2>

<p> Authentication expires in: <code>$auth_expires_in</code> </p>

<p> LoginTimeout: <code>[sec_login_timeout]</code> </p>

[ad_decode [ad_conn untrusted_user_id] 0 "" "<p> auth_token: <code>[sec_get_user_auth_token [ad_conn untrusted_user_id]]</code> </p>"]

<p> <a href=change-auth-token>Change auth token</a> </p>

</body></html>"



ns_return 200 text/html $page
