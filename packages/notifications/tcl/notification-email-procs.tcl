ad_library {

    Notifications Email Delivery Method

    @creation-date 2002-06-20
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::email {

    ad_proc -public get_package_id {} {
        return [apm_package_id_from_key notifications]
    }

    ad_proc -public get_parameter {
        {-name:required}
        {-default ""}
    } {
        return [parameter::get -package_id [get_package_id] -parameter $name -default $default]
    }

    ad_proc -public address_domain {} {
        set domain [get_parameter -name "EmailDomain"]
        if { [empty_string_p $domain] } {
            # No domain set up, let's use the default from the system info
            # This may not find anything, but at least it's worth a try
            if { ![regexp {^(https?://)?(www\.)?([^/]*)} [ad_url] match ignore ignore domain] } {
                ns_log Warning "notification::email::address_domain: Couldn't find an email domain for notifications."
            }
        }
        return $domain
    }

    ad_proc -public manage_notifications_url {} {
        return "[ad_url]/[apm_package_url_from_key [notification::package_key]]manage"
    }

    ad_proc -public reply_address_prefix {} {
        return [get_parameter -name "EmailReplyAddressPrefix"]
    }

    ad_proc -private qmail_mail_queue_dir {} {
        return [get_parameter -name "EmailQmailQueue"]
    }

    ad_proc -private parse_email_address {email} {
        if {![regexp {<([^>]*)>} $email all clean_email]} {
            return $email
        } else {
            return $clean_email
        }
    }

    ad_proc -public reply_address {
        {-object_id:required}
        {-type_id:required}
    } {
        if {[empty_string_p $object_id] || [empty_string_p $type_id]} {
            return "[address_domain] mailer <[reply_address_prefix]@[address_domain]>"
        } else {
            return "[address_domain] mailer <[reply_address_prefix]-$object_id-$type_id@[address_domain]>"
        }
    }

    ad_proc -public parse_reply_address {
        {-reply_address:required}
    } {
        This takes a reply address, checks it for consistency, and returns a list of object_id and type_id
    } {
        # The pattern to match
        set regexp_str "^[reply_address_prefix]-(\[0-9\]*)-(\[0-9\]*)\@"

        # Check the format and extract type_id and object_id at the same time
        if {![regexp $regexp_str $reply_address all object_id type_id]} {
            return ""
        }

        return [list $object_id $type_id]
    }

    ad_proc -public send {
        to_user_id
        reply_object_id
        notification_type_id
        subject
        content
    } {
        Send the actual email
    } {
        # Get email
        set email [cc_email_from_party $to_user_id]

       append content "\nGetting too much email? Manage your notifications at: [manage_notifications_url]"

        acs_mail_lite::send \
            -to_addr $email \
            -from_addr [reply_address -object_id $reply_object_id -type_id $notification_type_id] \
            -subject $subject \
            -body $content
    }

    ad_proc -private load_qmail_mail_queue {
        {-queue_dir:required}
    } {
        Scans qmail incoming email queue and queues up messages
        using acs-mail.

        @author ben@openforce.net
        @author dan.wickstrom@openforce.net
        @creation-date 22 Sept, 2001

        @param queue_dir The location of the qmail mail queue in
        the file-system.
    } {
        if {[catch {
            set messages [glob "$queue_dir/new/*"]
        } errmsg]} {
            ns_log Notice "queue dir = $queue_dir/new/*, no messages"
            return [list]
        }

        set list_of_reply_ids [list]
        set new_messages_p 0

        foreach msg $messages {
            ns_log Notice "opening file: $msg"
            if [catch {set f [open $msg r]}] {
                continue
            }
            set file [read $f]
            close $f
            set file [split $file "\n"]

            set new_messages 1
            set end_of_headers_p 0
            set i 0
            set line [lindex $file $i]
            set headers [list]

            # walk through the headers and extract each one
            while ![empty_string_p $line] {
                set next_line [lindex $file [expr $i + 1]]
                if {[regexp {^[ ]*$} $next_line match] && $i > 0} {
                    set end_of_headers_p 1
                }
                if {[regexp {^([^:]+):[ ]+(.+)$} $line match name value]} {
                    # join headers that span more than one line (e.g. Received)
                    if { ![regexp {^([^:]+):[ ]+(.+)$} $next_line match] && !$end_of_headers_p} {
                append line $next_line
                incr i
                    }
                    lappend headers [string tolower $name] $value

                    if {$end_of_headers_p} {
                incr i
                break
                    }
                } else {
                    # The headers and the body are delimited by a null line as specified by RFC822
                    if {[regexp {^[ ]*$} $line match]} {
                incr i
                break
                    }
                }
                incr i
                set line [lindex $file $i]
            }
            set body "\n[join [lrange $file $i end] "\n"]"

            # okay now we have a list of headers and the body, let's
            # put it into notifications stuff
            array set email_headers $headers

            if [catch {set from $email_headers(from)}] {
                set from ""
            }
            if [catch {set to $email_headers(to)}] {
                set to ""
            }

            set from [parse_email_address $from]
            set to [parse_email_address $to]

            # Find the from user
            set from_user [cc_lookup_email_user $from]

            # We don't accept empty users for now
            if {[empty_string_p $from_user]} {
                ns_log Notice "NOTIF-INCOMING-EMAIL: no user $from"
                if {[catch {ns_unlink $msg} errmsg]} {
                    ns_log Notice "NOTIF-INCOMING-EMAIL: couldn't remove message"
                }
                continue
            }

            set to_stuff [parse_reply_address -reply_address $to]

            # We don't accept a bad incoming email address
            if {[empty_string_p $to_stuff]} {
                ns_log Notice "NOTIF-INCOMING-EMAIL: bad to address $to"
                if {[catch {ns_unlink $msg} errmsg]} {
                    ns_log Notice "NOTIF-INCOMING-EMAIL: couldn't remove message"
                }
                continue
            }

            set object_id [lindex $to_stuff 0]
            set type_id [lindex $to_stuff 1]

            db_transaction {
                set reply_id [notification::reply::new \
                        -object_id $object_id \
                        -type_id $type_id \
                        -from_user $from_user \
                        -subject $email_headers(subject) \
                        -content $body]

                catch {ns_unlink $msg}

                lappend list_of_reply_ids $reply_id
            } on_error {
                ns_log Error "Error inserting incoming email into the queue"
            }
        }

        return $list_of_reply_ids
    }

    ad_proc -public scan_replies {} {
        scan for replies
    } {
        ns_log Notice "NOTIF-EMAIL: about to load qmail queue"
        return [load_qmail_mail_queue -queue_dir [qmail_mail_queue_dir]]
    }

}
