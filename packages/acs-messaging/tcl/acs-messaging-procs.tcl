ad_library {
    Utility procs for working with messages

    @author John Prevost <jmp@arsdigita.com>
    @creation-date 2000-09-01
    @cvs-id $Id$
}

ad_proc -public acs_message_p {
    {message_id}
} {
    Check if an integer is a valid OpenACS message id.
} {
    return [string equal [db_exec_plsql acs_message_p {
	begin
	    :1 := acs_message.message_p(:message_id);
	end;
    }] "t"]
}

ad_page_contract_filter acs_message_id { name value } {
    Checks whether the value (assumed to be an integer) is the id
    of an already-existing OpenACS message.
} {
    # empty is okay (handled by notnull)
    if {$value eq ""} {
        return 1
    }
    if {![acs_message_p $value]} {
        ad_complain "$name ($value) does not refer to a valid OpenACS message"
        return 0
    }
    return 1
}

ad_proc -public acs_messaging_format_as_html {
    {mime_type}
    {content}
} {
    Returns a string of HTML which appropriately renders the content
    given its mime content-type.  This function supports three content
    types, "text/plain", "text/plain; format=flowed", and "text/html"
    @param mime_type MIME content-type of content
    @param content   Text to view
} {
    if {$mime_type eq "text/plain"} {
	set result "<pre>[ad_quotehtml $content]</pre>"
    } elseif {$mime_type eq "text/plain; format=flowed"} {
	set result [ad_text_to_html -- $content]
    } elseif {$mime_type eq "text/html"} {
	set result $content
    } else {
	set result "<i>content type undecipherable</i>"
    }
    return $result
}


ad_proc -public acs_messaging_first_ancestor {
    {message_id}
} {
    Takes the message_id of an acs_message and returns
    the message_id of the first ancestor message (i.e. the message
    that originated the thread).
} {
    db_1row acs_message_first_ancestor {
	select acs_message.first_ancestor(:message_id) as ancestor_id from dual
    }

    return $ancestor_id
}

ad_proc -public acs_messaging_send {
    {-message_id:required}
    {-recipient_id:required}
    {-grouping_id ""}
    {-wait_until ""}
} {
    Schedule one message to be sent to one party.
} {
    db_dml {
        begin
            acs_message.send (
                message_id => :message_id,
                recipient_id => :recipient_id,
                grouping_id => :grouping_id,
                wait_until => :wait_until
            );
        end;
    }
}

ad_proc -public acs_messaging_send_query {
    {-message_id:required}
    {-query:required}
    {-bind ""}
} {
    Given an SQL query returning columns recipient_id, grouping_id,
    and wait_until, arrange for all to be sent for this message.

    Example:

    acs_message_send_query -message_id $new_message -query {
        select subscriber_id as recipient_id, forum_id as grouping_id,
               bboard_util.next_period(period) as wait_until
            from bboard_forum_subscribers
            where forum_id = :forum_id
    } -bind [list forum_id $forum_id]

    Assuming bboard_util.next_period(period) returns the next date at
    which a digest should be sent, the above will enter info to send
    all subscriptions for a single message.

    The bind argument, if given, must be a list, NOT an ns_set.

} {
    # Makes sure not to insert values that are already there--silent "failure"
    # because it's really a vacuous success.
    db_dml insert_messaging_by_query "
        insert into acs_messages_outgoing
            (message_id, to_address, grouping_id, wait_until)
        select :m__message_id, p.email, q.grouping_id,
               nvl(q.wait_until, SYSDATE) as wait_until
            from ($query) q, parties p
            where not exists (select 1 from acs_messages_outgoing o
                                  where o.message_id = :m__message_id
                                    and p.email = o.to_address)
              and p.party_id = q.recipient_id
    " -bind [concat $bind [list m__message_id $message_id]]
}

ad_proc -private acs_messaging_timezone_offset {
} {
    Returns a best guess of the timezone offset for the machine.
} {
    return [format "%+05d" [expr ([lindex [ns_localtime] 2] - [lindex [ns_gmtime] 2]) * 100]]
}

ad_proc -private acs_messaging_process_queue {
} {
    Process the message queue, sending any reasonable messages.
} {
    db_foreach acs_message_send {} {
        if {![catch {
            acs_mail_lite::send -send_immediately \
                -to_addr $recip_email \
                -from_addr $sender_email \
                -subject $title \
                -body $content
        } errMsg]} {
            # everything went well, dequeue
            db_dml acs_message_remove_from_queue {}
        } else {
            ns_log "Error" "acs-messaging: Error processing queue: $errMsg"
        }
    }
}
