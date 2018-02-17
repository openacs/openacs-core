ad_library {

    Provides API for importing email via postfix maildir
    
    @creation-date 12 Oct 2017
    @cvs-id $Id$

}

namespace eval acs_mail_lite {}

ad_proc -private acs_mail_lite::maildir_check_incoming {
} {
    Checks for new, actionable incoming email via Postfix MailDir standards.
    Email is actionable if it is identified by acs_mail_lite::email_type.

    When actionable, email is buffered in table acs_mail_lite_from_external
    and callbacks are triggered.

    @see acs_mail_lite::email_type

} {
    set error_p 0
    set mail_dir_fullpath [acs_mail_lite::mail_dir]
    if { $mail_dir_fullpath ne "" } {
        

        set newdir [file join $mail_dir_fullpath new "*"]
        set curdir [file join $mail_dir_fullpath cur "."]

        set messages_list [glob -nocomplain $newdir]
        
        # only one of acs_mail_lite::maildir_check_incoming process at a time.
        set cycle_start_cs [clock seconds]
        nsv_lappend acs_mail_lite sj_actives_list $cycle_start_cs
        set sj_actives_list [nsv_get acs_mail_lite sj_actives_list]
        ns_log Notice "acs_mail_lite::maildir_check_incoming.37. start \
 sj_actives_list '${sj_actives_list}'"
        
        set active_cs [lindex $sj_actives_list end]
        set concurrent_ct [llength $sj_actives_list]
        # pause is in seconds
        set pause_s 10
        set pause_ms [expr { $pause_s * 1000 } ]
        while { $active_cs eq $cycle_start_cs \
                    && $concurrent_ct > 1 } {
            set sj_actives_list [nsv_get acs_mail_lite sj_actives_list]
            set active_cs [lindex $sj_actives_list end]
            set concurrent_ct [llength $sj_actives_list]
            ns_log Notice "acs_mail_lite::maildir_check_incoming.1198. \
 pausing ${pause_s} seconds for prior invoked processes to stop. \
 sj_actives_list '${sj_actives_list}'"
            after $pause_ms
        }

        if { $active_cs eq $cycle_start_cs } {
            
            set aml_package_id [apm_package_id_from_key "acs-mail-lite"]
            set filter_proc [parameter::get -parameter "IncomingFilterProcName" \
                                 -package_id $aml_package_id]
            #
            # Iterate through emails
            #
            foreach msg $messages_list {
                set error_p [acs_mail_lite::maildir_email_parse \
                                 -headers_arr_name hdrs_arr \
                                 -parts_arr_name parts_arr \
                                 -message_fpn $msg]
                if { $error_p } {
                    ns_log Notice "acs_mail_lite::maildir_check_incoming \
 could not process message file '${msg}'. Messaged moved to MailDir/cur/."
                    # Move the message into MailDir/cur for other mail reader
                    file copy -- $msg $curdir
                    file delete -- $msg

                } else {
                    # process email

                    set uid $hdrs_arr(uid)
                    set uidvalidity [file mtime $mail_dir_fullpath]
                    set processed_p [acs_mail_lite::inbound_cache_hit_p \
                                         $uid \
                                         $uidvalidity \
                                         $mail_dir_fullpath ]

                    if { !$processed_p } {
                        
                        set type [acs_mail_lite::email_type \
                                      -header_arr_name hdrs_arr ]
                        
                        set headers_list [array names hdrs_arr]
                        # Create some standardized header indexes aml_*
                        # with corresponding values 
                        set size_idx [lsearch -nocase -exact \
                                          $headers_list size]
                        set sizen [lindex $headers_list $size_idx]
                        if { $sizen ne "" } {
                            set hdrs_arr(aml_size_chars) $hdrs_arr(${sizen})
                        } else {
                            set hdrs_arr(aml_size_chars) ""
                        }
                        
                        if { [info exists hdrs_arr(received_cs)] } {
                            set hdrs_arr(aml_received_cs) $hdrs_arr(received_cs)
                        } else {
                            set hdrs_arr(aml_received_cs) ""
                        }
                        
                        set su_idx [lsearch -nocase -exact \
                                        $headers_list subject]
                        if { $su_idx > -1 } {
                            set sun [lindex $headers_list $su_idx]
                            set hdrs_arr(aml_subject) [ad_quotehtml $hdrs_arr(${sun})]
                        } else {
                            set hdrs_arr(aml_subject) ""
                        }
                        
                        set to_idx [lsearch -nocase -exact \
                                        $headers_list to]
                        if { ${to_idx} > -1 } {
                            set ton [lindex $headers_list $to_idx]
                            set hdrs_arr(aml_to) [ad_quotehtml $hdrs_arr(${ton}) ]
                        } else {
                            set hdrs_arr(aml_to) ""
                        }
                        
                        acs_mail_lite::inbound_email_context \
                            -header_array_name hdrs_arr \
                            -header_name_list $headers_list
                        
                        acs_mail_lite::inbound_prioritize \
                            -header_array_name hdrs_arr
                        
                        if { [string match {[a-z]*_[a-z]*} $filter_proc] } {
                            set hdrs_arr(aml_package_ids_list) [safe_eval ${filter_proc}]
                        }
                        
                        set id [acs_mail_lite::inbound_queue_insert \
                                    -parts_arr_name parts_arr 
                                \
                                    -headers_arr_name hdrs_arr \
                                    -error_p $error_p ]
                        ns_log Notice "acs_mail_lite::maildir_check_incoming \
 inserted to queue aml_email_id '${id}'"
                    }

                    # Move the message into MailDir/cur for other mail handling
                    file copy -- $msg $curdir
                    file delete -- $msg
                }
            }
        }
        # remove active_cs from sj_actives_list
        set sj_idx [lsearch -integer -exact $sj_actives_list $cycle_start_cs]
        # We call nsv_get within nsv_set to reduce chances of dropping
        # a new list entry.
        nsv_set acs_mail_lite sj_actives_list \
            [lreplace [nsv_get acs_mail_lite sj_actives_list] $sj_idx $sj_idx]
        ns_log Notice "acs_mail_lite::maildir_check_incoming.199. stop \
 sj_actives_list '${sj_actives_list}'"
        ns_log Dev "acs_mail_lite::maildir_check_incoming.200. nsv_get \
 acs_mail_lite sj_actives_list '[nsv_get acs_mail_lite sj_actives_list]'"
    }
    # end if !$error
    
    return 1
}


