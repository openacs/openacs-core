set trail_counter 0
multirow create audit_trail message creation_user creation_date
db_foreach audit_trail_select {
    select a.message,
           p.first_names || ' ' || p.last_name as overwrite_user,
           to_char(a.overwrite_date, 'YYYY-MM-DD HH24:MI:SS') as overwrite_date
    from lang_messages_audit a,
         persons p
    where locale = :current_locale
    and message_key = :message_key
    and package_key = :package_key
    and a.overwrite_user = p.person_id
    order by overwrite_date desc
} {

    if { [string equal $trail_counter 0] } {
        set current_message_author $overwrite_user
        set current_message_date $overwrite_date

    } else {
        multirow append audit_trail $previous_message $overwrite_user $overwrite_date
    }

    set previous_message $message
    set previous_overwrite_user $overwrite_user
    set previous_overwrite_date $overwrite_date
    incr trail_counter
}

if { $trail_counter > 0 } {
    set original_message $previous_message
}
