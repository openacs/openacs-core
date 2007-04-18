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
    ad_proc -public with_finally {
	-code:required
	-finally:required
    } {
	Execute CODE, then execute cleanup code FINALLY.
	If CODE completes normally, its value is returned after
	executing FINALLY.
	If CODE exits non-locally (as with error or return), FINALLY
	is executed anyway.

	@option code Code to be executed that could throw and error
	@option finally Cleanup code to be executed even if an error occurs
    } {
	global errorInfo errorCode

	# Execute CODE.
	set return_code [catch {uplevel $code} string]
	set s_errorInfo $errorInfo
	set s_errorCode $errorCode

	# As promised, always execute FINALLY.  If FINALLY throws an
	# error, Tcl will propagate it the usual way.  If FINALLY contains
	# stuff like break or continue, the result is undefined.
	uplevel $finally

	switch $return_code {
	    0 {
		# CODE executed without a non-local exit -- return what it
		# evaluated to.
		return $string
	    }
	    1 {
		# Error
		return -code error -errorinfo $s_errorInfo -errorcode $s_errorCode $string
	    }
	    2 {
		# Return from the caller.
		return -code return $string
	    }
	    3 {
		# break
		return -code break
	    }
	    4 {
		# continue
		return -code continue
	    }
	    default {
		return -code $return_code $string
	    }
	}
    }

    #---------------------------------------
    ad_proc -public get_package_id {} {
	@returns package_id of this package
    } {
        return [apm_package_id_from_key acs-mail-lite]
    }
    
    #---------------------------------------
    ad_proc -public get_parameter {
        -name:required
        {-default ""}
    } {
	Returns an apm-parameter value of this package
	@option name parameter name
	@option default default parameter value
	@returns apm-parameter value of this package
    } {
        return [parameter::get -package_id [get_package_id] -parameter $name -default $default]
    }
    
    #---------------------------------------
    ad_proc -public parse_email_address {
	-email:required
    } {
	Extracts the email address out of a mail address (like Joe User <joe@user.com>)
	@option email mail address to be parsed
	@returns only the email address part of the mail address
    } {
        if {![regexp {<([^>]*)>} $email all clean_email]} {
            return $email
        } else {
            return $clean_email
        }
    }


    #---------------------------------------
    ad_proc -private log_mail_sending {
	-user_id:required
    } {
	Logs mail sending time for user
	@option user_id user for whom email sending should be logged
    } {
	db_dml record_mail_sent {}
	if {![db_resultrows]} {
	    db_dml insert_log_entry {}
	}
    }

    
    #---------------------------------------
    ad_proc -public generate_message_id {
    } {
        Generate an id suitable as a Message-Id: header for an email.
	@returns valid message-id for mail header
    } {
        # The combination of high resolution time and random
        # value should be pretty unique.

        return "<[clock clicks].[ns_time].oacs@[address_domain]>"
    }

    #---------------------------------------
    ad_proc -public valid_signature {
	-signature:required
	-message_id:required
    } {
        Validates if provided signature matches message_id
	@option signature signature to be checked
	@option msg message-id that the signature should be checked against
	@returns boolean 0 or 1
    } {
	if {![regexp "(<\[\-0-9\]+\\.\[0-9\]+\\.oacs@[address_domain]>)" $message_id match id] || $signature ne [ns_sha1 $id] } {
	    # either couldn't find message-id or signature doesn't match
	    return 0
	}
	return 1
    }

    #---------------------------------------
    ad_proc -public deliver_mail {
	-to_addr:required
	-from_addr:required
	-subject:required
	-body:required
	{-extraheaders ""}
	{-bcc ""}
	{-valid_email_p 0}
	-package_id:required
    } {
	Bounce Manager send 
	@option to_addr list of mail recipients
	@option from_addr mail sender
	@option subject mail subject
	@option body mail body
	@option extraheaders extra mail header
	@option bcc list of recipients of a mail copy
	@option valid_email_p flag if email needs to be checked if it's bouncing or
	        if calling code already made sure that the receiving email addresses
	        are not bouncing (this increases performance if mails are send in a batch process)
	@option package_id package_id of the sending package
	        (needed to call package-specific code to deal with bounces)
    } {
	set msg "Subject: $subject\nDate: [ns_httptime [ns_time]]"
	
	array set headers $extraheaders
	set message_id $headers(Message-Id)

	foreach {key value} $extraheaders {
	    append msg "\n$key\: $value"
	}

	## Blank line between headers and body
	append msg "\n\n$body\n"

        # ----------------------------------------------------
        # Rollout support
        # ----------------------------------------------------
        # if set in etc/config.tcl, then
        # packages/acs-tcl/tcl/rollout-email-procs.tcl will rename a
        # proc to ns_sendmail. So we simply call ns_sendmail instead
        # of the sendmail bin if the EmailDeliveryMode parameter is
        # set to anything other than default - JFR
        #-----------------------------------------------------
        set delivery_mode [ns_config ns/server/[ns_info server]/acs/acs-rollout-support EmailDeliveryMode] 

        if {$delivery_mode ne ""
            && $delivery_mode ne "default" 
        } {
            # The to_addr has been put in an array, and returned. Now
            # it is of the form: email email_address name namefromdb
            # user_id user_id_if_present_or_empty_string
            set to_address "[lindex $to_addr 1] ([lindex $to_addr 3])"
            set eh [util_list_to_ns_set $extraheaders]
            ns_sendmail $to_address $from_addr $subject $body $eh $bcc
        } else {

            if {[bounce_sendmail] eq "SMTP"} {
                ## Terminate body with a solitary period
                foreach line [split $msg "\n"] { 
                    if {"." eq [string trim $line]} {
                        append data .
                    }
		    #AG: ensure no \r\r\n terminations.
		    set trimmed_line [string trimright $line \r]
		    append data "$trimmed_line\r\n"
                }
                append data .
                
                smtp -from_addr $from_addr -sendlist $to_addr -msg $data -valid_email_p $valid_email_p -message_id $message_id -package_id $package_id
                if {$bcc ne ""} {
                    smtp -from_addr $from_addr -sendlist $bcc -msg $data -valid_email_p $valid_email_p -message_id $message_id -package_id $package_id
                }
                
            } else {
                sendmail -from_addr $from_addr -sendlist $to_addr -msg $msg -valid_email_p $valid_email_p -message_id $message_id -package_id $package_id
                if {$bcc ne ""} {
                    sendmail -from_addr $from_addr -sendlist $bcc -msg $msg -valid_email_p $valid_email_p -message_id $message_id -package_id $package_id
                }
            }
            
            
        }
    }
    
    #---------------------------------------
    ad_proc -private sendmail {
	-from_addr:required
        -sendlist:required
	-msg:required
	{-valid_email_p 0}
	{-cc ""}
	-message_id:required
	-package_id:required
    } {
	Sending mail through sendmail.
	@option from_addr mail sender
	@option sendlist list of mail recipients
	@option msg mail to be sent (subject, header, body)
	@option valid_email_p flag if email needs to be checked if it's bouncing or
	        if calling code already made sure that the receiving email addresses
	        are not bouncing (this increases performance if mails are send in a batch process)
	@option message_id message-id of the mail
	@option package_id package_id of the sending package
	        (needed to call package-specific code to deal with bounces)
    } {
	array set rcpts $sendlist
	if {[info exists rcpts(email)]} {
	    foreach rcpt $rcpts(email) rcpt_id $rcpts(user_id) rcpt_name $rcpts(name) {
		if { $valid_email_p || ![bouncing_email_p -email $rcpt] } {
		    with_finally -code {
			set sendmail [list [bounce_sendmail] "-f[bounce_address -user_id $rcpt_id -package_id $package_id -message_id $message_id]" "-t" "-i"]
			
			# add username if it exists
			if {$rcpt_name ne ""} {
			    set pretty_to "$rcpt_name <$rcpt>"
			} else {
			    set pretty_to $rcpt
			}
			
			# substitute all "\r\n" with "\n", because piped text should only contain "\n"
			regsub -all "\r\n" $msg "\n" msg
			
			if {[catch {
			    set err1 {}
			    set f [open "|$sendmail" "w"]
			    puts $f "From: $from_addr\nTo: $pretty_to\nCC: $cc\n$msg"
			    set err1 [close $f]
			} err2]} {
			    ns_log Error "Attempt to send From: $from_addr\nTo: $pretty_to\n$msg failed.\nError $err1 : $err2"
			}
		    } -finally {
		    }
		} else {
		    ns_log Notice "acs-mail-lite: Email bouncing from $rcpt, mail not sent and deleted from queue"
		}
		# log mail sending time
		if {$rcpt_id ne ""} { log_mail_sending -user_id $rcpt_id }
	    }
	}
    }

    #---------------------------------------
    ad_proc -private smtp {
	-from_addr:required
	-sendlist:required
	-msg:required
	{-valid_email_p 0}
	-message_id:required
	-package_id:required
    } {
	Sending mail through smtp.
	@option from_addr mail sender
	@option sendlist list of mail recipients
	@option msg mail to be sent (subject, header, body)
	@option valid_email_p flag if email needs to be checked if it's bouncing or
	        if calling code already made sure that the receiving email addresses
	        are not bouncing (this increases performance if mails are send in a batch process)
	@option message_id message-id of the mail
	@option package_id package_id of the sending package
	        (needed to call package-specific code to deal with bounces)
    } { 
	set smtp [ns_config ns/parameters smtphost]
	if {$smtp eq ""} {
	    set smtp [ns_config ns/parameters mailhost]
	}
	if {$smtp eq ""} {
	    set smtp localhost
	}
	set timeout [ns_config ns/parameters smtptimeout]
	if {$timeout eq ""} {
	    set timeout 60
	}
	set smtpport [ns_config ns/parameters smtpport]
	if {$smtpport eq ""} {
	    set smtpport 25
	}
	array set rcpts $sendlist
        foreach rcpt $rcpts(email) rcpt_id $rcpts(user_id) rcpt_name $rcpts(name) {
	    if { $valid_email_p || ![bouncing_email_p -email $rcpt] } {
		# add username if it exists
		if {$rcpt_name ne ""} {
		    set pretty_to "$rcpt_name <$rcpt>"
		} else {
		    set pretty_to $rcpt
		}

		set msg "From: $from_addr\r\nTo: $pretty_to\r\n$msg"
		set mail_from [bounce_address -user_id $rcpt_id -package_id $package_id -message_id $message_id]

		## Open the connection
		set sock [ns_sockopen $smtp $smtpport]
		set rfp [lindex $sock 0]
		set wfp [lindex $sock 1]

		## Perform the SMTP conversation
		with_finally -code {
		    _ns_smtp_recv $rfp 220 $timeout
		    _ns_smtp_send $wfp "HELO [ns_info hostname]" $timeout
		    _ns_smtp_recv $rfp 250 $timeout
		    _ns_smtp_send $wfp "MAIL FROM:<$mail_from>" $timeout
		    _ns_smtp_recv $rfp 250 $timeout

		    # By now we are sure that the server connection works, otherwise
		    # we would have gotten an error already
		    
		    if {[catch {
			_ns_smtp_send $wfp "RCPT TO:<$rcpt>" $timeout
			_ns_smtp_recv $rfp 250 $timeout
		    } errmsg]} {
			
			# This user has a problem with retrieving the email
			# Record this fact as a bounce e-mail
			if { $rcpt_id ne "" && ![bouncing_user_p -user_id $rcpt_id] } {
			    ns_log Notice "acs-mail-lite: Bouncing email from user $rcpt_id due to $errmsg"
			    # record the bounce in the database
			    db_dml record_bounce {}
			    
			    if {![db_resultrows]} {
				db_dml insert_bounce {}
			    }
			    
			}
			
			return
		    }

		    _ns_smtp_send $wfp DATA $timeout
		    _ns_smtp_recv $rfp 354 $timeout
		    _ns_smtp_send $wfp $msg $timeout
		    _ns_smtp_recv $rfp 250 $timeout
		    _ns_smtp_send $wfp QUIT $timeout
		    _ns_smtp_recv $rfp 221 $timeout

		} -finally {
		    ## Close the connection
		    close $rfp
		    close $wfp
		}
	    } else {
		ns_log Notice "acs-mail-lite: Email bouncing from $rcpt, mail not sent and deleted from queue"
	    }
	    # log mail sending time
	    if {$rcpt_id ne ""} { log_mail_sending -user_id $rcpt_id }
	}
    }

    #---------------------------------------
    ad_proc -private get_address_array {
	-addresses:required
    } {	Checks if passed variable is already an array of emails,
	user_names and user_ids. If not, get the additional data
	from the db and return the full array.
	@option addresses variable to checked for array
	@returns array of emails, user_names and user_ids to be used
	         for the mail procedures
    } {
	if {[catch {array set address_array $addresses}]
	    || ![string equal [lsort [array names address_array]] [list email name user_id]]} {

	    # either user just passed a normal address-list or
	    # user passed an array, but forgot to provide user_ids
	    # or user_names, so we have to get this data from the db

	    if {![info exists address_array(email)]} {
		# so user passed on a normal address-list
		set address_array(email) $addresses
	    }

	    set address_list [list]
	    foreach email $address_array(email) {
		# strip out only the emails from address-list
		lappend address_list [string tolower [parse_email_address -email $email]]
	    }

	    array unset address_array
	    # now get the user_names and user_ids
	    foreach email $address_list {
		set email [string tolower $email]
		if {[db_0or1row get_user_name_and_id ""]} {
		    lappend address_array(email) $email
		    lappend address_array(name) $user_name
		    lappend address_array(user_id) $user_id
		} else {
		    lappend address_array(email) $email
		    lappend address_array(name) ""
		    lappend address_array(user_id) ""
		}
	    }
	}
	return [array get address_array]
    }
    
    #---------------------------------------
    ad_proc -public send {
	-send_immediately:boolean
	-valid_email:boolean
        -to_addr:required
        -from_addr:required
        {-subject ""}
        -body:required
        {-extraheaders ""}
        {-bcc ""}
	{-package_id ""}
	-no_callback:boolean
    } {
        Reliably send an email message.

	@option send_immediately Switch that lets the mail send directly without adding it to the mail queue first.
	@option valid_email Switch that avoids checking if the email to be mailed is not bouncing
	@option to_addr List of mail-addresses or array of email,name,user_id containing lists of users to be mailed
	@option from_addr mail sender
	@option subject mail subject
	@option body mail body
	@option extraheaders extra mail headers in an ns_set
	@option bcc see to_addr
	@option package_id To be used for calling a package-specific proc when mail has bounced
	@option no_callback_p Boolean that indicates if callback should be executed or not. If you don't provide it it will execute callbacks
        @returns the Message-Id of the mail or an empty string if e-mail was discarded
    } {

	## Extract "from" email address
	set from_addr [parse_email_address -email $from_addr]

	set from_party_id [party::get_by_email -email $from_addr] 
	set to_party_id [party::get_by_email -email $to_addr] 
	
	## Get address-array with email, name and user_id
	set to_addr [get_address_array -addresses [string map {\n "" \r ""} $to_addr]]
	if {$bcc ne ""} {
	    set bcc [get_address_array -addresses [string map {\n "" \r ""} $bcc]]
	}

        if {$extraheaders ne ""} {
            set eh_list [util_ns_set_to_list -set $extraheaders]
        } else {
            set eh_list ""
        }

        # Subject cannot contain newlines -- replace with spaces
        regsub -all {\n} $subject { } subject

	set message_id [generate_message_id]
        lappend eh_list "Message-Id" $message_id

	if {$package_id eq ""} {
	    if {[ad_conn -connected_p]} {
		set package_id [ad_conn package_id]
	    } else {
		set package_id ""
	    }
	}

        # Subject can not be longer than 200 characters
        if { [string length $subject] > 200 } {
            set subject "[string range $subject 0 196]..."
        }

	# check, if send_immediately is set
	# if not, take global parameter
	if {$send_immediately_p} {
	    set send_p $send_immediately_p
	} else {
	    # if parameter is not set, get the global setting
	    set send_p [parameter::get -package_id [get_package_id] -parameter "send_immediately" -default 0]
	}

	if {$to_addr ne ""} {
	    # if send_p true, then start acs_mail_lite::send_immediately, so mail is not stored in the db before delivery
	    if { $send_p } {
		acs_mail_lite::send_immediately -to_addr $to_addr -from_addr $from_addr -subject $subject -body $body -extraheaders $eh_list -bcc $bcc -valid_email_p $valid_email_p -package_id $package_id
	    } else {
		# else, store it in the db and let the sweeper deliver the mail
		db_dml create_queue_entry {}
	    }
	    
	    if { !$no_callback_p } {
		callback acs_mail_lite::send \
		    -package_id $package_id \
		    -from_party_id $from_party_id \
		    -to_party_id $to_party_id \
		    -body $body \
		    -message_id $message_id \
		    -subject $subject
	    }
	    
	    return $message_id
	} else {
	    return ""
	}
    }


    #---------------------------------------
    ad_proc -private sweeper {} {
        Send messages in the acs_mail_lite_queue table.
    } {
	# Make sure that only one thread is processing the queue at a time.
	if {[nsv_incr acs_mail_lite send_mails_p] > 1} {
	    nsv_incr acs_mail_lite send_mails_p -1
	    return
	}

	with_finally -code {
	    db_foreach get_queued_messages {} {
		with_finally -code {
		    deliver_mail -to_addr $to_addr -from_addr $from_addr \
			-subject $subject -body $body -extraheaders $extra_headers \
			-bcc $bcc -valid_email_p $valid_email_p \
			-package_id $package_id

		    db_dml delete_queue_entry {}
		} -finally {
		}
	    }
	} -finally {
	    nsv_incr acs_mail_lite send_mails_p -1
	}
    }

    #---------------------------------------
    ad_proc -private send_immediately {
        -to_addr:required
        -from_addr:required
        {-subject ""}
        -body:required
        {-extraheaders ""}
        {-bcc ""}
	{-valid_email_p 0}
	-package_id:required
    } {
	Procedure to send mails immediately without queuing the mail in the database for performance reasons.
	If ns_sendmail fails, the mail will be written in the db so the sweeper can send them out later.
	@option to_addr List of mail-addresses or array of email,name,user_id containing lists of users to be mailed
	@option from_addr mail sender
	@option subject mail subject
	@option body mail body
	@option extraheaders extra mail headers
	@option bcc see to_addr
	@option valid_email_p Switch that avoids checking if the email to be mailed is not bouncing
	@option package_id To be used for calling a package-specific proc when mail has bounced
    } {
	if {[catch {
	    deliver_mail -to_addr $to_addr -from_addr $from_addr -subject $subject -body $body -extraheaders $extraheaders -bcc $bcc -valid_email_p $valid_email_p -package_id $package_id
	} errmsg]} {
	    ns_log Error "acs_mail_lite::deliver_mail failed: $errmsg"
	    ns_log "Notice" "Mail info will be written in the db"
	    db_dml create_queue_entry {}
	} else {
	    ns_log "Debug" "acs_mail_lite::deliver_mail successful"
	}
    }

    #---------------------------------------
    ad_proc -private message_interpolate {
	{-values:required}
	{-text:required}
    } {
	Interpolates a set of values into a string. This is directly copied from the bulk mail package
	
	@param values a list of key, value pairs, each one consisting of a
	target string and the value it is to be replaced with.
	@param text the string that is to be interpolated
	
	@return the interpolated string
    } {
	foreach pair $values {
	    regsub -all [lindex $pair 0] $text [lindex $pair 1] text
	}
	return $text
    }

    #---------------------------------------

}
