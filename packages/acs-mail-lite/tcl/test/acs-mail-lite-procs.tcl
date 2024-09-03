ad_library {

    Tests for procs in tcl/acs-mail-lite-procs.tcl

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        acs_mail_lite::send
    } \
    email_send {
        Test acs_mail_lite::send
    } {
        aa_run_with_teardown -test_code {

            set package_id [apm_package_id_from_key "acs-mail-lite"]
            set orig_send_immediately_p [parameter::get \
                                             -package_id $package_id \
                                             -parameter "send_immediately" \
                                             -default 0]
            parameter::set_value \
                -package_id $package_id \
                -parameter "send_immediately" \
                -value 0

            set any_object_id [db_string get_any_object {
                select max(object_id) from acs_objects
            }]

            set sender_info [acs::test::user::create]
            set recipient_info [acs::test::user::create]
            set from_addr [dict get $sender_info email]
            set to_addr [dict get $recipient_info email]


            aa_section "Scheduled sending"

            set subject {Test scheduled subject}
            set body {Test scheduled body}

            acs_mail_lite::send \
                -to_addr $to_addr \
                -from_addr $from_addr \
                -subject $subject \
                -body $body \
                -object_id $any_object_id

            aa_true "Mail was scheduled for sending" [db_0or1row check_scheduled {
                select 1 from acs_mail_lite_queue
                where object_id = :any_object_id
                and to_addr = :to_addr
                and from_addr = :from_addr
                and subject = :subject
                and body = :body
            }]

            set subject {Test immediate subject}
            set body {Test immediate body}

            aa_section "Immediate sending"
            #
            # We can only test an immediate send operation, when the
            # SMTP server is configured and available.
            #
            if {[::acs_mail_lite::configured_p]} {

                acs_mail_lite::send \
                    -to_addr $to_addr \
                    -from_addr $from_addr \
                    -subject $subject \
                    -body $body \
                    -object_id $any_object_id \
                    -send_immediately

                set recipient_id [dict get $recipient_info user_id]

                aa_false "Mail was NOT scheduled for sending" [db_0or1row check_scheduled {
                    select 1 from acs_mail_lite_queue
                    where object_id = :any_object_id
                    and to_addr = :to_addr
                    and from_addr = :from_addr
                    and subject = :subject
                    and body = :body
                }]

                aa_true "A unique id was assigned to the message" [db_0or1row check_id {
                    select 1 from acs_mail_lite_send_msg_id_map
                    where object_id = :any_object_id
                    and package_id = :package_id
                    and party_id = :recipient_id
                }]
            } else {
                aa_log "Test skipped, since the SMTP host is apparently not configured"
            }

        } -teardown_code {

            #
            # Delete the scheduled email
            #
            db_dml delete_scheduled_email {
                delete from acs_mail_lite_queue
                where object_id = :any_object_id
                and to_addr = :to_addr
                and from_addr = :from_addr
            }

            parameter::set_value \
                -package_id $package_id \
                -parameter "send_immediately" \
                -value $orig_send_immediately_p

            if {[info exists sender_info]} {
                acs::test::user::delete -user_id [dict get $sender_info user_id]
            }
            if {[info exists recipient_info]} {
                acs::test::user::delete -user_id [dict get $recipient_info user_id]
            }
        }
    }

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
