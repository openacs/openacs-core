ad_library {

    Provides a simple API for reliably sending email.

    (Legacy and deprecated procs)

    @author Hector Romojaro (hector.romojaro@gmail.com)
    @creation-date 21 June 2018
    @cvs-id $Id$

}

package require mime 1.4
package require smtp 1.4
package require base64 2.3.1
namespace eval acs_mail_lite {

    ad_proc -deprecated load_mails {
        -queue_dir:required
    } {
        Scans for incoming email. The function requires
        incoming emails that comply to the following syntax rule:
<pre>
        [&lt;SitePrefix&gt;][-]&lt;ReplyPrefix&gt;-Whatever@&lt;BounceDomain&gt;

        [] = optional
        &lt;&gt; = Package Parameters
        </pre>

        If no SitePrefix is set we assume that there is only one
        OpenACS installation. Otherwise only messages are dealt with
        which contain a SitePrefix.

        ReplyPrefixes are provided by packages that implement the
        callback acs_mail_lite::incoming_email and provide a package
        parameter called ReplyPrefix. Only implementations are
        considered where the implementation name is equal to the
        package key of the package.

        Also we only deal with messages that contain a valid and
        registered ReplyPrefix.  These prefixes are automatically set
        in the acs_mail_lite_prefixes table.

        @author Nima Mazloumi (nima.mazloumi@gmx.de)
        @creation-date 2005-07-15

        @option queue_dir The location of the qmail mail
                (BounceMailDir) queue in the file-system
                i.e. /home/service0/mail.

        @see acs_mail_lite::incoming_email
        @see acs_mail_lite::parse_email
    } {

        # get list of all incoming mail
        if {[catch {
            set messages [glob "$queue_dir/new/*"]
        } errmsg]} {
            if {[string match "no files matched glob pattern*"  $errmsg ]} {
                ns_log Debug "load_mails: queue dir = $queue_dir/new/*, no messages"
            } else {
                ns_log Error "load_mails: queue dir = $queue_dir/new/ error $errmsg"
            }
            return [list]
        }

        # loop over every incoming mail
        foreach msg $messages {
            ns_log Debug "load_mails: opening $msg"
            array set email {}

            # This will parse the E-mail and extract the files to the filesystem
            parse_email -file $msg -array email

            set email(to) [parse_email_address -email $email(to)]
            set email(from) [parse_email_address -email $email(from)]
            set subject [lindex $email(subject) 0]
            if {$email(bodies) eq ""} {
                ad_script_abort
                ns_log Notice "E-Mail without body"
            }

            # Do no execute any callbacks if the email is an autoreply.
            # Thanks to Vinod for the idea and the code
            set callback_executed_p [acs_mail_lite::autoreply_p \
                                         -subject $subject \
                                         -from $email(from)]

            if {!$callback_executed_p} {
                # Special treatment for e-mails which look like they contain an object_id
                set pot_object_id [lindex [split $email(to) "@"] 0]
                ns_log Debug "Object_id for mail:: $pot_object_id"
                if {[string is integer -strict  $pot_object_id]} {
                    if {[acs_object::object_p -id $pot_object_id]} {
                        callback acs_mail_lite::incoming_object_email \
                            -array email \
                            -object_id $pot_object_id

                        # Mark that the callback has been executed already
                        set no_callback_p 1
                    }
                }
            }

            if {!$callback_executed_p} {
                # We execute all callbacks now
                callback acs_mail_lite::incoming_email -array email
            }

            #let's delete the file now
            if {[catch {file delete -- $msg} errmsg]} {
                ns_log Error "load_mails: unable to delete queued message $msg: $errmsg"
            } else {
                ns_log Debug "load_mails: deleted $msg"
            }
        }
    }

