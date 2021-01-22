ns_log notice "CSP violation: [ns_conn content] user-agent: [ns_set iget [ns_conn headers] user-agent] user_id [ad_conn user_id] peer [ad_conn peeraddr]"
ns_return 200 text/plain ok
