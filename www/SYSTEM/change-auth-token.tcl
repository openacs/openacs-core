# This page changes the current user's auth token, thus causing the user's authentication to become expired
# This can be useful for testing/troubleshooting expiring logins.

sec_change_user_auth_token [ad_conn untrusted_user_id]

ad_returnredirect security-debug

