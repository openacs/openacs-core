ad_library {

    Provides a simple API for reliably sending email.

    @author Eric Lorenzo (eric@openforce.net)
    @creation-date 22 March 2002
    @cvs-id $Id$

}

namespace eval acs_mail_lite {

    ad_proc -public send {
        {-to_addr:required}
        {-from_addr:required}
        {-subject ""}
        {-body:required}
        {-extraheaders ""}
        {-bcc ""}
    } {
        Reliably send an email message.
    } {
        if {![empty_string_p $extraheaders]} {
            set eh_list [util_ns_set_to_list -set $extraheaders]
        } else {
            set eh_list ""
        }

        # Subject can not be longer than 200 characters
        if { [string length $subject] > 200 } {
            set subject "[string range $subject 0 196]..."
        }

        db_dml create_queue_entry {}
    }

    ad_proc -private sweeper {} {
        Send messages in the acs_mail_lite_queue table.
    } {
        db_foreach get_queued_messages {} {
            set eh [util_list_to_ns_set $extra_headers]
            if {[catch {ns_sendmail $to_addr $from_addr $subject $body $eh $bcc} errmsg]} {
                ns_log Error "ns_sendmail failed: $errmsg"
            } else {
                db_dml delete_queue_entry {}
            }
        }
    }

}
