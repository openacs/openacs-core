ad_library {

    Notification Reply Sweeps

    @creation-date 2002-06-02
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::reply::sweep {

    ad_proc -public qmail_mail_queue_dir {} {
        return ""
    }
    
    ad_proc -public load_mail_queue {} {
        return [load_qmail_mail_queue -queue_dir [qmail_mail_queue_dir]]
    }

    ad_proc -public load_qmail_mail_queue {
        {-queue_dir:required}
    } {
        Scans qmail incoming email queue and queues up messages 
        using acs-mail.  

        @Author dan.wickstrom@openforce.net, ben@openforce
        @creation-date 22 Sept, 2001
    
        @param queue_dir The location of the qmail mail queue in
        the file-system.
    } {
        if [catch {set messages [glob "$queue_dir/new/*"]} ] {
            ns_log Notice "queue dir = [glob $queue_dir/new/*]"
            return [list]
        }

        set mail_link_ids [list]
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
            
            # Find the from user
            set from_user [cc_lookup_email_user $from]

            # We don't accept empty users for now
            if {[empty_string_p $from_user]} {
                ns_log Notice "NOTIF-INCOMING-EMAIL: no user $from"
                continue
            }
            
            set to_stuff [notification::reply::parse_reply_address -reply_address $to]

            # We don't accept a bad incoming email address
            if {[empty_string_p $to_stuff]} {
                ns_log Notice "NOTIF-INCOMING-EMAIL: bad to address $to"
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
            } on_error {
                ns_log Error "Error inserting incoming email into the queue"
            }
        }
        
        return $list_of_reply_ids
    }

    ad_proc -public process_db_queue {} {
        
    }

}
