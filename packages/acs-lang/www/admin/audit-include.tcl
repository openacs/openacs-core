set trail_counter 0

set new_message [db_string current_message { select message from lang_messages where locale = :current_locale and package_key = :package_key and message_key = :message_key } -default ""]

multirow create audit_inv creation_user_id creation_user_name creation_date old_message new_message old_new_message comment_text

db_foreach audit_inv_select {
    select a.old_message,
           p.first_names || ' ' || p.last_name as overwrite_user_name,
           a.overwrite_user,
           to_char(a.overwrite_date, 'YYYY-MM-DD HH24:MI:SS') as overwrite_date,
           a.comment_text
    from lang_messages_audit a,
         persons p
    where locale = :current_locale
    and message_key = :message_key
    and package_key = :package_key
    and a.overwrite_user = p.person_id
    order by overwrite_date desc
} {
    multirow append audit_inv \
        $overwrite_user \
        $overwrite_user_name \
        [lc_time_fmt $overwrite_date "%x %X"] \
        $old_message \
        $new_message \
        "$old_message,$new_message" \
        $comment_text
    
    set new_message $old_message

    incr trail_counter
}

if { $trail_counter > 0 } {
    set original_message $new_message
}

# invert the audit trail

multirow create audit creation_user_id creation_user_name creation_date old_message new_message old_new_message comment_text

for { set i [multirow size audit_inv] } { $i > 0 } { incr i -1 } {
    multirow get audit_inv $i

    multirow append audit \
        $audit_inv(creation_user_id) \
        $audit_inv(creation_user_name) \
        $audit_inv(creation_date) \
        $audit_inv(old_message) \
        $audit_inv(new_message) \
        $audit_inv(old_new_message) \
        $audit_inv(comment_text)
}

multirow extend audit creation_user_url

multirow foreach audit {
    set creation_user_url [acs_community_member_url -user_id $creation_user_id]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