    ad_proc -private parse_email {
        -file:required
        -array:required
    } {
        An email is split into several parts: headers, bodies and
        files lists and all headers directly.

        The headers consists of a list with header names as keys and
        their corresponding values. All keys are lowercase.  The
        bodies consists of a list with two elements: content-type and
        content.  The files consists of a list with three elements:
        content-type, filename and content.

        The array with all the above data is upvared to the caller environment.

        Important headers are:

        -message-id (a unique id for the email, is different for each email except it was bounced from a mailer daemon)
        -subject
        -from
        -to

        Others possible headers:

        -date
        -received
        -references (this references the original message id if the email is a reply)
        -in-reply-to (this references the original message id if the email is a reply)
        -return-path (this is used for mailer daemons to bounce emails back like bounce-user_id-signature-package_id@service0.com)

        Optional application specific stuff only exist in special cases:

        X-Mozilla-Status
        X-Virus-Scanned
        X-Mozilla-Status2
        X-UIDL
        X-Account-Key
        X-Sasl-enc

        You can therefore get a value for a header either through iterating the headers list or simply by calling i.e. "set message_id $email(message-id)".

        Note: We assume "application/octet-stream" for all attachments and "base64" for
        as transfer encoding for all files.

        Note: tcllib required - mime, base64

        @author Nima Mazloumi (nima.mazloumi@gmx.de)
        @creation-date 2005-07-15

    } {
        upvar $array email

        #prepare the message
        if {[catch {set mime [mime::initialize -file $file]} errormsg]} {
            ns_log error "Email could not be delivered for file $file"
            set stream [open $file]
            set content [read $stream]
            close $stream
            ns_log error $content
            file delete -- $file
            return
        }

        #get the content type
        set content [mime::getproperty $mime content]

        #get all available headers
        set keys [mime::getheader $mime -names]

        set headers [list]

        # create both the headers array and all headers directly for the email array
        foreach header $keys {
            set value [mime::getheader $mime $header]
            set email([string tolower $header]) $value
            lappend headers [list $header $value]
        }

        set email(headers) $headers

        #check for multipart, otherwise we only have one part
        if { [string first "multipart" $content] != -1 } {
            set parts [mime::getproperty $mime parts]
        } else {
            set parts [list $mime]
        }

        # travers the tree and extract parts into a flat list
        set all_parts [list]
        foreach part $parts {
            if {[mime::getproperty $part content] eq "multipart/alternative"} {
                foreach child_part [mime::getproperty $part parts] {
                    lappend all_parts $child_part
                }
            } else {
                lappend all_parts $part
            }
        }

        set bodies [list]
        set files [list]

        #now extract all parts (bodies/files) and fill the email array
        foreach part $all_parts {
            # Attachments have a "Content-disposition" part
            # Therefore, we filter out if it is an attachment here
            if {[catch {mime::getheader $part Content-disposition}] || [mime::getheader $part Content-disposition] eq "inline"} {
                switch [mime::getproperty $part content] {
                    "text/plain" {
                        lappend bodies [list "text/plain" [mime::getbody $part]]
                    }
                    "text/html" {
                        lappend bodies [list "text/html" [mime::getbody $part]]
                    }
                }
            } else {
                set encoding [mime::getproperty $part encoding]
                set body [mime::getbody $part -decode]
                set content  $body
                set params [mime::getproperty $part params]
                array set param $params

                # Append the file if there exist a filename to use. Otherwise do not append
                if {[info exists param(name)] && $param(name) ne ""} {
                    set filename $param(name)

                    # Determine the content_type
                    set content_type [mime::getproperty $part content]
                    if {$content_type eq "application/octet-stream"} {
                        set content_type [ns_guesstype $filename]
                    }

                    lappend files [list $content_type $encoding $filename $content]
                }
            }
        }

        set email(bodies) $bodies
        set email(files) $files

        #release the message
        mime::finalize $mime -subordinates all
    }

    ad_proc -public -deprecated autoreply_p {
        {-subject ""}
        {-from ""}
    } {
        Parse the subject, from and body to determine if the email is an auto reply
        Typical autoreplies are "Out of office" messages. This is what the procedure does

        @param subject Subject of the Email that will be scanned for "out of office"
        @param from From address which will be checked if it is coming from a mailer daemon

        @return 1 if this is actually an autoreply

        @see acs_mail_lite::email_type
    } {
        set autoreply_p 0
        if {$subject ne ""} {
        # check subject
            set autoreply_p [regexp -nocase "(out of.*office|automated response|autoreply)" $subject]
            set autoreply_p [regexp "NDN" $subject]
            set autoreply_p [regexp "\[QuickML\] Error" $subject]
        }

        if {$from ne ""} {
        # check from if it comes from the mailer daemon
            set autoreply_p [regexp -nocase "mailer.*daemon" $from]
        }
        return $autoreply_p
    }

    ad_proc -public -deprecated parse_bounce_address {
        -bounce_address:required
    } {
        This takes a reply address, checks it for consistency,
        and returns a list of user_id, package_id and bounce_signature found

        @option bounce_address bounce address to be checked
        @return tcl-list of user_id package_id bounce_signature
        @see acs_mail_lite::inbound_email_context
    } {
        set regexp_str "\[[bounce_prefix]\]-(\[0-9\]+)-(\[^-\]+)-(\[0-9\]*)\@"
        if {![regexp $regexp_str $bounce_address all user_id signature package_id]} {
            ns_log Debug "acs-mail-lite: bounce address not found for $bounce_address"
            return ""
        }
        return [list $user_id $package_id $signature]
    }

    ad_proc -deprecated -public bouncing_email_p {
        -email:required
    } {
        Checks if email address is bouncing mail
        @option email email address to be checked for bouncing
        @return boolean 1 if bouncing 0 if ok.
        @see acs_mail_lite::bouncing_user_p
    } {
        return [bouncing_user_p \
                    -user_id [party::get_by_email -email $email]]
    }

    ad_proc -deprecated -public scan_replies {} {
        Scheduled procedure that will scan for bounced mails
        @see acs_mail_lite::check_bounces
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

    ad_proc -deprecated -public record_bounce {
        {-user_id ""}
        {-email ""}
    } {
        Records that an email bounce for this user
        @see acs_mail_lite::bounce_ministry
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
