ad_library {

    Provides a simple API for reliably sending email.

    @author Eric Lorenzo (eric@openforce.net)
    @creation-date 22 March 2002
    @cvs-id $Id$

}

package require mime 1.4
package require smtp 1.4
package require base64 2.3.1

namespace eval acs_mail_lite {

    #---------------------------------------
    ad_proc -private bounce_prefix {} {
        @return bounce prefix for x-envelope-from
    } {
        return [parameter::get_from_package_key -package_key "acs-mail-lite" -parameter "EnvelopePrefix"]
    }

    #---------------------------------------
    ad_proc -public bouncing_email_p {
        -email:required
    } {
        Checks if email address is bouncing mail
        @option email email address to be checked for bouncing
        @return boolean 1 if bouncing 0 if ok.
    } {
        return [db_string bouncing_p {} -default 0]
    }

    #---------------------------------------
    ad_proc -public bouncing_user_p {
        -user_id:required
    } {
        Checks if email address of user is bouncing mail
        @option user_id user to be checked for bouncing
        @return boolean 1 if bouncing 0 if ok.
    } {
        return [db_string bouncing_p {} -default 0]
    }

    #---------------------------------------
    ad_proc -public bounce_address {
        -user_id:required
        -package_id:required
        -message_id:required
    } {
        Composes a bounce address. If parameter FixedSenderEmail empty,
        message_id is used. If message_id is empty, the legacy approach
        for creating bounce_address is used.

        @option user_id user_id of the mail recipient
        @option package_id package_id of the mail sending package
        (needed to call package-specific code to deal with bounces)
        @option message_id message-id of the mail
        @return bounce address
    } {
        set mail_package_id [apm_package_id_from_key "acs-mail-lite"]
        set fixed_sender [parameter::get -parameter "FixedSenderEmail" \
                              -package_id $mail_package_id \
                              -default "" ]
        if { $fixed_sender ne "" } {
            set ba $fixed_sender
        } else {
            if { $message_id ne "" } {
                set ba $message_id
            } else {
                set ba [bounce_prefix]
                append ba "-" $user_id "-" [ns_sha1 $message_id] \
                    "-" $package_id "@" [address_domain]
                ns_log Warning "acs_mail_lite::bounce_address is using \
 deprecated way. Supply message_id. Use acs_mail_lite::unique_id_create"
            }
        }
        return $ba
    }

    #---------------------------------------
    ad_proc -public -deprecated parse_bounce_address {
        -bounce_address:required
    } {
        This takes a reply address, checks it for consistency,
        and returns a list of user_id, package_id and bounce_signature found
        @option bounce_address bounce address to be checked
        @return tcl-list of user_id package_id bounce_signature

        @See acs_mail_lite::inbound_email_context
    } {
        set regexp_str "\[[bounce_prefix]\]-(\[0-9\]+)-(\[^-\]+)-(\[0-9\]*)\@"
        if {![regexp $regexp_str $bounce_address all user_id signature package_id]} {
            ns_log Debug "acs-mail-lite: bounce address not found for $bounce_address"
            return ""
        }
        return [list $user_id $package_id $signature]
    }

    #---------------------------------------
    ad_proc -public scan_replies {} {
        Scheduled procedure that will scan for bounced mails
    } {
        # Make sure that only one thread is processing the queue at a time.
        if {[nsv_incr acs_mail_lite check_bounce_p] > 1} {
            nsv_incr acs_mail_lite check_bounce_p -1
            return
        }

        ad_try  {
            ns_log Debug "acs-mail-lite: about to load qmail queue for [mail_dir]"
            load_mails -queue_dir [mail_dir]
        } finally {
            nsv_incr acs_mail_lite check_bounce_p -1
        }
    }

    #---------------------------------------
    ad_proc -private check_bounces {} {
        Daily proc that sends out warning mail that emails
        are bouncing and disables emails if necessary
    } {
        set package_id [apm_package_id_from_key "acs-mail-lite"]
        set max_bounce_count [parameter::get -package_id $package_id -parameter MaxBounceCount -default 10]
        set max_days_to_bounce [parameter::get -package_id $package_id -parameter MaxDaysToBounce -default 3]
        set notification_interval [parameter::get -package_id $package_id -parameter NotificationInterval -default 7]
        set max_notification_count [parameter::get -package_id $package_id -parameter MaxNotificationCount -default 4]
        set notification_sender [parameter::get -package_id $package_id -parameter NotificationSender -default "reminder@[address_domain]"]
        if { $notification_sender eq "" } {
            # Use the most specific default available
            set fixed_sender [parameter::get -package_id $package_id -parameter "FixedSenderEmail"]
            if { $fixed_sender ne "" } {
                set notification_sender $fixed_sender
            } elseif { [acs_mail_lite::utils::valid_email_p [ad_system_owner]] } {
                set notification_sender [ad_system_owner]
            } else {
                # Set to an email address that is required to exist
                # to avoid email loops and other issues
                # per RFC 5321 section 4.5.1 
                # https://tools.ietf.org/html/rfc5321#section-4.5.1
                # The somewhat unique capitalization may be useful
                # for identifyng source in diagnostic context.
                set notification_sender "PostMastER@[address_domain]"
            }
        }

        # delete all bounce-log-entries for users who received last email
        # X days ago without any bouncing (parameter)
        db_dml delete_log_if_no_recent_bounce {}

        # disable mail sending for users with more than X recently
        # bounced mails
        db_dml disable_bouncing_email {}

        # notify users of this disabled mail sending
        db_dml send_notification_to_bouncing_email {}

        # now delete bounce log for users with disabled mail sending
        db_dml delete_bouncing_users_from_log {}

        set subject "[ad_system_name] Email Reminder"

        # now periodically send notifications to users with
        # disabled email to tell them how to reenable the email
        set notifications [db_list_of_ns_sets get_recent_bouncing_users {}]

        # send notification to users with disabled email
        foreach notification $notifications {
            set notification_list [util_ns_set_to_list -set $notification]
            array set user $notification_list
            set user_id $user(user_id)
            set href [export_vars -base [ad_url]/register/restore-bounce {user_id}]
            set body "Dear $user(name),\n\n\
 Due to returning mails from your email account, \n \
 we currently do not send you any email from our system.\n\n \
 To re-enable your email notifications, please visit\n${href}"

            send -to_addr $notification_list -from_addr $notification_sender -subject $subject -body $body -valid_email
            ns_log Notice "Bounce notification send to user $user_id"

            # schedule next notification
            db_dml log_notification_sending {}
        }
    }

    ad_proc -public record_bounce {
        {-user_id ""}
        {-email ""}
    } {
        Records that an email bounce for this user
    } {
        if {$user_id eq ""} {
            set user_id [party::get_by_email -email $email]
        }
        if { $user_id ne "" && ![acs_mail_lite::bouncing_user_p -user_id $user_id] } {
            ns_log Debug "acs_mail_lite::incoming_email impl acs-mail-lite: Bouncing email from user $user_id"
            # record the bounce in the database
            db_dml record_bounce {}

            if {![db_resultrows]} {
                db_dml insert_bounce {}
            }
        }
    }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
