ad_page_contract { 
    redirect to the specified tip
} { 
    tip:integer,notnull
}

set msgid [db_string get "select message_id from forums_messages where forum_id = 115570 and parent_id is null and subject ~ '^\[^0-9\]*$tip\[^0-9\]'" -default {}]

if {![empty_string_p $msgid]} { 
    ad_returnredirect "http://openacs.org/forums/message-view?message_id=$msgid"
} else { 
    ns_returnnotfound
}
