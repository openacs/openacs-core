ad_library {

    Notifications Email Delivery Method

    @creation-date 2002-06-20
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::email {

    ad_proc -public get_package_id {} {
        Get the package id for notifications (depends on this being a singular
        package)
    } {
        return [apm_package_id_from_key notifications]
    }

    ad_proc -public get_parameter {
        {-name:required}
        {-default ""}
    } {
        Shorthand proc to return a given notifications package parameter.
    } {
        return [parameter::get -package_id [get_package_id] -parameter $name -default $default]
    }

    ad_proc -public address_domain {} {
        Get the domain name to use for e-mail.  The package parameter "EmailDomain" is
        preferred, but if it doesn't exist, we build one using the system URL.
    } {
        set domain [get_parameter -name "EmailDomain"]
        if { $domain eq "" } {
            # No domain set up, let's use the default from the system info
            # This may not find anything, but at least it's worth a try
            if { ![regexp {^(https?://)?(www\.)?([^/]*)} [ad_url] match ignore ignore domain] } {
                ns_log Warning "notification::email::address_domain: Couldn't find an email domain for notifications."
            } else {
		regsub -nocase {(.*):.*} $domain "\\1" domain
	    }
        }
        return $domain
    }

    ad_proc -public manage_notifications_url {} {
        Build a url to the "manage notifications" script.
    } {
        return "[ad_url][apm_package_url_from_key [notification::package_key]]manage"
    }

    ad_proc -public reply_address_prefix {} {
        Shorthand proc to return the email reply address prefix parameter value.
    } {
        return [get_parameter -name "EmailReplyAddressPrefix"]
    }

    ad_proc -private qmail_mail_queue_dir {} {
        Shorthand proc to return the email qmail-style mail queue (i.e. a Maildir directory)
    } {
        return [get_parameter -name "EmailQmailQueue"]
    }

    ad_proc -private parse_email_address {email} {
        Strip out the user's name (in angle brackets) from an e-mail address if it exists.
    } {
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
        Build an object/type-specific e-mail address that the user can reply to.
    } {
        if {$object_id eq "" || $type_id eq ""} {
            return "\"[address_domain] mailer\" <[reply_address_prefix]@[address_domain]>"
        } else {
            return "\"[address_domain] mailer\" <[reply_address_prefix]-$object_id-$type_id@[address_domain]>"
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
        from_user_id
        to_user_id
        reply_object_id
        notification_type_id
        subject
        content_text
        content_html
        file_ids
    } {
        Send the actual email.

        @param from_user_id The user_id of the user that the email should be sent as. Leave empty for the standard mailer from address.
    } {

       # Get user data
       set email [party::email -party_id $to_user_id]
       set user_locale [lang::user::site_wide_locale -user_id $to_user_id]
       if { $user_locale eq "" } {
           set user_locale lang::system::site_wide_locale
       }

       # Variable used in the content
       set manage_notifications_url [manage_notifications_url]

       if { $content_html eq "" } {
           set mime_type "text/plain"
           append content_text "\n#" "notifications.lt_Getting_too_much_emai#"
           set content $content_text
       } else {
           set mime_type "text/html"
           append content_html "<p>#" "notifications.lt_Getting_too_much_emai#</p>"
           set content $content_html
       }

       # convert relative URLs to fully qualified URLs
       set content [ad_html_qualify_links $content]

       # Use this to build up extra mail headers        
       set extra_headers [list]

       # This should disable most auto-replies.
       lappend extra_headers [list "Precedence" "list"]
        
       set reply_to [reply_address -object_id $reply_object_id -type_id $notification_type_id]

       if { $from_user_id ne "" && $from_user_id != 0 && [db_0or1row get_person {}]} {
           set from_email [party::email -party_id $from_user_id]
	   
           # Set the Mail-Followup-To address to the
           # address of the notifications handler.
           lappend extra_headers [list "Mail-Followup-To" $reply_to]
       } else {
           set from_email $reply_to
       }

       acs_mail_lite::send \
           -to_addr $email \
           -from_addr $from_email \
           -reply_to $reply_to \
           -mime_type $mime_type \
           -subject [lang::util::localize $subject $user_locale] \
           -body [lang::util::localize $content $user_locale] \
           -file_ids $file_ids \
           -use_sender \
           -extraheaders $extra_headers
    }

    ad_proc -public bounce_mail_message {
        {-to_addr:required}
	{-from_addr:required}
	{-body:required}
	{-message_headers:required}
	{-reason ""}
    } {
        This sends a bounce message indicating a a failuring in sending
	a message to the system.

        @author mkovach@alal.com
	@creation-date 05 Nov 2003

	@param to_addr who the bounce is going to
	@param from_addr who the bouncing message as sent to
	@param the message body
	@param message_headers the headers of the message
	@param reason (defaults to nothing).  Reason for bounce
    } {
        set domain [address_domain]
        set bounce_to [parse_email_address $to_addr]
	set bounce_address [parse_email_address $from_addr]
	set bounce_from "MAILER-DAEMON@$domain"
	set bounce_subject "failure notice"
	set l "Hi.  This is the notification program at $domain.\n"
	append l "I'm afraid I wasn't able to deliver your message to the\n"
	append l "following addresses.  This is a permament error; I've\n"
	append l "given up.  Sorry it didn't work out.\n\n"
        append l "<$from_addr>:\n"
	append l "$reason\n\n"
	append l "--- Below is this line is a copy of the message.\n\n"
	append l "$message_headers\n\n"
	append l "$body\n"
	acs_mail_lite::send \
	    -to_addr $bounce_to \
	    -from_addr $bounce_from \
	    -subject $bounce_subject \
	    -body $l \
	    -extraheaders ""
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
	ns_log debug "load_qmail_mail_queue: checking $queue_dir/new/ for incoming mail"

        if {[catch {
            set messages [glob "$queue_dir/new/*"]
        } errmsg]} {
	    if {[string match "no files matched glob pattern*"  $errmsg ]} { 
		ns_log Debug "load_qmail_mail_queue: queue dir = $queue_dir/new/*, no messages"		
	    } else { 
		ns_log Error "load_qmail_mail_queue: queue dir = $queue_dir/new/ error $errmsg"
	    }
	    return {}
        }

        set list_of_reply_ids [list]
        set new_messages_p 0

        foreach msg $messages {
            ns_log Debug "load_qmail_mail_queue: opening file: $msg"
            if {[catch {set f [open $msg r]} errmsg]} {
		# spit out an error message for failure to open and contiue to next message
		ns_log Warning "load_qmail_mail_queue: error opening file $errmsg"
		continue
            }
            set orig_file [read $f]
            close $f
            set file [split $orig_file "\n"]

            set new_messages 1
            set end_of_headers_p 0
            set i 0
            set line [lindex $file $i]
            set headers [list]
            set orig_headers ""

            # walk through the headers and extract each one
            set is_auto_reply_p 0
            while {$line ne ""} {
                set next_line [lindex $file $i+1]
                if {[regexp {^[ ]*$} $next_line match] && $i > 0} {
                    set end_of_headers_p 1
                }
                set multiline_header_p 0
                if {[regexp {^([^:]+):[ ]+(.+)$} $line match name value]} {
                    # join headers that span more than one line (e.g. Received)
                    if { ![regexp {^([^:]+):[ ]+(.+)$} $next_line match] && !$end_of_headers_p} {
			set multiline_header_p 1
		    } else {
			# we only want messages a person typed in themselves - nothing
			# from any sort of auto-responder.
			if { [string compare -nocase $name "Auto-Submitted"] == 0 } {
			    set is_auto_reply_p 1
			    break
			} elseif { [string compare -nocase $name "Subject"] == 0 && [string first "Out of Office AutoReply:" $value] == 0 } {
			    # added for BP
			    set is_auto_reply_p 1
			    break
			} else {
			    lappend headers [string tolower $name] $value
			    append orig_headers "$line\n"
			}
		    }

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
                if { $multiline_header_p } {
                    append line [lindex $file $i]
                } else {
                    set line [lindex $file $i]
                }
            }


            # a break above just exited the while loop;  now we need to skip
            # the rest of the foreach as well
            if { $is_auto_reply_p } {
                ns_log Debug "load_qmail_mail_queue: message $msg is from an auto-responder, skipping"
                if {[catch {file delete -- $msg} errmsg]} {
                    ns_log Warning "load_qmail_mail_queue: couldn't remove message $msg:  $errmsg"
                }
                continue
            }

            set body [parse_incoming_email $orig_file]



            # okay now we have a list of headers and the body, let's
            # put it into notifications stuff
            array set email_headers $headers


            if {[catch {set from $email_headers(from)}]} {
                set from ""
            }
            if {[catch {set to $email_headers(to)}]} {
                set to ""
            }

            set from [parse_email_address $from]
            set to [parse_email_address $to]

            # Find the from user
            set from_user [party::get_by_email -email $from]

            # We don't accept empty users for now
            if {$from_user eq ""} {
                ns_log debug "load_qmail_mail_queue: no user for from address: $from, to: $to. bouncing message."
		# bounce message with an informative error.
		bounce_mail_message  -to_addr $email_headers(from) \
		    -from_addr $email_headers(to) \
		    -body $body  \
		    -message_headers $orig_headers \
		    -reason "Invalid sender.  You must be a member of the site and\nyour From address must match your registered address."

                if {[catch {file delete -- $msg} errmsg]} {
                    ns_log Warning "load_qmail_mail_queue: couldn't remove message $msg: $errmsg"
                }
                continue
            }

            set to_stuff [parse_reply_address -reply_address $to]
            # We don't accept a bad incoming email address
            if {$to_stuff eq ""} {
                ns_log debug "load_qmail_mail_queue: bad to address $to from $from. bouncing message."

		# bounce message here
		bounce_mail_message -to_addr $email_headers(from) \
		    -from_addr $email_headers(to) \
		    -body $body \
		    -message_headers $orig_headers \
		    -reason "Invalid To Address"

                if {[catch {file delete -- $msg} errmsg]} {
                    ns_log Warning "load_qmail_mail_queue: couldn't remove message file $msg: $errmsg"
                }
                continue
            }

            set object_id [lindex $to_stuff 0]
            set type_id [lindex $to_stuff 1]
	    set to_addr $to 

            db_transaction {  
		set reply_id [notification::reply::new \
				  -object_id $object_id \
				  -type_id $type_id \
				  -from_user $from_user \
				  -subject $email_headers(subject) \
				  -content $body]
	        set headers $orig_headers
                db_dml holdinsert {} -clobs [list $to_addr $headers $body]

                if {[catch {file delete -- $msg} errmsg]} { 
		    ns_log Error "load_qmail_mail_queue: unable to delete queued message $msg: $errmsg"
		}

                lappend list_of_reply_ids $reply_id
	    } on_error {
                ns_log Error "load_qmail_mail_queue: error inserting incoming email into the queue: $errmsg"
	    }
        }

        return $list_of_reply_ids
    }

    ad_proc -public scan_replies {} {
        scan for replies
    } {
        ns_log debug "notification::email::scan_replies: about to load qmail queue"
        return [load_qmail_mail_queue -queue_dir [qmail_mail_queue_dir]]
    }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
