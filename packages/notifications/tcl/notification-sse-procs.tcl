ad_library {

    Notifications Server Sent Events Delivery Method

    @creation-date 2024-12-19
    @author Antonio Pisano <antonio@elettrotecnica.it>
}

namespace eval notification::sse {

    #
    # Needed to update subscribers concurrently.
    #
    if {![nsv_exists ::notification::sse subscription_mutex]} {
        nsv_set ::notification::sse subscription_mutex \
            [ns_mutex create ::notification::sse_subscription]
    }

    ad_proc -private subscribe {
        subscription_id
    } {
        Subscribe the current connection channel to notifications.

        This will detach the connection channel from the thread and
        abort the script.
    } {
        set channel [ns_connchan detach]
        ns_connchan write $channel [string cat \
                                        "HTTP/1.1 200 OK\r\n" \
                                        "Cache-Control: no-cache\r\n" \
                                        "X-Accel-Buffering': no\r\n" \
                                        "Content-type: text/event-stream\r\n" \
                                        "\r\n"]
        nsv_lappend \
            ::notification::sse \
            channels-$subscription_id \
            $channel
        ad_script_abort
    }

    ad_proc -private unsubscribe {
        channel
        subscription_id
    } {
        Unsubscribe a channel from notifications.
    } {
        ns_log notice \
            notification::sse::unsubscribe \
            $subscription_id \
            $channel

        if {[nsv_get ::notification::sse channels-$subscription_id channels]} {
            ns_mutex eval [nsv_get ::notification::sse subscription_mutex] {
                set idx [lsearch -exact $channels $channel]
                nsv_set ::notification::sse channels-$subscription_id \
                    [lreplace $channels $idx $idx]
            }
        }
    }

    ad_proc -private channels {
        to_user_id
    } {
        @return list of channels
    } {
        if {![nsv_get ::notification::sse channels-$to_user_id channels]} {
            set channels [list]
        }

        return $channels
    }

    ad_proc -public send {
        from_user_id
        to_user_id
        reply_object_id
        notification_type_id
        subject
        content_text
        content_html
        file_ids
    } {
        Send the notification.
    } {
        set channels [::notification::sse::channels $to_user_id]

        if {[llength $channels] == 0} {
            #
            # Nobody listening. We are done.
            #
            return
        }

        #
        # convert relative URLs to fully qualified URLs
        #
        set content [::ad_html_qualify_links $content_html]

        #
        # We currently use the Notification web api to display SSE
        # notifications, which does not support HTML markup.
        #
        set content [::ad_html_to_text $content]


        set user_locale [::lang::user::site_wide_locale -user_id $to_user_id]
        if { $user_locale eq "" } {
            set user_locale [::lang::system::site_wide_locale]
        }

        set subject [::lang::util::localize $subject $user_locale]
        set content [::lang::util::localize $content $user_locale]

        set from_user [::acs_user::get -user_id $from_user_id]
        set from_user [dict filter $from_user key user_id first_names last_name email]

        set to_user [::acs_user::get -user_id $to_user_id]
        set to_user [dict filter $to_user key user_id first_names last_name email]

        set reply_object [::acs_object::get -object_id $reply_object_id]
        set reply_object [dict filter $reply_object key object_id title package_id object_type]

        set notification_type [ns_set array [lindex [db_list_of_ns_sets get_notif_type {
            select type_id, short_name, pretty_name, description
            from notification_types
            where type_id = :notification_type_id
        }] 0]]

        #
        # We do not expand files right now the same as other entities,
        # but we may in the future.
        #

        #
        # Serialize message as JSON
        #
        dom createNodeCmd -jsonType NUMBER textNode jsonNumber
        dom createNodeCmd -jsonType STRING textNode jsonString

        dom createNodeCmd -jsonType NONE elementNode first_names
        dom createNodeCmd -jsonType NONE elementNode last_name
        dom createNodeCmd -jsonType NONE elementNode user_id
        dom createNodeCmd -jsonType NONE elementNode email

        dom createNodeCmd -jsonType NONE elementNode object_id
        dom createNodeCmd -jsonType NONE elementNode title
        dom createNodeCmd -jsonType NONE elementNode package_id
        dom createNodeCmd -jsonType NONE elementNode object_type

        dom createNodeCmd -jsonType NONE elementNode type_id
        dom createNodeCmd -jsonType NONE elementNode short_name
        dom createNodeCmd -jsonType NONE elementNode pretty_name
        dom createNodeCmd -jsonType NONE elementNode description

        dom createNodeCmd -jsonType NONE elementNode from_user
        dom createNodeCmd -jsonType NONE elementNode to_user
        dom createNodeCmd -jsonType NONE elementNode reply_object
        dom createNodeCmd -jsonType NONE elementNode notification_type

        dom createNodeCmd -jsonType NONE elementNode subject
        dom createNodeCmd -jsonType NONE elementNode content
        dom createNodeCmd -jsonType ARRAY elementNode file_ids

        set resultJSON [dom createDocumentNode]
        $resultJSON appendFromScript {
            from_user {
                user_id {
                    jsonNumber [dict get $from_user user_id]
                }
                foreach key {first_names last_name email} {
                    $key {
                        jsonString [dict get $from_user $key]
                    }
                }
            }
            to_user {
                user_id {
                    jsonNumber [dict get $to_user user_id]
                }
                foreach key {first_names last_name email} {
                    $key {
                        jsonString [dict get $to_user $key]
                    }
                }
            }
            reply_object {
                foreach key {object_id package_id} {
                    $key {
                        jsonNumber [dict get $reply_object $key]
                    }
                }
                foreach key {title object_type} {
                    $key {
                        jsonString [dict get $reply_object $key]
                    }
                }
            }
            notification_type {
                type_id {
                    jsonNumber [dict get $notification_type type_id]
                }
                foreach key {short_name pretty_name description} {
                    $key {
                        jsonString [dict get $notification_type $key]
                    }
                }
            }
            subject {
                jsonString $subject
            }
            content {
                jsonString $content
            }
            file_ids [lmap file_id $file_ids {
                jsonNumber $file_id
            }]
        }

        set message [$resultJSON asJSON]

        foreach channel $channels {
            try {
                ns_connchan write $channel [string cat "data: " $message "\n\n"]
            } on error {errmsg} {
                ::notification::sse::unsubscribe $channel $to_user_id
            }
        }

        return $message
    }

    ad_proc -private scan_replies {} {
        Scan for replies
    } {
        #
        # A noop because there is no reply with SSE.
        #
    }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
