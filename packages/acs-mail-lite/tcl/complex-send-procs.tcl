namespace eval acs_mail_lite {

    #---------------------------------------
    # complex_send
    # created ... by ...
    # modified 2006/07/25 by nfl: new param. alternative_part_p
    #                             and creation of multipart/alternative
    # 2006/../.. new created as an frontend to the old complex_send that now is called complex_send_immediatly
    # 2006/11/17 modified (nfl)
    #---------------------------------------
    ad_proc -public complex_send {
        -send_immediately:boolean
        -valid_email:boolean
        {-to_party_ids ""}
        {-cc_party_ids ""}
        {-bcc_party_ids ""}
        {-to_group_ids ""}
        {-cc_group_ids ""}
        {-bcc_group_ids ""}
        {-to_addr ""}
        {-cc_addr ""}
        {-bcc_addr ""}
        -from_addr:required
        {-reply_to ""}
        {-subject ""}
        -body:required
        {-package_id ""}
        {-files ""}
        {-file_ids ""}
        {-folder_ids ""}
        {-mime_type "text/plain"}
        {-object_id ""}
        {-single_email_p ""}
        {-no_callback_p ""}
        {-extraheaders ""}
        {-alternative_part_p ""}
        -single_email:boolean
        -no_callback:boolean 
        -use_sender:boolean
    } {

        Prepare an email to be send with the option to pass in a list
        of file_ids as well as specify an html_body and a mime_type. It also supports multiple "TO" recipients as well as CC
        and BCC recipients. Runs entirely off MIME and SMTP to achieve this. 
        For backward compatibility a switch "single_email_p" is added.

        @param send_immediately The email is send immediately and not stored in the acs_mail_lite_queue
        
        @param to_party_ids list of party ids to whom we send this email

        @param cc_party_ids list of party ids to whom we send this email in "CC"

        @param bcc_party_ids list of party ids to whom we send this email in "BCC"

        @param to_party_ids list of group_ids to whom we send this email

        @param cc_party_ids list of group_ids to whom we send this email in "CC"

        @param bcc_party_ids list of group_ids to whom we send this email in "BCC"

        @param to_addr List of e-mail addresses to send this mail to. We will figure out the name if possible.

        @param from_addr E-Mail address of the sender. We will try to figure out the name if possible.
        
        @param subject of the email
        
        @param body Text body of the email
        
        @param cc_addr List of CC Users e-mail addresses to send this mail to. We will figure out the name if possible. Only useful if single_email is provided. Otherwise the CC users will be send individual emails.

        @param bcc_addr List of CC Users e-mail addresses to send this mail to. We will figure out the name if possible. Only useful if single_email is provided. Otherwise the CC users will be send individual emails.

        @param package_id Package ID of the sending package
        
        @param files List of file_title, mime_type, file_path (as in full path to the file) combination of files to be attached

        @param folder_ids ID of the folder who's content will be send along with the e-mail.

        @param file_ids List of file ids (items or revisions) to be send as attachments. This will only work with files stored in the file system.

        @param mime_type MIME Type of the mail to send out. Can be "text/plain", "text/html".

        @param object_id The ID of the object that is responsible for sending the mail in the first place

        @param extraheaders List of keywords and their values passed in for headers. Interesting ones are: "Precedence: list" to disable autoreplies and mark this as a list message. This is as list of lists !!

        @param single_email Boolean that indicates that only one mail will be send (in contrast to one e-mail per recipient). 

        @param no_callback Boolean that indicates if callback should be executed or not. If you don't provide it it will execute callbacks	
        @param single_email_p Boolean that indicates that only one mail will be send (in contrast to one e-mail per recipient). Used so we can set a variable in the callers environment to call complex_send.

        @param no_callback_p Boolean that indicates if callback should be executed or not. If you don't provide it it will execute callbacks. Used so we can set a variable in the callers environment to call complex_send.

        @param use_sender Boolean indicating that from_addr should be used regardless of fixed-sender parameter

        @param alternative_part_p Boolean whether or not the code generates a multipart/alternative mail (text/html)
    } {

        # Check if the e-mail is valid, meaning it contains at least an "@" sign
        
        # check, if send_immediately is set
        # if not, take global parameter
        if {$send_immediately_p} {
            set send_p $send_immediately_p
        } else {
            # if parameter is not set, get the global setting
            set send_p [parameter::get -package_id [get_package_id] -parameter "send_immediately" -default 0]
        }

        # if send_p true, then start acs_mail_lite::send_immediately, so mail is not stored in the db before delivery
        if { $send_p } {
            acs_mail_lite::complex_send_immediately \
                -to_party_ids $to_party_ids \
                -cc_party_ids $cc_party_ids \
                -bcc_party_ids $bcc_party_ids \
                -to_group_ids $to_group_ids \
                -cc_group_ids $cc_group_ids \
                -bcc_group_ids $bcc_group_ids \
                -to_addr $to_addr \
                -cc_addr $cc_addr \
                -bcc_addr $bcc_addr \
                -from_addr $from_addr \
                -reply_to $reply_to \
                -subject $subject \
                -body $body \
                -package_id $package_id \
                -files $files \
                -file_ids $file_ids \
                -folder_ids $folder_ids \
                -mime_type $mime_type \
                -object_id $object_id \
                -single_email_p $single_email_p \
                -no_callback_p $no_callback_p \
                -extraheaders $extraheaders \
                -alternative_part_p $alternative_part_p \
                -use_sender_p $use_sender_p
        } else {
            # else, store it in the db and let the sweeper deliver the mail
            set creation_date [clock format [clock seconds] -format "%Y.%m.%d %H:%M:%S"]
            set locking_server ""
            db_dml create_complex_queue_entry {}
        }
    }

    #---------------------------------------
    # complex_send
    # created ... by ...
    # modified 2006/07/25 by nfl: new param. alternative_part_p
    #                             and creation of multipart/alternative    
    # 2006/../.. Renamed to complex_send_immediately
    #---------------------------------------
    ad_proc -public complex_send_immediately {
        -valid_email:boolean
        {-to_party_ids ""}
        {-cc_party_ids ""}
        {-bcc_party_ids ""}
        {-to_addr ""}
        {-cc_addr ""}
        {-bcc_addr ""}
        -from_addr:required
        {-reply_to ""}
        {-subject ""}
        -body:required
        {-package_id ""}
        {-files ""}
        {-file_ids ""}
        {-folder_ids ""}
        {-mime_type "text/plain"}
        {-object_id ""}
        {-single_email_p "1"}
        {-no_callback_p "0"}
        {-extraheaders ""}
        {-alternative_part_p ""}
        {-use_sender_p "0"}
    } {

        Prepare an email to be send immediately with the option to pass in a list
        of file_ids as well as specify an html_body and a mime_type. It also supports multiple "TO" recipients as well as CC
        and BCC recipients. Runs entirely off MIME and SMTP to achieve this. 
        For backward compatibility a switch "single_email_p" is added.

        
        @param to_party_ids list of party ids (including groups) to whom we send this email

        @param cc_party_ids list of party ids (including groups) to whom we send this email in "CC"

        @param bcc_party_ids list of party ids (including groups) to whom we send this email in "BCC"

        @param to_addr List of e-mail addresses to send this mail to. We will figure out the name if possible.

        @param from_addr E-Mail address of the sender. We will try to figure out the name if possible.
        
        @param reply_to E-Mail address to which replies should go. Defaults to from_addr
        
        @param subject of the email
        
        @param body Text body of the email
        
        @param cc_addr List of CC Users e-mail addresses to send this mail to. We will figure out the name if possible. Only useful if single_email is provided. Otherwise the CC users will be send individual emails.

        @param bcc_addr List of CC Users e-mail addresses to send this mail to. We will figure out the name if possible. Only useful if single_email is provided. Otherwise the CC users will be send individual emails.

        @param package_id Package ID of the sending package
        
        @param files List of file_title, mime_type, file_path (as in full path to the file) combination of files to be attached

        @param folder_ids ID of the folder who's content will be send along with the e-mail.

        @param file_ids List of file ids (items or revisions) to be send as attachments. This will only work with files stored in the file system.

        @param mime_type MIME Type of the mail to send out. Can be "text/plain", "text/html".

        @param object_id The ID of the object that is responsible for sending the mail in the first place

        @param extraheaders List of keywords and their values passed in for headers. Interesting ones are: "Precedence: list" to disable autoreplies and mark this as a list message. This is as list of lists !!

        @param single_email_p Indicates that only one mail will be send (in contrast to one e-mail per recipient). Defaults to 1

        @param no_callback_p Indicates if callback should be executed or not. If you don't provide it it will execute callbacks.

        @param use_sender_p Boolean indicating that from_addr should be used regardless of fixed-sender parameter

        @param alternative_part_p Boolean whether or not the code generates a multipart/alternative mail (text/html)
    } {

        set mail_package_id [apm_package_id_from_key "acs-mail-lite"]
        if {$package_id eq ""} {
            set package_id $mail_package_id
        }

	
	###########################################
	#
	# Prepare the sender and reply to address
	#
	###########################################

        # We check if we need to use a fixed sender which overwrites
	# the original sender
        set fixed_sender [parameter::get -parameter "FixedSenderEmail" \
                              -package_id $mail_package_id]

        if { $fixed_sender ne "" && !$use_sender_p} {
            set sender_addr $fixed_sender
        } else {
            set sender_addr $from_addr
        }

        # Get the party_id for the sender
        set party_id($from_addr) [party::get_by_email -email $from_addr]

        # Set the Reply-To
        if {$reply_to eq ""} {
            set reply_to $sender_addr
        }

        # Deal with the sender address. Only change the from string if we find a party_id
        # This should take care of anyone parsing in an email which is already formated with <>.
        set party_id($sender_addr) [party::get_by_email -email $sender_addr]
        if {[exists_and_not_null party_id($sender_addr)]} {
            set from_string "\"[party::name -email $sender_addr]\" <${sender_addr}>"
            set reply_to_string "\"[party::name -email $sender_addr]\" <${reply_to}>"
        } else {
            set from_string $sender_addr
            set reply_to_string $sender_addr
        }


	##########################
	#
	# Prepare the recipients
	#
	##########################

	foreach type [list to cc bcc] {
	    set ${type}_recipient_list [list]
	    
	    foreach email [set ${type}_addr] {
		set party_id($email) [party::get_by_email -email $email]
		if {$party_id($email) eq ""} {
		    # We could not find a party_id, write the email alone

		    set recipient [acs_mail_lite::prepare_recipient -email $email]
		    if {$recipient ne ""} {
			lappend ${type}_recipient_list $recipient
		    }

		} else {	    
		    lappend $party_ids $party_id($email)
		}
	    }

	    # Weed out the duplicates and resolve groups
	    set party_ids [party::resolve_members -party_ids $party_ids]
	    
	    foreach party_id $party_ids {
		set recipient [acs_mail_lite::prepare_recipient -party_id $party_id]
		if {$recipient ne ""} {
		    lappend ${type}_recipient_list $recipient
		}
	    }
	}


	# This part should probably go to a different procedure....

	##################
        # default values for alternative_part_p
        # TRUE on mime_type text/html
        # FALSE on mime_type text/plain
        # if { $alternative_part_p eq "" } {    ...} 
        if { $alternative_part_p eq "" } {
            if { $mime_type eq "text/plain" } {
                set alternative_part_p "0"
            } else {
                set alternative_part_p "1"
            }
        }

	# decision between normal or multipart/alternative body

        # Encode the body with UTF-8 charset
        set charset "UTF-8"
        set encoding [ns_encodingforcharset $charset]
        set body [encoding convertto $encoding $body]

        set multi_token_type ""
        if { $alternative_part_p eq "0"} {
            # Set the message token
            set message_token [mime::initialize -canonical "$mime_type" \
                                   -param [list charset $charset] \
                                   -encoding "quoted-printable" \
                                   -string "$body"]
        } else {
            set multi_token_type "multipart/alternative"

            # build multipart/alternative
            if { $mime_type eq "text/plain" } {
                set message_text_part [mime::initialize -canonical "text/plain" \
                                           -param [list charset $charset] \
                                           -encoding "quoted-printable" \
                                           -string "$body"]
                set converted [ad_text_to_html "$body"]
                set message_html_part [mime::initialize -canonical "text/html" \
                                           -param [list charset $charset] \
                                           -encoding "quoted-printable" \
                                           -string "$converted"]
            } else {
                set message_html_part [mime::initialize -canonical "text/html" \
                                           -param [list charset $charset] \
                                           -encoding "quoted-printable" \
                                           -string "$body"]
                set converted [ad_html_to_text "$body"]
                set message_text_part [mime::initialize -canonical "text/plain" \
                                           -param [list charset $charset] \
                                           -encoding "quoted-printable" \
                                           -string "$converted"]
            }   
            set message_token [mime::initialize -canonical multipart/alternative -parts [list $message_text_part $message_html_part]]
            # see RFC 2046, 5.1.4.  Alternative Subtype, for further information/reference (especially order of parts)  
        }


        # encode all attachments in base64
        
        set tokens [list $message_token]

	#############
	# End of block to go in separate proc
	#############

	# Prepare the attachments
	set attachments [acs_mail_lite::encode_attachments -file_ids $file_ids -folder_ids $folder_ids -files $files]
	set item_ids [lindex $attachments 0]
	set attachment_tokens [lindex $attachments 1]
	set tokens [concat $tokens $attachment_tokens]

	# We have at least one attachment so change the type to multipart/mixed
	if {[llenght $attachment_tokens] > 0} {
	    set multi_token_type "multipart/mixed"
	}

	#####################
	#
	# Compose the e-mail
	#
	#####################

        if { $multi_token_type eq "multipart/mixed" } {
            set multi_token [mime::initialize -canonical $multi_token_type -parts "$tokens"]
        } else {
            set multi_token $tokens
        }

        # Set the message_id
        set message_id "[mime::uniqueID]"
        mime::setheader $multi_token "message-id" "[mime::uniqueID]"
        
        # Set the date
        mime::setheader $multi_token date [build_date]

        # Set the subject
        mime::setheader $multi_token Subject [build_subject $subject]

        foreach header $extraheaders {
            mime::setheader $multi_token "[lindex $header 0]" "[lindex $header 1]"
        }

        set packaged [mime::buildmessage $multi_token]



	###################
	#
	# Send the e-mail
	#
	###################

	
	if {$single_email_p} {
	    
	    #############################
	    # 
	    # One mail to all
	    # 
	    #############################
	    
	    # Resolve the various types into two lists
	    # so we have the emails in one and the 
	    # party_ids in the other (needed for the callback)
	    
	    foreach type [list to cc bcc] {		    
		set addr_list [list]
		set ${type}_party_ids [list]
		
		foreach recipient [set ${type}_recipient_list] {
		    lappend ${type}_party_ids [lindex $recipient 0]
		    lappend addr_list [lindex $recipient 1]			
		}
		
		set ${type}_addr_string [join $addr_list ","]
	    }
	    
	    # Send out the E-Mail
	    acs_mail_lite::complex_smtp -multi_token $multi_token \
		-headers [list [list From "$from_string"] [list Reply-To "$reply_to_string"] \
			      [list To "$to_addr_string ","]"] [list CC "[join $cc_addr_string ","]"] \
			      [list BCC "[join $bcc_addr_string ","]"]]
	    
	    #Close all mime tokens
	    mime::finalize $multi_token -subordinates all
	    
	    if { !$no_callback_p } {
		# First join the emails without parties for the callback.
		callback acs_mail_lite::complex_send \
		    -package_id $package_id \
		    -from_party_id [party::get_by_email -email $sender_addr] \
		    -from_addr $sender_addr \
		    -to_party_ids $to_party_ids \
		    -cc_party_ids $cc_party_ids \
		    -bcc_party_ids $bcc_party_ids \
		    -to_addr $to_addr_string \
		    -cc_addr $cc_addr_string \
		    -bcc_addr $bcc_addr_string \
		    -body $body \
		    -message_id $message_id \
		    -subject $subject \
		    -object_id $object_id \
		    -file_ids $item_ids
	    }
	    
	    
	} else {
	    
	    ####################################################################
	    # 
	    # Individual E-Mails. 
	    # All recipients, (regardless who they are) get a separate E-Mail
	    #
	    ####################################################################
	    
	    # We send individual e-mails. 
	    set recipient_list [concat $to_recipient_list $cc_recipient_list $bcc_recipient_list]
	    
	    foreach recipient $recipient_list {
		set party_id [lindex $recipient 0]
		set address [lindex $recipient 1]
		set message_id [mime::uniqueID]
		acs_mail_lite::complex_smtp -multi_token $multi_token \
		    -headers [list [list From "$from_string"] [list Reply-To "$reply_to_string"] [list To "$address"]]
		if { !$no_callback_p } {
		    # If we have a party_id record only the
		    # party_id
		    if {$party_id ne ""} {
			set address ""
		    }
		    
		    callback acs_mail_lite::complex_send \
			-package_id $package_id \
			-from_party_id [party::get_by_email -email $sender_addr] \
			-from_addr $from_addr \
			-to_addr $address \
			-to_party_ids $party_id \
			-body $body \
			-message_id $message_id \
			-subject $subject \
			-object_id $object_id \
			-file_ids $item_ids
		}
	    }
	    
	    #Close all mime tokens
	    mime::finalize $multi_token -subordinates all
	}
    }	    


    #---------------------------------------
    # 2006/11/17 Created by cognovis/nfl
    #            nsv_incr description: http://www.panoptic.com/wiki/aolserver/Nsv_incr
    #---------------------------------------    
    ad_proc -private complex_sweeper {} {
        Send messages in the acs_mail_lite_complex_queue table.
    } {
        # Make sure that only one thread is processing the queue at a time.
        if {[nsv_incr acs_mail_lite complex_send_mails_p] > 1} {
            nsv_incr acs_mail_lite complex_send_mails_p -1
            return
        }

        with_finally -code {
            db_foreach get_complex_queued_messages {} {
                # check if record is already there and free to use
                set return_id [db_string get_complex_queued_message {} -default -1]
                if {$return_id == $id} {
                    # lock this record for exclusive use
                    set locking_server [ad_url]
                    db_dml lock_queued_message {}
                    # send the mail
                    set err [catch {
                        acs_mail_lite::complex_send_immediately \
                            -to_party_ids [concat $to_party_ids $to_group_ids]\
                            -cc_party_ids [concat $cc_party_ids $cc_group_ids] \
                            -bcc_party_ids [concat $bcc_party_ids $bcc_group_ids] \
                            -to_addr $to_addr \
                            -cc_addr $cc_addr \
                            -bcc_addr $bcc_addr \
                            -from_addr $from_addr \
                            -reply_to $reply_to \
                            -subject $subject \
                            -body $body \
                            -package_id $package_id \
                            -files $files \
                            -file_ids $file_ids \
                            -folder_ids $folder_ids \
                            -mime_type $mime_type \
                            -object_id $object_id \
                            -single_email_p $single_email_p \
                            -no_callback_p $no_callback_p \
                            -extraheaders $extraheaders \
                            -alternative_part_p $alternative_part_p \
                            -use_sender_p $use_sender_p        
                    } errMsg]
                    if {$err} {
                        ns_log Error "Error while sending queued complex mail: $errMsg"
                        # release the lock
                        set locking_server ""
                        db_dml lock_queued_message {}    
                    } else {
                        # mail was sent, delete the queue entry
                        db_dml delete_complex_queue_entry {}
                    }
                }
            }
        } -finally {
            nsv_incr acs_mail_lite complex_send_mails_p -1
        }
    }      
    
    ad_proc -private encode_attachments {
	{-file_ids ""}
	{-folder_ids ""}
	{-files ""}
    } {
	This procedure takes files and folders and returns a list of
	item_ids if possible and the list of tokens
	
        @param files List of file_title, mime_type, file_path (as in full path to the file) combination of files to be attached

        @param folder_ids ID of the folder who's content will be send along with the e-mail.

        @param file_ids List of file ids (items or revisions) to be send as attachments. This will only work with files stored in the file system.

	@return list of the list of item_ids and tokens
    } {
        set item_ids [list]
	set tokens [list]

        if {[exists_and_not_null file_ids]} {

            # Check if we are dealing with revisions or items.
            foreach file_id $file_ids {
                set item_id [content::revision::item_id -revision_id $file_id]
                if {$item_id eq ""} {
                    lappend item_ids $file_id
                } else {
                    lappend item_ids $item_id
                }
            }

            db_foreach get_file_info "select r.mime_type,r.title, r.content as filename
	           from cr_revisions r, cr_items i
	           where r.revision_id = i.latest_revision
                   and i.item_id in ([join $item_ids ","])" {
                       lappend tokens [mime::initialize -param [list name "[ad_quotehtml $title]"] -header [list "Content-Disposition" "attachment; filename=$title"] -header [list Content-Description $title] -canonical $mime_type -file "[cr_fs_path]$filename"]
                   }
        }


        # Append files from the filesystem
        if {$files ne ""} {
            foreach file $files {
                lappend tokens [mime::initialize -param [list name "[ad_quotehtml [lindex $file 0]]"] -canonical [lindex $file 1] -file "[lindex $file 2]"]
            }
        }

        # Append folders
        if {[exists_and_not_null folder_ids]} {
            
            foreach folder_id $folder_ids {
                db_foreach get_file_info {select r.revision_id,r.mime_type,r.title, i.item_id, r.content as filename
                    from cr_revisions r, cr_items i
                    where r.revision_id = i.latest_revision and i.parent_id = :folder_id} {
                        lappend tokens [mime::initialize -param [list name "[ad_quotehtml $title]"] -canonical $mime_type -file "[cr_fs_path]$filename"]
                        lappend item_ids $item_id
                    }
            } 
        }
	return [list $item_ids $tokens]
    }

    ad_proc -private prepare_recipient {
	{-email ""}
	{-party_id}
    } {
	Returns the formated string for e-mail headers of the recipient
	along with the party_id. It will try to find out the name
	and party_id if possible. It also checks if the e-mail is valid
	
	@param email The email address of the recipient
	@param party_id The party_id of the recipient
	@return List of party_id and string for the e-mail inclusion. Empty string is returned if the email is invalid.
    } {
	if {$email ne ""} {
            set party_id [party::get_by_email -email $email]
	} else {
	    set email [party::email_not_cached -party_id $party_id]
	} 

        if {[acs_mail_lite::valid_email_p $email]} {
	    if {$party_id eq ""} {
		# We could not find a party_id, write the email alone
		return [list "" $email]
	    } else {	    
		return [list $party_id "\"[party::name -party_id $party_id]\" <$email>"]
	    }
	} else {
	    acs_mail_lite::record_bounce -email $email
	    return ""
	}
    }

    ad_proc -private prepare_recipients {
	{-emails ""}
	{-party_ids ""}
    } {
	Receive a list of emails and party_ids and return the formated 
	string with the names to be used 
    }

	
    ad_proc -private complex_smtp {
        -multi_token:required
        -headers:required
    } {
        Send messages via SMTP. Takes care of rollout support
        
        @param multi_token Multi Token generated which is passed directly to smtp::sendmessage
        @param headers List of list of header key-value pairs like {{from malte@cognovis.de} {to malte@cognovis.de}}
    } {

        set mail_package_id [apm_package_id_from_key "acs-mail-lite"]

        # Get the SMTP Parameters
    	set smtp [parameter::get -parameter "SMTPHost" \
                      -package_id $mail_package_id -default [ns_config ns/parameters mailhost]]
    	if {$smtp eq ""} {
    	    set smtp localhost
    	}

    	set timeout [parameter::get -parameter "SMTPTimeout" \
                         -package_id $mail_package_id -default  [ns_config ns/parameters smtptimeout]]
    	if {$timeout eq ""} {
    	    set timeout 60
    	}

    	set smtpport [parameter::get -parameter "SMTPPort" \
                          -package_id $mail_package_id -default 25]

    	set smtpuser [parameter::get -parameter "SMTPUser" \
                          -package_id $mail_package_id]

    	set smtppassword [parameter::get -parameter "SMTPPassword" \
                              -package_id $mail_package_id]
    	

	# Rollout support
	switch $delivery_mode {
	    log {ns_log Notice "Sending E-Mail to headers $headers $multitoken"}
	    redirect {
		set redirect_address [ns_config ns/server/[ns_info server]/acs/acs-rollout-support EmailRedirectTo] 
		eval "smtp::sendmessage $multitoken -header [list From "$from_string"] -header [list Reply-To "$reply_to_string"] -header [list To "$redirect_address"]]"
	    }
	    filter {
		# No idea how to do this
	    }
	    default {
		set cmd_string "smtp::sendmessage $multi_token"     
		foreach header $headers {
		    append cmd_string " -header {$header}"
		}
		append cmd_string " -servers $smtp -ports $smtpport -username $smtpuser -password $smtppassword"
		eval $cmd_string
		ns_log Debug "complex-send cmd_string: $cmd_string"
	    }
	} 
    	
    }

	
    ad_proc -public valid_email_p {
        {-email ""}
    } {
        Checks if the email is valid. Returns 1 if it is. Uses mime::parsemail to determine this
    } {
        array set test [lindex [mime::parseaddress "$email"] 0]
        if {$email ne $test(proper)} {
            regsub "\"" $test(proper) "" proper
            if {$email ne $proper} {
                return 0
            } else {
                return 1
            }
        } else {
            return 1
        }
    }
}
