
if { ![string match  "your-ip-here" [ns_conn peeraddr]] } {
    ns_return 200 text/html "Forbidden"
    return
}


sec_login_handler

set session_id {}
catch { set session_id [ad_get_signed_cookie_with_expr "ad_session_id"] }

set ad_user_login {}
catch { set ad_user_login [ad_get_signed_cookie "ad_user_login"] }

set ad_user_login_secure {}
catch { set ad_user_login_secure [ad_get_signed_cookie "ad_user_login_secure"] }

set ad_secure_token {}
catch { set ad_secure_token [ad_get_signed_cookie "ad_secure_token"] }

set auth_expires_in "N/A"

catch {
    set login_list [split [ad_get_signed_cookie "ad_user_login"] ","]
    set login_expr [lindex $login_list 1]
    set auth_expires_in [expr [sec_login_timeout] - ([ns_time] - $login_expr)]
}


ns_return 200 text/html "<html><body>

<h1>Debug Page For Security Cookies</h1>

<h2>Cookies</h2>

<p> session_id: <code>$session_id</code> </p>

<p> ad_user_login: <code>$ad_user_login</code> </p>

<p> ad_user_login_secure: <code>$ad_user_login_secure</code> </p>

<p> ad_secure_token: <code>$ad_secure_token</code> </p>

<p> Cookie HTTP header: <code>[ns_set iget [ad_conn headers] Cookie]</code></p>

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

