ad_page_contract {
    Page responsible for collecting CSP complaints for the browser and
    putting them in the log file.
}

ns_log notice "CSP violation: [ns_conn content] user-agent: [ns_set iget [ns_conn headers] user-agent] user_id [ad_conn user_id] peer [ad_conn peeraddr]"
ns_return 200 text/plain ok

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