ad_proc -private acs_mail_lite::maildir_email_parse {
    -headers_arr_name
    -parts_arr_name
    {-message_fpn ""}
    {-part_id ""}
    {-section_ref ""}
    {-error_p "0"}
} {
    Parse an email from a Postfix maildir into array array_name
    for adding to queue via acs_mail_lite::inbound_queue_insert
    <br><br>
    Parsed data is set in headers and parts arrays in calling environment.
    @param message_fpn is absolute file path and name of one message
} {
    # Put email in a format usable for
    # acs_mail_lite::inbound_queue_insert to insert into queue

    # We have to generate the references for MailDir..

    # <br><pre>
    # Most basic example of part reference:
    # ref    # part
    # 1    #   message text only

    # More complex example. Order is not enforced, only hierarchy.
    # ref    # part
    # 1    #   multipart message
    # 1.1    # part 1 of ref 1
    # 1.2    # part 2 of ref 1
    # 4    #   part 1 of ref 4
    # 3.1    # part 1 of ref 3
    # 3.2    # part 2 of ref 3
    # 3.5    # part 5 of ref 3
    # 3.3    # part 3 of ref 3
    # 3.4    # part 4 of ref 3
    # 2    #   part 1 of ref 2

    # Due to the hierarchical nature of email, this proc is recursive.
    # To see examples of struct list to build, see www/doc/imap-notes.txt
    # and www/doc/maildir-test.tcl
    # reference mime procs:
    # https://www.tcl.tk/community/tcl2004/Tcl2003papers/kupries-doctools/tcllib.doc/mime/mime.html

    upvar 1 $headers_arr_name h_arr
    upvar 1 $parts_arr_name p_arr
    upvar 1 __max_txt_bytes __max_txt_bytes
    set has_parts_p 0
    set section_n_v_list [list ]
    # rfc 822 date time format regexp expression
    set re822 {[^a-z]([a-z][a-z][a-z][ ,]+[0-9]+ [a-z][a-z][a-z][ ]+[0-9][0-9][0-9][0-9][ ]+[0-9][0-9][:][0-9][0-9][:][0-9][0-9][ ]+[\+\-][0-9]+)[^0-9]}

    if { ![info exists __max_txt_bytes] } {
        set sp_list [acs_mail_lite::sched_parameters]
        set __max_txt_bytes [dict get $sp_list max_blob_chars]
    }
    if { $message_fpn ne "" } {
        if {[catch {set m_id [mime::initialize -file ${message_fpn}] } errmsg] } {
            ns_log Error "maildir_email_parse.71 could not parse \
 message file '${message_fpn}' error: '${errmsg}'"
            set error_p 1
        } else {
            # For acs_mail_lite::inbond_cache_hit_p, 
            # make a uid if there is not one. 
            set uid_ref ""
            # Do not use email file's tail, 
            # because tail is unique to system not email.
            # See http://cr.yp.to/proto/maildir.html
            
            # A header returns multiple values in a list
            # if header name is repeated in email.
            set h_list [mime::getheader $m_id]
            # headers_list 
            set headers_list [list ]
            foreach {h v} $h_list {
                switch -nocase -- $h {
                    uid {
                        if { $h ne "uid" } {
                            lappend struct_list "uid" $v
                        }
                        set uid_ref "uid"
                        set uid_val $v
                    }
                    message-id -
                    msg-id {
                        if { $uid_ref ne "uid"} {
                            if { $uid_ref ne "message-id" } {
                                # message-id is not required
                                # msg-id is an alternate 
                                # Fallback to most standard uid
                                set uid_ref [string tolower $h]
                                set uid_val $v
                            }
                        }
                    }
                    received {
                        if { [llength $v ] > 1 } {
                            set v0 [lindex $v 0]
                        } else {
                            set v0 $v
                        }
                        if { [regexp -nocase -- $re822 $v0 match r_ts] } {
                            set age_s [mime::parsedatetime $r_ts rclock]
                            set dt_cs [expr { [clock seconds] - $age_s } ]
                            lappend headers_list "aml_datetime_cs" $dt_cs
                        }
                    }
                    default { 
                        # do nothing
                    }
                }
                lappend headers_list $h $v
            }
            lappend headers_list "aml_received_cs" [file mtime ${message_fpn}]
            lappend headers_list "uid" $uid_val
            
            # Append property_list to to headers_list
            set prop_list [mime::getproperty $m_id]
            #set prop_names_list /mime::getproperty $m_id -names/
            foreach {n v} $prop_list {
                switch -nocase -exact -- $n {
                    params {
                        # extract name as header filename
                        foreach {m w} $v {
                            if { [string match -nocase "*name" $m] } {
                                regsub -all -nocase -- {[^0-9a-zA-Z-.,\_]} $w {_} w
                                if { $w eq "" } {
                                    set w "untitled"
                                } 
                                set filename $w
                                lappend headers_list "filename" $w
                            } else {
                                lappend headers_list $m $w
                            }
                        }
                    }
                    default {
                        lappend headers_list $n $v
                    }
                }
            }
        }
        if { $section_ref eq "" } {
            set section_ref 1
        }
        set subref_ct 0
        set type ""
        
        # Assume headers and names are unordered
        foreach {n v} $headers_list {
            if { [string match -nocase {parts} $n] } {
                set has_parts_p 1
                foreach part_id $v {
                    incr subref_ct
                    set subref $section_ref
                    append subref "." $subref_ct
                    acs_mail_lite::maildir_email_parse \
                        -headers_arr_name h_arr \
                        -parts_arr_name p_arr \
                        -part_id $part_id \
                        -section_ref $subref
                }
            } else {
                switch -exact -nocase -- $n {
                    size {
                        set bytes $v
                    }
                    # content-type
                    content {
                        set type $v
                    }
                    default {
                        # do nothing
                    }
                }
                if { $section_ref eq "1" } {
                    set h_arr(${n}) ${v}
                } else {
                    lappend section_n_v_list ${n} ${v}
                }
            }
        }
        
        set section_id [acs_mail_lite::section_id_of $section_ref]
        ns_log Dev "acs_mail_lite::maildir_email_parse.746 \
message_fpn '${message_fpn}' section_ref '${section_ref}' section_id '${section_id}'"
        
        # Add content of an email part
        set p_arr(${section_id},nv_list) $section_n_v_list
        set p_arr(${section_id},c_type) $type
        lappend p_arr(section_id_list) ${section_id}
        
        if { [info exists bytes] && $bytes > $__max_txt_bytes \
                 && ![info exists filename] } {
            set filename "blob.txt"
        }
        
        if { [info exists filename ] } {
            set filename2 [clock microseconds]
            append filename2 "-" $filename
            set filepathname [file join [acs_root_dir] \
                                  acs-mail-lite \
                                  $filename2 ]
            set p_arr(${section_id},filename) $filename
            set p_arr(${section_id},c_filepathname) $filepathname
            if { $filename eq "blob.txt" } {
                ns_log Dev "acs_mail_lite::maildir_email_parse.775 \
 m_id '${m_id}' '${section_ref}' \
 -file '${filepathname}'"
                set txtfileId [open $filepathname "w"]
                puts -nonewline $txtfileId [mime::getbody $m_id]
                close $txtfileId
            } else {
                ns_log Dev "acs_mail_lite::maildir_email_parse.780 \
 mime::getbody '${m_id}' '${section_ref}' \
 -file '${filepathname}' -decode"
                set binfileId [open $filepathname "w"]
                chan configure $binfileId -translation binary
                puts -nonewline $binfileId [mime::getbody $m_id -decode ]
                close $binfileId
            } 
        } elseif { $section_ref ne "" } {
            # text content
            set p_arr(${section_id},content) [mime::buildmessage $m_id]
            ns_log Dev "acs_mail_lite::maildir_email_parse.792 \
 text m_id '${m_id}' '${section_ref}': \
 $p_arr(${section_id},content)'"
            
        } else {
            set p_arr(${section_id},content) ""
            # The content for this case
            # has been verified to be redundant.
            # It is mostly the last section/part of message.
            #
            # If diagnostics urge examining these cases, 
            # Set debug_p 1 to allow the following code to 
            # to compress a message to recognizable parts without 
            # flooding the log.
            set debug_p 0
            if { $debug_p } {
                set msg_txt [mime::buildmessage $m_id]
                # 72 character wide lines * x lines
                set msg_start_max [expr { 72 * 20 } ]
                set msg_txtb [string range $msg_txt 0 $msg_start_max]
                if { [string length $msg_txt] \
                         > [expr { $msg_start_max + 400 } ] } {
                    set msg_txte [string range $msg_txt end-$msg_start_max end]
                } elseif { [string length $msg_txt] \
                               > [expr { $msg_start_max + 144 } ] } {
                    set msg_txte [string range $msg_txt end-144 end]
                } else {
                    set msg_txte ""
                }
                ns_log Dev "acs_mail_lite::maildir_email_parse.818 IGNORED \
 text '${message_fpn}' '${section_ref}' \n \
 msg_txte '${msg_txte}'"
            } else {
                ns_log Dev "acs_mail_lite::maildir_email_parse.822 ignored \
 text '${message_fpn}' '${section_ref}'"
            }
        }
    }
    return $error_p
}


#            
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:


