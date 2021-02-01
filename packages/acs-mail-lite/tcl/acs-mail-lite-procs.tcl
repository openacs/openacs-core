ad_library {

    Provides a simple API for reliably sending email.

    @author Eric Lorenzo (eric@openforce.net)
    @creation-date 22 March 2002
    @cvs-id $Id$
}

package require mime 1.4
package require smtp 1.4
# package require base64 2.3.1

namespace eval acs_mail_lite {

    ad_proc -public get_package_id {} {
        @return package_id of this package
    } {
        return [apm_package_id_from_key acs-mail-lite]
    }

    ad_proc -deprecated -public get_parameter {
        -name:required
        {-default ""}
    } {
        Returns an apm-parameter value of this package

        Deprecated: just a wrapper for parameter::get

        @option name parameter name
        @option default default parameter value
        @return apm-parameter value of this package
        @see parameter::get
    } {
        return [parameter::get \
                    -package_id [get_package_id] \
                    -parameter $name \
                    -default $default]
    }

    ad_proc -private mail_dir {} {
        @return incoming mail directory to be scanned for bounces
    } {
        return [parameter::get \
                    -package_id [get_package_id] \
                    -parameter "BounceMailDir" \
                    -default ""]
    }

    #---------------------------------------
    ad_proc -public parse_email_address {
        -email:required
    } {
        Extracts the email address out of a mail address (like Joe User <joe@user.com>)
        @option email mail address to be parsed
        @return only the email address part of the mail address
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
        @return valid message-id for mail header
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
        Validates if provided signature matches message_id.

        @option signature signature to be checked
        @option msg message-id that the signature should be checked against
        @return boolean 0 or 1
    } {
        if {![regexp "(<\[\-0-9\]+\\.\[0-9\]+\\.oacs@[address_domain]>)" $message_id match id]
            || $signature ne [ns_sha1 $id]
        } {
            # either couldn't find message-id or signature doesn't match
            return 0
        }
        return 1
    }

    #---------------------------------------
    ad_proc -private get_delivery_parameters {} {
        Get the SMTP Parameters and return these as a dict.

        @return dict with keys identical to the package parameters
    } {
        set mail_package_id [get_package_id]

        set smtpHost [parameter::get -parameter "SMTPHost" \
                      -package_id $mail_package_id \
                      -default [ns_config ns/parameters mailhost]]
        if {$smtpHost eq ""} {
            set smtpHost localhost
        }

        set timeout [parameter::get -parameter "SMTPTimeout" \
                         -package_id $mail_package_id \
                         -default  [ns_config ns/parameters smtptimeout]]
        if {$timeout eq ""} {
            set timeout 60
        }

        set smtpPort [parameter::get -parameter "SMTPPort" \
                          -package_id $mail_package_id \
                          -default 25]

        set smtpUser [parameter::get -parameter "SMTPUser" \
                          -package_id $mail_package_id]

        set smtpPassword [parameter::get -parameter "SMTPPassword" \
                              -package_id $mail_package_id]

        set deliveryMode [parameter::get \
                               -package_id $mail_package_id \
                               -parameter EmailDeliveryMode \
                               -default default]
        return [list \
                    SMTPHost $smtpHost \
                    SMTPTimeout $timeout \
                    SMTPPort $smtpPort \
                    SMTPUser $smtpUser \
                    SMTPPassword $smtpPassword \
                    EmailDeliveryMode $deliveryMode]
    }


    #---------------------------------------
    ad_proc -private smtp {
        -multi_token:required
        -headers:required
        -originator:required
        -delivery_dict:required
    } {
        Send messages via SMTP

        @param multi_token Multi Token generated which is passed
               directly to smtp::sendmessage

        @param headers List of list of header key-value pairs like
               {{from malte@cognovis.de} {to malte@cognovis.de}}

        @param delivery_dict dictionary of delivery parameters
               including the SMTP* configurtion parameters

    } {

        # Consider adding code here to
        # set orignator to acs-mail-lite parameter FixedSenderEmail
        # if FixedSenderEmail is not empty,
        # so as to be consistent for all cases calling this proc.

        set cmd [list smtp::sendmessage $multi_token -originator $originator]
        foreach header $headers {
            lappend cmd -header $header
        }
        lappend cmd \
            -servers [dict get $delivery_dict SMTPHost] \
            -ports [dict get $delivery_dict SMTPPort]

        #
        # Request authentication only, when user AND password are
        # specified. If only one of these is specified, issue a
        # warning and ignore the parameter.
        #
        set smtpUser [dict get $delivery_dict SMTPUser]
        set smtpPassword [dict get $delivery_dict SMTPPassword]
        if {$smtpUser ne "" && $smtpPassword ne "" } {
            lappend cmd -username $smtpUser -password $smtpPassword
        } elseif {$smtpUser ne ""|| $smtpPassword ne ""} {
            ns_log warning "acs-mail-lite::smtp: invalid parameter combination;\
                when SMTPUser is specified, SMTPPassword has to be provided as well and vice versa"
        }

        ns_log Debug "send cmd: $cmd"
        if {[catch $cmd errorMsg]} {
            ns_log Error "acs-mail-lite::smtp: error $errorMsg while executing\n$cmd"
            error $errorMsg
        }
    }

