ad_page_contract {
    Toggle the 'Don't SPAM me' user preference.

    Note: this page is apparently not referenced anywhere.
}

set user_id [ad_conn user_id]
db_dml unused {}

ad_returnredirect "home"
ad_script_abort


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
