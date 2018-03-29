
set user_id [ad_conn user_id]
db_dml unused "update user_preferences set dont_spam_me_p = util.logical_negation(dont_spam_me_p) where user_id = :user_id"

ad_returnredirect "home"
ad_script_abort


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