    #---------------------------------------
    ad_proc -private get_address_array {
        -addresses:required
    } {
        Checks if passed variable is already an array of emails,
        user_names and user_ids. If not, get the additional data
        from the db and return the full array.
        @option addresses variable to checked for array
        @return array of emails, user_names and user_ids to be used
        for the mail procedures
    } {
        if {[catch {array set address_array $addresses}]
            || [lsort [array names address_array]] ne [list email name user_id]
        } {
            #
            # Either user just passed a normal address-list or
            # user passed an array, but forgot to provide user_ids
            # or user_names, so we have to get this data from the db
            #
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
                if {[db_0or1row get_user_name_and_id {
                    select person_id as user_id, first_names || ' ' || last_name as user_name
                    from parties, persons
                    where email = :email
                      and party_id = person_id
                     order by party_id desc
                    fetch first 1 rows only
                }]} {
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
        {-mime_type "text/plain"}
        {-cc_addr ""}
        {-bcc_addr ""}
        {-reply_to ""}
        {-package_id ""}
        -no_callback:boolean
        {-file_ids ""}
        {-filesystem_files ""}
        -delete_filesystem_files:boolean
        {-extraheaders ""}
        -use_sender:boolean
        {-object_id ""}
    } {

        Prepare an email to be send with the option to pass in a list
        of file_ids as well as specify an html_body and a mime_type. It
        also supports multiple "TO" recipients as well as CC
        and BCC recipients. Runs entirely off MIME and SMTP to achieve this.

        @param send_immediately The email is send immediately and not
               stored in the acs_mail_lite_queue

        @param to_addr List of e-mail addresses to send this mail to.

        @param from_addr E-Mail address of the sender.

        @param subject of the email

        @param body Text body of the email

        @param cc_addr List of CC Users e-mail addresses to send this mail to.

        @param bcc_addr List of CC Users e-mail addresses to send this mail to.

        @param package_id Package ID of the sending package

        @param file_ids List of file ids (items or revisions) to be
               send as attachments. This will only work with files stored in
               the file-storage.

        @param filesystem_files List of regular files on the
               filesystem to be send as attachments.

        @param delete_filesystem_files_p Decides if we want files specified
               by the 'file' parameter to be deleted once sent.

        @param mime_type MIME Type of the mail to send out. Can be
               "text/plain", "text/html".

        @param extraheaders List of keywords and their values passed
               in for headers. Interesting ones are: "Precedence:
               list" to disable autoreplies and mark this as a list
               message. This is as list of lists !!

        @param no_callback Boolean that indicates if callback should
               be executed or not. If you don't provide it it will
               execute callbacks

        @param use_sender Boolean indicating that from_addr should be
               used regardless of fixed-sender parameter

    } {
        #
        # Check, if send_immediately is set if not, take global
        # parameter.
        #
        if { !$send_immediately_p } {
            set send_immediately_p [parameter::get \
                                        -package_id [get_package_id] \
                                        -parameter "send_immediately" \
                                        -default 0]
        }

        #
        # If send_immediately_p true, then start
        # acs_mail_lite::send_immediately, so mail is not stored in
        # the db before delivery.
        #
        if { $send_immediately_p } {
            acs_mail_lite::send_immediately \
                -to_addr $to_addr \
                -cc_addr $cc_addr \
                -bcc_addr $bcc_addr \
                -from_addr $from_addr \
                -reply_to $reply_to \
                -subject $subject \
                -body $body \
                -package_id $package_id \
                -file_ids $file_ids \
                -filesystem_files $filesystem_files \
                -delete_filesystem_files_p $delete_filesystem_files_p \
                -mime_type $mime_type \
                -no_callback_p $no_callback_p \
                -extraheaders $extraheaders \
                -use_sender_p $use_sender_p \
                -object_id $object_id
        } else {
            # else, store it in the db and let the sweeper deliver the mail
            set creation_date [clock format [clock seconds] -format "%Y.%m.%d %H:%M:%S"]
            set locking_server ""
            db_dml create_queue_entry {}
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

        ad_try {
            db_foreach get_queued_messages {} {
                # check if record is already there and free to use
                set return_id [db_string get_queued_message {} -default -1]
                if {$return_id == $id} {
                    # lock this record for exclusive use
                    set locking_server [ad_url]
                    db_dml lock_queued_message {}
                    # send the mail
                    ad_try {
                        acs_mail_lite::send_immediately \
                            -to_addr $to_addr \
                            -cc_addr $cc_addr \
                            -bcc_addr $bcc_addr \
                            -from_addr $from_addr \
                            -reply_to $reply_to \
                            -subject $subject \
                            -body $body \
                            -package_id $package_id \
                            -object_id $object_id \
                            -file_ids $file_ids \
                            -filesystem_files $filesystem_files \
                            -delete_filesystem_files_p $delete_filesystem_files_p \
                            -mime_type $mime_type \
                            -no_callback_p $no_callback_p \
                            -extraheaders $extraheaders \
                            -use_sender_p $use_sender_p
                    } on error {errorMsg} {
                        ad_log Error "Could not send queued mail (message $return_id): $errorMsg"
                        # release the lock (MS not now)
                        # set locking_server ""
                        # db_dml lock_queued_message {}
                    } on ok {r} {
                        # mail was sent, delete the queue entry
                        db_dml delete_queue_entry {}
                    }
                }
            }
        } finally {
            nsv_incr acs_mail_lite send_mails_p -1
        }
    }

    #---------------------------------------
    ad_proc -private send_immediately {
        {-valid_email_p "0"}
        -to_addr:required
        {-cc_addr ""}
        {-bcc_addr ""}
        -from_addr:required
        {-reply_to ""}
        {-subject ""}
        -body:required
        {-package_id ""}
        {-file_ids ""}
        {-filesystem_files ""}
        {-delete_filesystem_files_p "0"}
        {-mime_type "text/plain"}
        {-no_callback_p "0"}
        {-extraheaders ""}
        {-use_sender_p "0"}
        {-object_id ""}
        {-force_delivery_mode ""}
    } {

        Prepare an email to be send immediately with the option to pass in a list
        of file_ids as well as specify an html_body and a mime_type. It also supports
        multiple "TO" recipients as well as CC
        and BCC recipients. Runs entirely off MIME and SMTP to achieve this.

        @param to_addr List of e-mail addresses to send this mail to.

        @param from_addr E-Mail address of the sender.

        @param reply_to E-Mail address to which replies should
               go. Defaults to from_addr

        @param subject of the email

        @param body Text body of the email

        @param cc_addr List of CC Users e-mail addresses to send this
               mail to.

        @param bcc_addr List of CC Users e-mail addresses to send this
               mail to.

        @param package_id Package ID of the sending package

        @param file_ids List of file ids (items or revisions) to be
               send as attachments. This will only work with files
               stored in the file-storage.

        @param filesystem_files List of regular files on the
               filesystem to be send as attachments.

        @param delete_filesystem_files_p Decides if we want files
               specified by the 'file' parameter to be deleted once
               sent.

        @param mime_type MIME Type of the mail to send out. Can be
               "text/plain", "text/html".

        @param extraheaders List of keywords and their values passed
               in for headers. Interesting ones are: "Precedence:
               list" to disable autoreplies and mark this as a list
               message. This is as list of lists !!

        @param no_callback_p Indicates if callback should be executed
               or not. If you don't provide it it will execute
               callbacks.

        @param use_sender_p Boolean indicating that from_addr should
               be used regardless of fixed-sender parameter

        @param object_id Object id that caused this email to be sent

        @param force_delivery_mode Force the specified delivery mode
               for this single call
    } {

        set mail_package_id [get_package_id]
        if {$package_id eq ""} {
            set package_id $mail_package_id
        }

        # Decide which sender to use
        set fixed_sender [parameter::get \
                              -parameter "FixedSenderEmail" \
                              -package_id $mail_package_id]

        if { $fixed_sender ne "" && !$use_sender_p} {
            set from_addr $fixed_sender
        }

        # Set the Reply-To
        if {$reply_to eq ""} {
            set reply_to $from_addr
        }

        # Get any associated data indicating need to sign message-id

        # associate a user_id
        set rcpt_id 0
        if { [llength $to_addr] == 1 } {
            set rcpt_id [party::get_by_email -email $to_addr]
            if {$rcpt_id eq ""} {
                set rcpt_id 0
            }
        }


        # Set the message_id
        # message-id gets signed if parameter defaults not passed
        set message_id [acs_mail_lite::unique_id_create \
                            -object_id $object_id \
                            -package_id $package_id \
                            -party_id $rcpt_id]


        # Set originator header
        set originator_email [parameter::get \
                                  -parameter "OriginatorEmail" \
                                  -package_id $mail_package_id]

        # Decision based firstly on parameter,
        # and then on other values that most likely could be substituted
        # with initial choice, and while meeting definition
        # of originator header according to RFC 2822 section 3.6.2
        # https://tools.ietf.org/html/rfc2822#section-3.6.2
        # A value must be provided.
        switch -exact -- $originator_email {
            fixed_sender {
                if { $fixed_sender ne "" } {
                    set originator $fixed_sender
                } elseif { $from_addr ne "" } {
                    set originator $from_addr
                } else {
                    set originator $message_id
                }
            }
            from_address {
                if { $from_addr ne "" } {
                    set originator $from_addr
                } elseif { $fixed_sender ne "" } {
                    set originator $fixed_sender
                } else {
                    set originator $message_id
                }
            }
            message_id {
                set originator $message_id
            }
            reply_to {
                if { $reply_to ne "" } {
                    set originator $reply_to
                } elseif { $from_addr ne "" } {
                    set originator $from_addr
                } else {
                    set originator $message_id
                }
            }
            bounce_address -
            default {
                # Build the originator address to be used as envelope sender
                # and originator etc.
                set originator [bounce_address -user_id $rcpt_id \
                                   -package_id $package_id \
                                   -message_id $message_id]
            }
        }

        # Set the date
        set message_date [acs_mail_lite::utils::build_date]

        # Build the message body
        set tokens [acs_mail_lite::utils::build_body \
                        -mime_type $mime_type -- $body]

        # Add attachments if any
        # ...from file-storage
        if {$file_ids ne ""} {
            set item_ids [list]

            # Check if we are dealing with revisions or items.
            foreach file_id $file_ids {
                set item_id [content::revision::item_id -revision_id $file_id]
                if {$item_id eq ""} {
                    lappend item_ids $file_id
                } else {
                    lappend item_ids $item_id
                }
            }

            db_foreach get_file_info {} {
                lappend tokens [mime::initialize \
                                    -param [list name [ns_quotehtml $title]] \
                                    -header [list Content-Disposition "attachment; filename=\"$name\""] \
                                    -header [list Content-Description $title] \
                                    -canonical $mime_type \
                                    -file "[cr_fs_path]$filename"]
            }
        }

        # ...from filesystem
        if {$filesystem_files ne ""} {
            # get root of folders into which files are allowed to be sent
            set filesystem_attachments_root [parameter::get \
                                                 -parameter "FilesystemAttachmentsRoot" \
                                                 -package_id $mail_package_id \
                                                 -default ""]
            if {$filesystem_attachments_root eq ""} {
                # on a unix system this could be '/tmp'
                set filesystem_attachments_root [ad_tmpdir]
            }
            foreach f $filesystem_files {
                # make the filename absolute
                if {[file pathtype $f] ne "absolute"} {
                    set f [file join [pwd] $f]
                }
                if {![file exists $f]} {
                    ns_log Error "acs-mail-lite::send: Could not send mail: file '$f' does not exist"
                    return
                }
                if {[string first $filesystem_attachments_root $f] != 0} {
                    ns_log Error "acs-mail-lite::send: Could not send mail: file '$f'\
                           is outside the allowed root folder for attachments\
                           '$filesystem_attachments_root'"
                    return
                }
                set name [file tail $f]
                set mime_type [cr_filename_to_mime_type $name]
                lappend tokens [mime::initialize \
                                    -param [list name $name] \
                                    -header [list Content-Disposition "attachment; filename=\"$name\""] \
                                    -header [list Content-Description $name] \
                                    -canonical $mime_type \
                                    -file $f]
            }
        }

        if {$file_ids ne "" || $filesystem_files ne ""} {
            set tokens [mime::initialize -canonical "multipart/mixed" -parts $tokens]
        }

        ### Add the headers

        mime::setheader $tokens "message-id" $message_id
        mime::setheader $tokens date $message_date

        # Set the subject
        if { $subject ne "" } {
            set encoded_subject [acs_mail_lite::utils::build_subject -- $subject]
            mime::setheader $tokens Subject $encoded_subject
        }

        # Add extra headers
        foreach header $extraheaders {
            mime::setheader $tokens [lindex $header 0] [lindex $header 1]
        }

        # Get the delivery parameters, includeing SMTP
        set deliveryDict [get_delivery_parameters]

        # Rollout support
        set default_send_mode smtp

        if {$force_delivery_mode ne ""} {
            set delivery_mode $force_delivery_mode
        } else {
            set delivery_mode [dict get $deliveryDict EmailDeliveryMode]
        }

        foreach w $delivery_mode {
            if {$w ni {smtp nssmtpd default log redirect ignore}} {
                ns_log warning "unexpected entry '$w' in parameter EmailDeliveryMode (ignored)"
            }
        }

        if {"nssmtpd" in $delivery_mode} {
            #
            # Filter the word "nssmtpd" from the EmailDeliveryMode and
            # try to use "nssmtpd" as default_send mode
            #
            if {[llength $delivery_mode] > 1} {
                # Filter "nssmtpd" from the list
                set delivery_mode [lmap m $delivery_mode {
                    if {$m eq "nssmtpd"} continue
                    set m
                }]
            }
            #
            # "ns_smtpd" can be used, when it is available and no
            # password mode is specified.
            #
            if { [namespace which ns_smtpd] eq ""
                 || [dict get $deliveryDict SMTPPassword] ne ""
                 || [dict get $deliveryDict SMTPUser] ne ""
             } {
                ns_log warning "configured 'nssmtp' as EmailDeliveryMode but it can't be used."
             } else {
                 set default_send_mode nssmtpd
             }
        }

        switch -- $delivery_mode {
            log {
                set send_mode "log"
                set notice "logging email instead of sending"
            }
            filter {
                set send_mode $default_send_mode
                set allowed_addr [parameter::get \
                                      -package_id $mail_package_id \
                                      -parameter EmailAllow]

                foreach recipient [concat $to_addr $cc_addr $bcc_addr] {

                    # if any of the recipient is not in the allowed list
                    # email message has to be sent to the log instead

                    if {$recipient ni $allowed_addr} {
                        set send_mode "log"
                        set notice "logging email because one of the recipient ($recipient) is not in the EmailAllow list"
                        break
                    }
                }

            }
            redirect {
                set send_mode $default_send_mode

                set redirect_to [parameter::get \
                                 -package_id $mail_package_id \
                                 -parameter EmailRedirectTo]
                if {$redirect_to eq ""} {
                    ns_log warning "acs-mail-lite: redirect mode activated but no value for\
                       EmailRedirectTo provided"
                    set send_mode ignore
                } else {
                    set to_addr $redirect_to

                    # Since we have to redirect to a list of addresses
                    # we need to remove the CC and BCC
                    set cc_addr ""
                    set bcc_addr ""
                }
            }
            default {
                set send_mode $default_send_mode
            }
        }

        # Prepare the headers list of recipients
        set headers_list [list [list From $from_addr] \
                              [list Reply-To $reply_to] \
                              [list To [join $to_addr ","]]]

        if { $cc_addr ne "" } {
            lappend headers_list [list CC [join $cc_addr ","]]
        }

        if { $bcc_addr ne ""} {

            # BCC implementation in tcllib 1.8 to 1.11 is awkward. It
            # sends the blind copy as an attachment, changes the From
            # header replacing it with the originator, etc. So we use
            # DCC instead which behaves as one would expect Bcc to
            # behave.

            lappend headers_list [list DCC [join $bcc_addr ","]]
        }

        set errorMsg ""
        set status ok

        if {$send_mode eq "nssmtpd"} {

            foreach header $headers_list {
                mime::setheader $tokens [lindex $header 0] [lindex $header 1]
            }
            set fullMailMessage [mime::buildmessage $tokens]

            #
            # Call "ns_smtpd send" from the NaviServer nssmtpd module.
            # When the last two arguments are not provided, the
            # command uses host and port from the configuration
            # section of the nssmtpd module.
            #
            try {
                ns_smtpd send $originator $to_addr fullMailMessage \
                    [dict get $deliveryDict SMTPHost] \
                    [dict get $deliveryDict SMTPPort]
            } on error {errorMsg} {
                set status error
            }

        } elseif { $send_mode eq "log" } {

            # Add recipients to headers
            foreach header $headers_list {
                mime::setheader $tokens [lindex $header 0] [lindex $header 1]
            }

            # Retrieve the email message as a string
            set packaged [mime::buildmessage $tokens]

            # Send the email message to the log
            ns_log Notice "acs-mail-lite::send: $notice\n\n**********\n\
                Envelope sender: $originator\n\n$packaged\n**********"

        } elseif {$send_mode eq "smtp"} {

            ad_try {
                acs_mail_lite::smtp -multi_token $tokens \
                    -headers $headers_list \
                    -originator $originator \
                    -delivery_dict $deliveryDict
            } on error {errorMsg} {
                set status error
            }

        } else {
            #
            # Ignoring sending message
            #
            ns_log warning "acs-mail-lite::send: ignore sending message to $to_addr"
        }

        #
        # Close all mime tokens
        #
        mime::finalize $tokens -subordinates all


        if { !$no_callback_p } {
            callback acs_mail_lite::send \
                -package_id $package_id \
                -message_id $message_id \
                -from_addr $from_addr \
                -to_addr $to_addr \
                -body $body \
                -mime_type $mime_type \
                -subject $subject \
                -cc_addr $cc_addr \
                -bcc_addr $bcc_addr \
                -file_ids $file_ids \
                -filesystem_files $filesystem_files \
                -delete_filesystem_files_p $delete_filesystem_files_p \
                -object_id $object_id \
                -status $status \
                -errorMsg $errorMsg
        }

        # Attachment files can now be deleted, if so required.
        # I leave this as the last thing to do, because callbacks
        # could need to look at files for their own purposes.
        if {[string is true $delete_filesystem_files_p]} {
            foreach f $filesystem_files {
            file delete -- $f
            }
        }
        if {$status ne "ok"} {
            error $errorMsg
        }
    }

    #---------------------------------------
    ad_proc -private message_interpolate {
        {-values:required}
        {-text:required}
    } {
        Interpolates a set of values into a string. This is directly
        copied from the bulk mail package.

        @param values a list of key, value pairs, each one consisting of a
        target string and the value it is to be replaced with.
        @param text the string that is to be interpolated

        @return the interpolated string
    } {
        foreach pair $values {
            regsub -all -- [lindex $pair 0] $text [lindex $pair 1] text
        }
        return $text
    }

    #---------------------------------------

    ad_proc -public -deprecated ::ns_sendmail {
        to
        from
        subject
        body
        {extraheaders {}}
        {bcc {}}
    } {

        Replacement for ns_sendmail for backward compatibility.

    } {

        ns_log warning "ns_sendmail is deprecated. Use acs_mail_lite::send instead."

        set extraheaders_list [list]

        if { $extraheaders ne "" } {
            foreach {key value} [util_ns_set_to_list -set $extraheaders] {
                lappend extraheaders_list [list $key $value]
            }
        }

        acs_mail_lite::send \
            -to_addr [split $to ","] \
            -from_addr $from \
            -subject $subject \
            -body $body \
            -bcc_addr [split $bcc ","] \
            -extraheaders $extraheaders_list
    }

    ad_proc -public address_domain {} {
        @return domain address to which bounces are directed to.
        If empty, uses domain from FixedSenderEmail parameter,
        otherwise the hostname in config.tcl is used.
    } {
        set domain [parameter::get_from_package_key \
                        -package_key "acs-mail-lite" \
                        -parameter "BounceDomain"]
        if { $domain eq "" } {
            # Assume a FixedSenderEmail domain, if it exists.
            set email [parameter::get_from_package_key \
                           -package_key "acs-mail-lite" \
                           -parameter "FixedSenderEmail"]
            if { $email ne "" } {
                set domain [string range $email [string last "@" $email]+1 end]
            } else {
                #
                # If there is no domain configured, use the configured
                # hostname as domain name
                #
                foreach driver {nsssl nssock_v4 nssock_v6 nssock} {
                    set section [ns_driversection -driver $driver]
                    set configured_hostname [ns_config $section hostname]
                    if {$configured_hostname ne ""} {
                        set domain $configured_hostname
                        break
                    }
                }
            }
        }
        return $domain
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
