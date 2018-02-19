ad_library {

    Provides API for importing email under a varitey of deployment conditions.
    
    @creation-date 19 Jul 2017
    @cvs-id $Id$

}

namespace eval acs_mail_lite {}

# Although loose dependencies require imap procs right now,
# the inbound email procs are designed to integrate
# other inbound email paradigms with minimal amount
# of re-factoring of code.

##code OpenACS Developers wanting to adapt code to other than IMAP:
# Use acs_mail_lite::imap_check_incoming
# as a template for creating a generic version:
# acs_mail_lite::check_incoming

ad_proc -public acs_mail_lite::sched_parameters {
    -sredpcs_override
    -reprocess_old_p
    -max_concurrent
    -max_blob_chars
    -mpri_min
    -mpri_max
    -hpri_package_ids
    -lpri_package_ids
    -hpri_party_ids
    -lpri_party_ids
    -hpri_subject_glob
    -lpri_subject_glob
    -hpri_object_ids
    -lpri_object_ids
    -reject_on_hit
    -reject_on_miss
} {
    Returns a name value list of parameters 
    used by ACS Mail Lite scheduled procs.
    If a parameter is passed with value, the value is assigned to parameter.

    @option sched_parameter value

    @param sredpcs_override If set, use this instead of si_dur_per_cycle_s. See www/doc/analysis-notes

    @param reprocess_old_p If set, does not ignore prior unread email

    @param max_concurrent Max concurrent processes to import (fast priority)

    @param max_blob_chars Email body parts larger are stored in a file.

    @param mpri_min Minimum threshold integer for medium priority. Smaller is fast High priority.

    @param mpri_max Maximum integer for medium priority. Larger is Low priority.

    @param hpri_package_ids List of package_ids to process at fast priority.

    @param lpri_package_ids List of package_ids to process at low priority.

    @param hpri_party_ids List of party_ids to process at fast/high priority.

    @param lpri_party_ids List of party_ids to process at low priority.
    
    @param hpri_subject_glob When email subject matches, flag as fast priority.

    @param lpri_subject_glob When email subject matches, flag as low priority.

    @param hpri_object_ids List of object_ids to process at fast/high priority.

    @param lpri_object_ids List of object_ids to process at low priority.

    @param reject_on_hit Name/Value list. See acs_mail_lite::inbound_filters

    @param reject_on_miss Name/Value list. See acs_mail_lite::inbound_filters

} {
    # See one row table acs_mail_lite_ui
    # sched_parameters sp
    set sp_list [list \
                     sredpcs_override \
                     reprocess_old_p \
                     max_concurrent \
                     max_blob_chars \
                     mpri_min \
                     mpri_max \
                     hpri_package_ids \
                     lpri_package_ids \
                     hpri_party_ids \
                     lpri_party_ids \
                     hpri_subject_glob \
                     lpri_subject_glob \
                     hpri_object_ids \
                     lpri_object_ids \
                     reject_on_hit \
                     reject_on_miss ]
    
    foreach sp $sp_list {
        if { [info exists $sp] } {
            set new(${sp}) [set $sp]
        }
    }
    set changes_p [array exists new]
    set exists_p [db_0or1row acs_mail_lite_ui_r {
        select sredpcs_override,
        reprocess_old_p,
        max_concurrent,
        max_blob_chars,
        mpri_min,
        mpri_max,
        hpri_package_ids,
        lpri_package_ids,
        hpri_party_ids,
        lpri_party_ids,
        hpri_subject_glob,
        lpri_subject_glob,
        hpri_object_ids,
        lpri_object_ids,
        reject_on_hit,
        reject_on_miss
        from acs_mail_lite_ui limit 1
    } ]

    if { !$exists_p } {
        # set initial defaults
        set sredpcs_override 0
        set reprocess_old_p "f"
        set max_concurrent 6
        set max_blob_chars 32767
        set mpri_min "999"
        set mpri_max "99999"
        set hpri_package_ids ""
        set lpri_package_ids ""
        set hpri_party_ids ""
        set lpri_party_ids ""
        set hpri_subject_glob ""
        set lpri_subject_glob ""
        set hpri_object_ids ""
        set lpri_object_ids ""
        set reject_on_hit ""
        set reject_on_miss ""
    }


    if { !$exists_p || $changes_p } {
        set validated_p 1
        set new_pv_list [array names new]
        if { $changes_p } {
            foreach spn $new_pv_list {
                switch -exact -- $spn {
                    sredpcs_override -
                    max_concurrent -
                    max_blob_chars -
                    mpri_min -
                    mpri_max {
                        set v_p [ad_var_type_check_integer_p $new(${spn})]
                        if { $v_p } {
                            if { $new(${spn}) < 0 } {
                                set v_p 0
                            }
                        }
                        if { $v_p && $spn eq "mpri_min" } {
                            if { $new(${spn}) >= $mpri_max } {
                                set v_p 0
                                ns_log Warning "acs_mail_lite::\
 sched_parameters mpri_min '$new(${spn})' \
 must be less than mpri_max '${mpri_max}'"
                            }
                        }
                        if { $v_p && $spn eq "mpri_max" } {
                            if { $new(${spn}) <= $mpri_min } {
                                set v_p 0
                                ns_log Warning "acs_mail_lite::\
 sched_parameters mpri_min '${mpri_min}' \
 must be less than mpri_max '$new(${spn})'"
                            }
                        }
                    }
                    reprocess_old_p {
                        set v_p [string is boolean -strict $new(${spn}) ]
                    }
                    hpri_package_ids -
                    lpri_package_ids -
                    hpri_party_ids -
                    lpri_party_ids -
                    hpri_object_ids -
                    lpri_object_ids {
                        set v_p [ad_var_type_check_integerlist_p $new(${spn})]
                    }
                    hpri_subject_glob -
                    lpri_subject_glob {
                        if { $new(${spn}) eq "" } {
                            set v_p 1
                        } else {
                            set v_p [regexp -- {^[[:graph:]\ ]+$} $new(${spn})]
                            if { $v_p && \
                                     [string match {*[\[;]*} $new(${spn}) ] } {
                                set v_p 0
                            }
                        }
                    }
                    reject_on_hit -
                    reject_on_miss {
                        if { [f::even_p [llength $new(${spn}) ]] } {
                            set v_p 1
                        } else {
                            set v_p 0
                        }
                    }
                    defaults {
                        ns_log Warning "acs_mail_lite::sched_parameters \
 No validation check made for parameter '${spn}'"
                    }
                }
                if { !$v_p } {
                    set validated_p 0
                    ns_log Warning "acs_mail_lite::sched_parameters \
 value '$new(${spn})' for parameter '${spn}' not allowed."
                }
            }
        }
            
        if { $validated_p } {
            foreach sp_n $new_pv_list {
                set ${sp_n} $new($sp_n)
            }

            db_transaction {
                if { $changes_p } {
                    db_dml acs_mail_lite_ui_d {
                        delete from acs_mail_lite_ui
                    }
                }
                db_dml acs_mail_lite_ui_i {
                    insert into acs_mail_lite_ui 
                    (sredpcs_override,
                     reprocess_old_p,
                     max_concurrent,
                     max_blob_chars,
                     mpri_min,
                     mpri_max,
                     hpri_package_ids,
                     lpri_package_ids,
                     hpri_party_ids,
                     lpri_party_ids,
                     hpri_subject_glob,
                     lpri_subject_glob,
                     hpri_object_ids,
                     lpri_object_ids,
                     reject_on_hit,
                     reject_on_miss)
                    values 
                    (:sredpcs_override,
                     :reprocess_old_p,
                     :max_concurrent,
                     :max_blob_chars,
                     :mpri_min,
                     :mpri_max,
                     :hpri_package_ids,
                     :lpri_package_ids,
                     :hpri_party_ids,
                     :lpri_party_ids,
                     :hpri_subject_glob,
                     :lpri_subject_glob,
                     :hpri_object_ids,
                     :lpri_object_ids,
                     :reject_on_hit,
                     :reject_on_miss
                     )
                }

                # See acs_mail_lite::imap_check_incoming for usage of:
                nsv_set acs_mail_lite si_configured_p 1
            }
        }
                
    }
    set s_list [list ]
    foreach s $sp_list {
        set sv [set ${s}]
        lappend s_list ${s} $sv
    }
    return $s_list
}

ad_proc -public acs_mail_lite::inbound_prioritize {
    {-header_array_name ""}
    {-size_chars ""}
    {-received_cs ""}
    {-subject ""}
    {-package_id ""}
    {-party_id ""}
    {-object_id ""}
} {
    Returns a prioritization integer for assigning priority to an inbound email.
    Another proc processes in order of lowest number first.
    Returns empty string if input values from email are not expected types.
    Priority has 3 categories: high priority, normal priority, low priority
    as specified in acs_mail_lite::sched_parameters

    Expects parameters to be passed within an array, or individually.
    When passing via an array, parameter names have suffix "aml_".
    For example, size_chars becomes aml_size_chars.

    Array values take precedence, if they exist.

    @param size_chars of email

    @param received_cs seconds since epoch when email received

    @param package_id associated with email (if any)

    @param party_id associated with email (if any)

    @param subject of email

    @param object_id associated with email (if any)

    @see acs_mail_lite::sched_parameters

} {
    if { $header_array_name ne "" } {
        set hn_list [list \
                         aml_size_chars \
                         aml_received_cs \
                         aml_subject \
                         aml_package_id \
                         aml_party_id \
                         aml_object_id ]
        upvar 1 $header_array_name h_arr
        foreach hn $hn_list {
            set vname [string range $hn 4 end]
            if { [info exists h_arr(${hn}) ] } {
                # set variable from array
                set ${vname} $h_arr(${hn})
            } elseif { [set ${hn}] ne "" } {
                # set array's index same as variable
                set h_arr(${hn}) [set ${vname} ]
            }
        }                
    }

    set priority_fine ""

    set size_error_p 0
    # validate email inputs
    if { ! ([string is wideinteger -strict $size_chars] \
                && $size_chars > 0) } {
        set size_error_p 1
        ns_log Warning "acs_mail_lite::inbound_prioritize.283: \
 size_chars '${size_chars}' is not a natural number."
    }
    set time_error_p 0
    if { ! ([string is wideinteger -strict $received_cs] \
                && $received_cs > 0) } {
        set time_error_p 1
        ns_log Warning "acs_mail_lite::inbound_prioritize.289: \
 received_cs '${received_cs}' is not a natural number."
    }

    # *_cs means clock time from epoch in seconds, 
    #      same as returned from tcl clock seconds
    array set params_arr [acs_mail_lite::sched_parameters]

    set priority 2
    # Set general priority in order of least specific first
    if { $package_id ne "" } {
        if { $package_id in $params_arr(hpri_package_ids) } {
            set priority 1
        }
        if { $package_id in $params_arr(lpri_package_ids) } {
            set priority 3
        }
    }

    if { $party_id ne "" } {
        if { $party_id in $params_arr(hpri_party_ids) } {
            set priority 1
        }
        if { $party_id in $params_arr(lpri_party_ids) } {
            set priority 3
        }
    }


    if { [string match $params_arr(hpri_subject_glob) $subject] } {
        set priority 1
    }
    if { [string match $params_arr(lpri_subject_glob) $subject] } {
        set priority 3
    }

    
    if { $object_id ne "" } {
        if { $object_id in $params_arr(hpri_object_ids) } {
            set priority 1
        }
        if { $object_id in $params_arr(lpri_object_ids) } {
            set priority 3
        }
    }
    
    # quick math for arbitrary super max of maxes
    set su_max $params_arr(mpri_max)
    append su_max "00"
    set size_list [list $su_max]
    set ns_section_list [list nssock nssock_v4 nssock_v6]
    foreach section $ns_section_list {
        lappend size_list [ns_config -int -min 0 $section maxinput]
    }
    set size_max [f::lmax $size_list] 
    # add granularity
    switch -exact $priority {
        1 {
            set pri_min 0
            set pri_max $params_arr(mpri_min)
        }
        2 {
            set pri_min $params_arr(mpri_min)
            set pri_max $params_arr(mpri_max)
        }
        3 {
            set pri_min $params_arr(mpri_max)
            set pri_max $size_max
        }
        default {
            ns_log Warning "acs_mail_lite::inbound_prioritize.305: \
 Priority value not expected '${priority}'"
        }
    }

    ns_log Dev "inbound_prioritize: pri_max '${pri_max}' pri_min '${pri_min}'"

    set range [expr { $pri_max - $pri_min } ]
    # deviation_max = d_max
    set d_max [expr { $range / 2 } ]
    # midpoint = mp
    set mp [expr { $pri_min + $d_max } ]
    ns_log Dev "inbound_prioritize: range '${range}' d_max '${d_max}' mp '${mp}'"

    # number of variables in fine granularity calcs: 
    # char_size, date time stamp
    set varnum 2
    # Get most recent scan start time for reference to batch present time
    set start_cs [nsv_get acs_mail_lite si_start_t_cs]
    set dur_s [nsv_get acs_mail_lite si_dur_per_cycle_s]
    ns_log Dev "inbound_prioritize: start_cs '${start_cs}' dur_s '${dur_s}'"

    # Priority favors earlier reception, returns decimal -1. to 0.
    # for normal operation. Maybe  -0.5 to 0. for most.
    if { $time_error_p } {
        set pri_t 0
    } else {
        set pri_t [expr { ( $received_cs - $start_cs ) / ( 2. * $dur_s ) } ]
    }

    # Priority favors smaller message size. Returns decimal 0. to 1.
    # and for most, somewhere closer to perhaps 0.
    if { $size_error_p } {
        set pri_s [expr { ( $size_max / 2 ) } ]
    } else {
        set pri_s [expr { ( $size_chars / ( $size_max + 0. ) ) } ]
    }

    set priority_fine [expr { int( ( $pri_t + $pri_s ) * $d_max ) + $mp } ] 
    ns_log Dev "inbound_prioritize: pri_t '${pri_t}' pri_s '${pri_s}'"
    ns_log Dev "inbound_prioritize: pre(max/min) priority_fine '${priority_fine}'"
    set priority_fine [f::min $priority_fine $pri_max]
    set priority_fine [f::max $priority_fine $pri_min]

    if { $header_array_name ne "" } {
        set h_arr(aml_priority) $priority_fine
    }
    return $priority_fine
}


ad_proc -public acs_mail_lite::email_type {
    {-subject ""}
    {-from ""}
    {-headers ""}
    {-header_arr_name ""}
    {-reply_too_fast_s "10"}
    {-check_subject_p "0"}
} {
    <p>
    Scans email's subject, from and headers for actionable type.
    </p><p>
    Returns actionable type and saves same type in header_arr_name(aml_type),
    and saves some normalized header info
    to reduce redundant processing downstream. See code comments for details.
    </p><p>
    Actional types: \
        'auto_gen' 'auto_reply', 'bounce', 'in_reply_to' or 
    empty string indicating 'other' type.
    </p>
    <ul><li>
    'auto_reply' may be a Delivery Status Notification for example.
    </li><li>
    'bounce' is a specific kind of Delivery Status Notification.
    </li><li>
    'in_reply_to' is an email reporting to originate from local email,
    which needs to be tested further to see if OpenACS needs to act on
    it versus a reply to a system administrator email for example.
    </li><li>
    'auto_gen' is an auto-generated email that does not qualify as 'auto_reply', 'bounce', or 'in_reply_to'
    </li><li>
    '' (Empty string) refers to email that the system does not recognize as a reply
    of any kind. If not a qualifying type, returns empty string.
    </li></ul>
    Adds these index to headers array:
    <ul><li>
    received_cs: the recevied time of email in tcl clock epoch time.
    </li><li>
    aml_type:  the same value returned by this proc.
    </li></ul>
    <p>
    If additional headers not calculated, they have value of empty string.
    </p><p>
    If headers and header_arr_name provided, only header_arr_name will be used, if header_arr_name contains at least one value.
    </p><p>
    If check_subject_p is set 1, \
    checks for common subjects identifying autoreplies. \
        This is not recommended to rely on exclusively. \
        This feature provides a framework for expaning classification of \
        emails for deployment routing purposes.
    </p><p>
    If array includes keys from 'ns_imap struct', such as internaldate.*, \
        then adds header with epoch time quivilent to header index received_cs
    </p>
    @param subject of email
    @param from of email
    @param headers of email, a block of text containing all headers and values
    @param header_arr_name, the name of an array containing headers.
    @param check_subject_p Set to 1 to check email subject. 
} {
    set ag_p 0
    set an_p 0
    set ar_p 0
    set as_p 0
    set dsn_p 0
    set irt_idx -1
    set or_idx -1
    set pe_p 0
    set ts_p 0
    set reject_p 0
    # header cases:  {*auto-generated*} {*auto-replied*} {*auto-notified*}
    # from:
    # https://www.iana.org/assignments/auto-submitted-keywords/auto-submitted-keywords.xhtml
    # and rfc3834 https://www.ietf.org/rfc/rfc3834.txt

    # Do NOT use x-auto-response-suppress
    # per: https://stackoverflow.com/questions/1027395/detecting-outlook-autoreply-out-of-office-emails

    # header cases: 
    # {*x-autoresponder*} {*autoresponder*} {*autoreply*}
    # {*x-autorespond*} {*auto_reply*} 
    # from: 
    # https://github.com/jpmckinney/multi_mail/wiki/Detecting-autoresponders
    # redundant cases are removed from list.
    # auto reply = ar
    set ar_list [list \
                     {auto-replied} \
                     {auto-reply} \
                     {autoreply} \
                     {autoresponder} \
                     {x-autorespond} \
                    ]
    # Theses were in auto_reply, but are not specific to replies:
    #                     {auto-generated} 
    #             {auto-notified} 
    # See section on auto_gen types. (auto-submitted and the like)

    
    if { $header_arr_name ne "" } {
        upvar 1 $header_arr_name h_arr
    } else {
        array set h_arr [list ]
    }

    if { $headers ne "" && [array size h_arr] < 1 } {
        #  To remove subject from headers to search, 
        #  incase topic uses a reserved word,
        #  we rebuild the semblence of array returned by ns_imap headers.
        #  Split strategy from qss_txt_table_stats
        set linebreaks "\n\r\f\v"
        set row_list [split $headers $linebreaks]
        foreach row $row_list {
            set c_idx [string first ":" $row]
            if { $c_idx > -1 } {
                set header [string trim [string range $row 0 $c_idx-1]]
                # following identifies multiline header content to ignore
                if { ![string match {*[;=,]*} $header] } {
                    # list of email headers at:
                    # https://www.cs.tut.fi/~jkorpela/headers.html
                    # Suggests this filter for untrusted input:
                    if { [regsub -all -- {[^a-zA-Z0-9\-]+} $header {} h2 ] } {
                        ns_log Warning "acs_mail_lite:email_type.864: \
 Unexpected header '${header}' changed to '${h2}'"
                        set header $h2
                    }
                    set value [string trim [string range $row $c_idx+1 end]]
                    # string match from proc safe_eval
                    if { ![string match {*[\[;]*} $value ] } {
                        # 'append' is used instead of 'set' in
                        # the rare case that there's a glitch
                        # and there are two or more headers with same name.
                        # We want to examine all values of specific header.
                        append h_arr(${header}) "${value} "
                        ns_log Dev "acs_mail_lite::email_type.984 \
 header '${header}' value '${value}' from text header '${row}'"
                    }
                }
            }
        }
    }

    set reject_p [acs_mail_lite::inbound_filters -headers_arr_name h_arr]


    if { !$reject_p } {

        set hn_list [array names h_arr]
        ns_log Dev "acs_mail_lite::email_type.996 hn_list '${hn_list}'"
        # Following checks according to rfc3834 section 3.1 Message header
        # https://tools.ietf.org/html/rfc3834


        # check for in-reply-to = irt
        set irt_idx [lsearch -glob -nocase $hn_list {in-reply-to}]
        # check for message_id = mi
        # This is a new message id, not message id of email replied to
        set mi_idx [lsearch -glob -nocase $hn_list {message-id}]

        # Also per rfc5436 seciton 2.7.1 consider:
        # auto-submitted = as
        
        set as_idx [lsearch -glob -nocase $hn_list {auto-submitted}]
        if { $as_idx > 1 } {
            set as_p 1
            set as_h [lindex $hn_list $as_idx]
            set an_p [string match -nocase $h_arr(${as_h}) {auto-notified}]
            # also check for auto-generated
            set ag_p [string match -nocase $h_arr(${as_h}) {auto-generated}]
        }
        


        ns_log Dev "acs_mail_lite::email_type.1017 as_p ${as_p} an_p ${an_p} ag_p ${ag_p}"

        # If one of the headers contains {list-id} then email
        # is from a mailing list.

        set i 0
        set h [lindex $ar_list $i]
        while { $h ne "" && !$ar_p } {
            #set ar_p string match -nocase $h $hn

            set ar_idx [lsearch -glob $hn_list $h]
            if { $ar_idx > -1 } {
                set ar_p 1
            }

            incr i
            set h [lindex $ar_list $i]
        }

        ns_log Dev "acs_mail_lite::email_type.1039 ar_p ${ar_p}"


        # get 'from' header value possibly used in a couple checks
        set fr_idx [lsearch -glob -nocase $hn_list {from}]
        set from_email ""
        if { $fr_idx > -1 } {
            set fr_h [lindex $hn_list $fr_idx]
            set from [ns_quotehtml $h_arr(${fr_h})]
            set h_arr(aml_from) $from
            set from_email [string tolower \
                                [acs_mail_lite::parse_email_address \
                                     -email $from]]
            set h_arr(aml_from_addrs) $from_email
            set at_idx [string last "@" $from ]
        } else {
            set at_idx -1
        }
        if { $at_idx > -1 } {
            # from_email is not empty string
            set from_host [string trim [string range $from $at_idx+1 end]]
            set party_id [party::get_by_email -email $from_email]
            if { $party_id ne "" } {
                set pe_p 1
            }
        } else {
            set from_host ""
            set party_id ""
        }


        

        if { !$ar_p && [info exists h_arr(internaldate.year)] \
                 && $from ne "" } {

            # Use the internal timestamp for additional filters
            set dti $h_arr(internaldate.year)
            append dti "-" [format "%02u" $h_arr(internaldate.month)]
            append dti "-" [format "%02u" $h_arr(internaldate.day)]
            append dti " " [format "%02u" $h_arr(internaldate.hours)]
            append dti ":" [format "%02u" $h_arr(internaldate.minutes)]
            append dti ":" [format "%02u" $h_arr(internaldate.seconds)] " "
            if { $h_arr(internaldate.zoccident) eq "0" } {
                # This is essentially iso8601 timezone formatting.
                append dti "+"
            } else {
                # Comment from panda-imap/src/c-client/mail.h:
                # /* non-zero if west of UTC */
                # See also discussion beginning with:
                # /* occidental *from Greenwich) timezones */
                # in panda-imap/src/c-client/mail.c
                append dti "-"
            }
            append dti [format "%02u" $h_arr(internaldate.zhours)]
            append dti [format "%02u" $h_arr(internaldate.zminutes)] "00"
            if { [catch {
                set dti_cs [clock scan $dti -format "%Y-%m-%e %H:%M:%S %z"]
            } err_txt ] } {
                set dti_cs ""
                ns_log Warning "acs_mail_lite::email_type.1102 \
 clock scan '${dti}' -format %Y-%m-%d %H:%M:%S %z failed. Could not check ts_p case."
            }
            set h_arr(aml_received_cs) $dti_cs
            # Does response time indicate more likely by a machine?
            # Not by itself. Only if it is a reply of some kind.

            # Response is likely machine if it is fast.
            # If the difference between date and local time is less than 10s
            # and either from is "" or subject matches "return*to*sender"

            # More likely also from machine 
            # if size is more than a few thousand characters in a short time.

            # This is meant to detect more general cases
            # of bounce/auto_reply detection related to misconfiguration
            # of a system.
            # This check is
            # intended to prevent flooding server and avoiding looping
            # that is not caught by standard MTA / smtp servers.
            # An MTA likely checks already for most floods and loops.
            # As well, this check providesy yet another
            # indicator to intervene in uniquely crafted attacks.

            if { $pe_p && $dti_cs ne "" } {
                # check multiple emails from same user

                nsv_lappend acs_mail_lite si_party_id_cs(${party_id}) $dti_cs
                set max_ct [nsv_get acs_mail_lite si_max_ct_per_cycle]
                set cycle_s [nsv_get acs_mail_lite si_dur_per_cycle_s]
                set cs_list [nsv_get acs_mail_lite si_party_id_cs(${party_id})]
                set cs_list_len [llength $cs_list]
                if { $cs_list_len > $max_ct } {
                    set params_ul [acs_mail_lite::sched_parameters]
                    set lpri_pids [dict get $params_ul lpri_party_ids]
                    set lpri_pids_list [split $lpri_pids]
                    if { $party_id ni $lpri_pdis_list } {
                        # full check required
                        set start_cs [nsv_get acs_mail_lite si_start_t_cs]
                        set prev_start_cs [expr { $start_cs - $cycle_s } ]
                        set cs_list [lsort -integer -increasing -unique $cs_list]
                        set i 0
                        set is_stale_p 1
                        while { $is_stale_p && $i < $cs_list_len } {
                            set test_ts [lindex $cs_list $i]
                            if { $test_ts > $prev_start_cs } {
                                set is_stale_p 0
                            }
                            incr i
                        }
                        if { $is_stale_p } {
                            set cs2_list [list ]
                            # Really? 
                            # We just added dti_cs to si_party_id_cs(party_id)
                            # This happens when scaning email is delayed some
                            ns_log Warning "acs_mail_lite::email_type.655 \
 party_id '${party_id}' prev_start_cs '${prev_start_cs}' i '${i}' \
 cs_list_len '${cs_list_len}' cs_list '${cs_list}' cs2_list '${cs2_list}'"
                        } else {
                            set cs2_list [lrange $cs_list $i-1 end]
                            set cs2_list_len [llength $cs2_list]
                            if { $cs2_list_len > $max_ct } {
                                # si_max_ct_per_cycle reached for party_id
                                
                                # Flag as low priority if over count for cycle
                                # That is, add party_id to 
                                # acs_mail_lite::sched_parameters -lpri_party_ids 
                                # if it is not already
                                # Already checked at beginning of this check
                                lappend lpri_pids_list $party_id
                                acs_mail_lite::sched_parameters \
                                    -lpri_party_ids $lpri_pids_list
                                
                            }
                        }
                        nsv_set acs_mail_lite si_party_id_cs(${party_id}) $cs2_list
                    }
                }
            }
                
            # RFC 822 header required: DATE
            set dt_idx [lsearch -glob -nocase $hn_list {date}]
            # If there is no date. Flag it.
            if { $dt_idx < 0 } {
                set ts_p 1
            } else {
                # Need to check received timestamp vs. when OpenACS
                # or a system hosted same as OpenACS sent it.
                
                set dt_h [lindex $hn_list $dt_idx]
                # Cannot use optional ns_imap parsedate here. May not exist.
                # rfc5322 section 3.3: multiple spaces in date is acceptable
                # but not for tcl clock scan -format
                regsub -all -- {[ ][ ]*} $h_arr(${dt_h}) { } dt_spaced
                # rfc5322 section 3.3: obs-zone breaks clock scan format too
                set dt_spaced_tz_idx [string first " (" $dt_spaced]
                set dt_spaced [string trim [string range $dt_spaced 0 ${dt_spaced_tz_idx} ]]
                set dte_cs [clock scan $dt_spaced -format "%a, %d %b %G %H:%M:%S %z"]

                set diff 1000
                if { $dte_cs ne "" && $dti_cs ne "" } {
                    set diff [expr { abs( $dte_cs - $dti_cs ) } ]
                } 
                # If too fast, set ts_p 1
                if { $diff < 11 } {
                    set ts_p 1
                }
                
                # check from host against acs_mail_lite's host
                # From: header must show same OpenACS domain for bounce
                # and subsequently verified not a user or system recognized
                # user/admin address. 
                
                # Examples of unrecognized addresses include mailer-daemon@..
                set host [dict get [acs_mail_lite::imap_conn_set] host]
                if { $ts_p && [string -nocase "*${host}*" $from_host] } {
                    if { $from_email eq [ad_outgoing_sender] || !$pe_p } {
                        # This is a stray one. 
                        set ag_p 1
                    }
                    
                }
                
                # Another possibility is return-path "<>"
                # and Message ID unique-char-ref@bounce-domain
                
                # Examples might be a bounced email from 
                # a nonstandard web form on site
                # or 
                # a loop where 'from' is
                # a verified user or system recognized address
                # and reply is within 10 seconds
                # and a non-standard acs-mail-lite reply-to address
                
                
            }

        }
        
        # Delivery Status Notifications, see rfc3464
        # https://tools.ietf.org/html/rfc3464
        # Note: original-envelope-id is not same as message-id.
        # original-recipient = or
        set or_idx [lsearch -glob -nocase $hn_list {original-recipient}]
        if { $or_idx < 0 } {
            # RFC3461 4.2 uses original-recipient-address
            set or_idx [lsearch -glob \
                            -nocase $hn_list {original-recipient-address}]
        }

        # action = ac (required for DSN)
        # per fc3464 s2.3.3
        set ac_idx [lsearch -glob -nocase $hn_list {action}]
        if { $ac_idx > -1 } {
            set ac_h [lindex $hn_list $ac_idx]
            set status_list [list failed \
                                 delayed \
                                 delivered \
                                 relayed \
                                 expanded ]
            # Should 'delivered' be removed from status_list?
            # No, just set ar_p 1 instead of dsn_p 1

            set s_i 0
            set status_p 0
            set stat [lindex $status_list $s_i]
            while { $stat ne "" && !$status_p } {
                # What if there are duplicate status values or added junk?
                # Catch it anyway by wrapping glob with asterisks
                if { [string match -nocase "*${stat}*" $h_arr(${ac_h})] } {
                    set status_p 1
                }
                ns_log Dev "acs_mail_lite::email_type.1070 \
 status_p $status_p stat '${stat}' ac_h ${ac_h} h_arr(ac_h) '$h_arr(${ac_h})'"

                incr s_i
                set stat [lindex $status_list $s_i]
            }
            if { $status_p } {
                # status = st (required for DSN)
                # per fc3464 s2.3.4
                set st_idx [lsearch -glob -nocase $hn_list {status}]
                if { $st_idx > -1 } {
                    set st_h [lindex $hn_list $st_idx]
                    set dsn_p [string match {*[0-9][0-9][0-9]*} \
                                   $h_arr(${st_h}) ]
                    ns_log Dev "acs_mail_lite::email_type.1080 \
 dsn_p ${dsn_p} st_h ${st_h} h_arr(st_h) '$h_arr(${st_h})'"
                    if { $st_idx eq 2 || !$dsn_p } {
                       set ar_p 1
                    }
                }
            }
        }

        ns_log Dev "acs_mail_lite::email_type.1089 \
 ar_p ${ar_p} dsn_p ${dsn_p}"

        # if h_arr exists and..
        if { !$ar_p && $check_subject_p } {
            # catch nonstandard cases
            # subject flags
            
            # If 'from' not set. Set here.
            if { $from eq "" } {
                set fr_idx [lsearch -glob -nocase $hn_list {from}]
                if { $fr_idx > -1 } {
                    set from $h_arr(${from})
                }
            }
            # If 'subject' not set. Set here.
            if { $subject eq "" } {
                set fr_idx [lsearch -glob -nocase $hn_list {subject}]
                if { $fr_idx > -1 } {
                    set subject $h_arr(${subject})
                    set h_arr(aml_subject) [ns_quotehtml $subject]
                }
            }
            
            set ps1 [string match -nocase {*out of*office*} $subject]
            set ps2 [string match -nocase {*automated response*} $subject]
            set ps3 [string match -nocase {*autoreply*} $subject]
            set ps4 [string match {*NDN*} $subject]
            set ps5 [string match {*\[QuickML\] Error*} $subject]
            # rfc3834 states to NOT rely on 'Auto: ' in subject for detection. 
            #set ps6 \[string match {Auto: *} $subject\]
            
            # from flags = pf
            set pf1 [string match -nocase {*mailer*daemon*} $from]
                
            set ar_p [expr { $ps1 || $ps2 || $ps3 || $ps4 || $ps5 || $pf1 } ]
        }

    }
    ns_log Dev "acs_mail_lite::email_type.1127 ar_p ${ar_p}"


    # Return actionable types:
    # 'auto_gen', 'auto_reply', 'bounce', 'in_reply_to' or '' (other)

    #  a bounce also flags maybe auto_reply, in_reply_to, auto_gen
    # an auto_reply also flags maybe auto_reply, auto_gen, in_reply_to
    # an auto_gen does NOT include an 'in_reply_to'
    # an in_reply_to does NOT include 'auto_gen'. 
    if { $dsn_p || $or_idx > -1 } {
        set type "bounce"
    } elseif { $ar_p || ( $irt_idx > -1 && \
                              ( $ag_p || $as_p || $an_p || $ts_p ) ) } {
        set type "auto_reply"
    } elseif { $ag_p || $as_p || $an_p || $ts_p } {
        set type "auto_gen"
    } elseif { $irt_idx > -1 } {
        set type "in_reply_to"
    } else {
        # other
        set type ""
    }
    if { $header_arr_name ne "" } {
        set h_arr(aml_type) $type
    }
    return $type
}


ad_proc -private acs_mail_lite::inbound_queue_insert {
    -headers_arr_name
    -parts_arr_name
    {-priority ""}
    {-aml_email_id ""}
    {-section_ref ""}
    {-struct_list ""}
    {-error_p "0"}
} {
    Adds a new, actionable incoming email to the queue for
    prioritized processing.

    Returns aml_email_id if successful, otherwise empty string.
} {
    upvar 1 $headers_arr_name h_arr
    upvar 1 $parts_arr_name p_arr

    set id ""
    # This should remain general enough to import
    # email regardless of its source.

    # Email should already be parsed and in a transferable format
    # in passed arrays

    # Array content corresponds to these tables:

    #   h_arr($name) $value         acs_mail_lite_ie_headers
    #       Some indexes match fields of table acs_mail_lite_from_external:
    #   h_arr(aml_email_id)
    #   h_arr(aml_to_addrs)     to_email_addrs
    #   h_arr(aml_from_addrs)   from_email_addrs
    #   h_arr(aml_priority)     priority    
    #   h_arr(aml_subject)      email subject (normalized index reference).
    #   h_arr(aml_msg_id)       email message-id or msg-id's cross-reference
    #                           see acs_mail_lite_msg_id_map.msg_id
    #   h_arr(aml_size_chars)   size_chars
    #   h_arr(aml_processed_p)  processed_p

    #   p_arr($section_id,<field>)  acs_mail_lite_ie_parts (content of a part)
    #   p_arr($section_id,nv_list)  acs_mail_lite_part_nv_pairs
    #   p_arr(section_id_list) list of section_ids
    #
    # 
    # where index is section_id based on section_ref, and
    # where top most section_ref is a natural number as
    # there may be more than one tree.
    # 
    # Specifically,
    # for p_arr, content is p_arr($section_id,content)
    #            c_type is p_arr($section_id,c_type)
    #            filename is p_arr($section_id,filename)
    #            c_filepathname is p_arr($section_id,c_filepathname)
    # 


    
    if { !$error_p } {
        
        # email goes into queue tables:

        # This data is expected to be available at same moment

        db_transaction {
            set id [db_nextval acs_mail_lite_in_id_seq]

            # acs_mail_lite_ie_headers
            set h_names_list [array names h_arr]
            set to_email_addrs ""
            set from_email_addrs ""
            set subject ""
            set msg_id ""
            set size_chars ""
            set received_cs ""
            # sub set of header names
            foreach h_name $h_names_list {
                set h_value $h_arr(${h_name}) 
                switch -nocase -- $h_name {
                    x-openacs-from -
                    aml_from_addrs -
                    from {
                        if { ![info exists h_arr(aml_from_addrs)] } {
                            set fr_addrs [acs_mail_lite::parse_email_address \
                                                      -email $h_value ]
                            set h_arr(aml_from_addrs) $fr_addrs
                        } else {
                            set fr_addrs $h_arr(aml_from_addrs)
                        }
                    }
                    x-openacs-to -
                    aml_to_addrs -
                    to {
                        if { ![info exists h_arr(aml_to_addrs)] } {
                            set h_quoted [ns_quotehtml $h_value]
                            set h_arr(aml_to) $h_quoted
                            set to_addrs [acs_mail_lite::parse_email_address \
                                                    -email $h_quoted ]
                            set h_arr(aml_to_addrs) $to_addrs
                        } else {
                            set to_addrs $h_arr(aml_to_addrs)
                        }
                    }
                    aml_msg_id {
                        set msg_id $h_value
                    }
                    x-openacs-subject -
                    aml_subject -
                    subject {
                        set subject $h_value
                    }
                    x-openacs-size -
                    aml_size_chars -
                    size {
                        if { ![info exists h_arr(aml_size_chars) ] } {
                            if { [string is wideinteger -strict $h_value] } {
                                set size_chars $h_value
                            }
                        } else {
                            set size_chars $h_arr(ams_size_chars)
                        }
                    }
                    aml_received_cs { 
                        set received_cs $h_value
                    }
                    aml_priority {
                        set priority $h_value
                    }
                }
                
                if { $priority eq "" } {
                    set priority [dict get \
                                      [acs_mail_lite::sched_parameters] mpri_max]
                }

                db_dml acs_mail_lite_ie_headers_w1 {
                    insert into acs_mail_lite_ie_headers 
                    (aml_email_id,h_name,h_value)
                    values (:id,:h_name,:h_value)
                }
            }
            
            # acs_mail_lite_from_external 
            set false 0
            #set processed_p 0
            #set release_p 0
            db_dml acs_mail_lite_from_external_w1 {
                insert into acs_mail_lite_from_external
                (aml_email_id,
                 priority,
                 to_email_addrs,
                 from_email_addrs,
                 subject,
                 msg_id,
                 size_chars,
                 received_cs,
                 processed_p,
                 release_p)
                values (:id,
                        :priority,
                        :to_addrs,
                        :fr_addrs,
                        :subject,
                        :msg_id,
                        :size_chars,
                        :received_cs,
                        :false,
                        :false)
            }



            set parts_list [list c_type filename content c_filepathname]
            foreach section_id $p_arr(section_id_list) {

                # acs_mail_lite_ie_parts
                foreach p $parts_list {
                    set $p ""
                    if { [info exists p_arr(${section_id},${p}) ] } {
                        set $p $p_arr(${section_id},${p})
                    } 
                }
                db_dml acs_mail_lite_ie_parts_w1 {
                    insert into acs_mail_lite_ie_parts
                    (aml_email_id,
                     section_id,
                     c_type,
                     filename,
                     content,
                     c_filepathname)
                    values 
                    (:id,
                     :section_id,
                     :c_type,
                     :filename,
                     :content,
                     :c_filepathname)
                }

                # acs_mail_lite_ie_part_nv_pairs
                foreach {p_name p_value} $p_arr(${section_id},nv_list) {
                    db_dml acs_mail_lite_ie_part_mv_pairs_w1 {
                        insert into acs_mail_lite_ie_part_nv_pairs
                        (aml_email_id,
                         section_id,
                         p_name,
                         p_value)
                        values
                        (:id,
                         :section_id,
                         :p_name,
                         :p_value)
                    }
                }
            }
            

        } on_error {
            ns_log Error "acs_mail_lite::inbound_queue_insert \
 Unable to insert email. Headers: '[array get h_arr]' Error: ${errmsg}"

        }
    }
    return $id
}


ad_proc -private acs_mail_lite::inbound_queue_pull {
} {
    Identifies and processes highest priority inbound email.
} {

    
    # Get scheduling parameters
    set start_cs [clock seconds]
    # The value of si_dur_per_cycle_s is used
    # to keep about 1 inbound_queue_pull active at a time.
    # This is an artificial limit.
    # For parallel processing of queue, remove this
    # scheduling check, and query the queue with each iteration.
    # That is, query the queue before processing
    # each inbound email to avoid collision of attempts
    # to process email more than once.
    set si_dur_per_cycle_s \
        [nsv_get acs_mail_lite si_dur_per_cycle_s ]
    set stop_cs [expr { $start_cs + int( $si_dur_per_cycle_s * .8 ) } ]
    set aml_package_id [apm_package_id_from_key "acs-mail-lite"]
    # ct = count
    set pull_ct 0
    # sort only what we need. Process in 20 email chunks
    set email_max_ct 20
    set pull_p 1
    while { $pull_p && [clock seconds ] < $stop_cs } {

        # ols = ordered lists
        set chunk_ols [db_list acs_mail_lite_from_external_rN {
            select aml_email_id from acs_mail_lite_from_external
            where processed_p <>'1' 
            and release_p <>'1'
            order by priority
            limit :email_max_ct } ]

        set chunk_len [llength $chunk_ols]
        if { $chunk_len < 1} {
            set pull_p 0
        }
        set i 0
        while { $i < $chunk_len && $pull_p && [clock seconds ] < $stop_cs } {
            array unset h_arr
            array unset p_arr
            set error_p 0
            set aml_email_id [lindex $chunk_ols $i]
            acs_mail_lite::inbound_queue_pull_one \
                -h_array_name h_arr \
                -p_array_name p_arr \
                -aml_email_id $aml_email_id
            
            set processed_p 0
            set bounced_p [acs_mail_lite::bounce_ministry]
            if { !$bounced_p } {

                # following from acs_mail_lite::load_mail
                set pot_object_id [lindex [split $h_arr(aml_to_addrs) "@"] 0]
                ##code  OpenACS Developers:
                # object_id@domain is unconventional 
                # and may break if someone
                # uses an email beginning with a number.
                # Also, 'from' header could be spoofed..
                # This practice should be deprecated in favor of signed 
                # acs_mail_lite::unqiue_id_create.
                # For emails originating elsewhere, another authentication
                # method, such as a pre-signed unique-id in message
                # content could be added as well.
                # For now, we warn whenver this is used.
                if { [ad_var_type_check_number_p $pot_object_id] } {
                    if { [acs_object::object_p -id h_arr(aml_object_id)] } {
                        ns_log Warning "acs_mail_lite::inbound_queue_pull \
 Accepted insecure email object_id '${pot_object_id}' \
 array get h_arr '[array get h_arr]'. See code comments."
                        callback -catch acs_mail_lite::incoming_object_email \
                            -array h_arr \
                            -object_id $pot_object_id
                        set processed_p 1
                    }
                }
                if { !$processed_p } {
                    # Execute all callbacks for this email
                    
                    # Forums uses callbacks via notifications
                    # See callback 
                    # acs_mail_lite::incoming_email -imp notifications 
                    # in notifications/tcl/notification-callback-procs.tcl
                    # and
                    # notification::reply::get 
                    #  in forums/tcl/forum-reply-procs.tcl
                    #  which is defined in file:
                    # notifications/tcl/notification-reply-procs.tcl

                    #Callback acs_mail_lite::incoming_email bounces everything
                    # with a user_id.
                    # Its useful code has been added to
                    # acs_mail_lite::bounce_ministry.
                    # A new callback intended to be compatible with
                    # notification::reply::get (if possible) is invoked here
                    if { ![info exists h_arr(aml_package_id) ] } {
                        set h_arr(aml_package_id) $aml_package_id
                    }
                    set status [callback -catch acs_mail_lite::email_inbound \
                                    -header_array_name h_arr \
                                    -parts_array_name p_arr \
                                    -package_id $h_arr(aml_package_id) \
                                    -object_id $h_arr(aml_object_id) \
                                    -party_id $h_arr(aml_party_id) \
                                    -other $h_arr(aml_other) \
                                    -datetime_cs $h_arr(aml_datetime_cs)]
                    
                    if {"0" in $status} {
                        set error_p 1
                    }
                }
            }

            # Email is removed from queue when
            # set acs_mail_lite_from_external.processed_p 1.
            # Do not release if there was an error.
            # set acs_mail_lite_from_external.release_p !$error_p
            set not_error_p [expr { ! $error_p } ]
            db_dml acs_mail_lite_from_external_wproc {
                update acs_mail_lite_from_external
                set processed_p='1'
                and release_p=:not_error_p
                where acs_email_id=:acs_email_id
            }

            incr i
        }
        
    }

   return 1
}



ad_proc -private acs_mail_lite::inbound_queue_pull_one {
    -h_array_name:required
    -p_array_name:required
    -aml_email_id:required
    {-mark_processed_p "1"}
    {-legacy_array_name ""}
} {
    Puts email referenced by aml_email_id from the inbound queue into array
    of h_array_name and p_array_name for use by registered callbacks. 

    Arrays are repopulated with values in the same manner that
    acs_mail_lite::inbounde_queue_insert receives them. See below for details.
    
    When complete, marks the email in the queue as processed, 
    if mark_processed_p is 1.
    
    Array content corresponds to these tables:
    <pre>
    h_arr($name) $value         acs_mail_lite_ie_headers
    
    Some indexes match fields of table acs_mail_lite_from_external:

    h_arr(aml_email_id)     assigned by acs_mail_lite::inbound_queue_insert
    h_arr(aml_to)           to email including any label
    h_arr(aml_to_addrs)     to_email_addrs
    h_arr(aml_from)         from email including any label
    h_arr(aml_from_addrs)   from_email_addrs
    h_arr(aml_priority)     priority    
    h_arr(aml_subject)      email subject (normalized index reference).
    h_arr(aml_msg_id)       email message-id or msg-id's cross-reference
                            see acs_mail_lite_msg_id_map.msg_id
    h_arr(aml_size_chars)   size_chars
    
    Some headers are transferred from the email generation process.
    See acs_mail_lite::unique_id_create for details:

    h_arr(aml_package_id)
    h_arr(aml_party_id)
    h_arr(aml_object_id)
    h_arr(aml_other)
    

    Some headers are internally generated during input:
    
    h_arr(aml_type)         Type of email from acs_mail_lite::email_type
    h_arr(aml_received_cs)  Time received in seconds since Tcl epoch 
    h_arr(aml_datetime_cs)  Time unique_id generatd in seconds since Tcl epoch 
    h_arr(aml_processed_p)  processed_p
    h_arr(aml_priority)     a priority number assigned to email.

    Email parts (of body) are kept in a separate array:

    p_arr($section_ref,<field>)  acs_mail_lite_ie_parts (content of a part)
    p_arr($section_ref,nv_list)  acs_mail_lite_part_nv_pairs
    p_arr(section_ref_list) list of section_refs
    
    
    where index is section_ref based on section_ref, and
    where top most section_ref is a natural number as
    there may be more than one tree.
      
    Specifically, for p_arr array:

    content        is  p_arr($section_ref,content)
    c_type         is  p_arr($section_ref,c_type)
    filename       is  p_arr($section_ref,filename)
    c_filepathname is  p_arr($section_ref,c_filepathname)

    where:
    c_type is content-type header
    filename is filename of an attachment in email
    c_filepathname is the filepathname within the system.

    Each section may have headers:
    
    To avoid any header-name collision with content, c_type etc,
    headers are supplied in a name_value_list only:

    list of headers by section is  p_arr($section_ref,name_value_list) 
    list of section_refs       is  p_arr(section_ref_list) 

    For direct compatibility with legacy email systems that used:
    </pre><p>
    acs_mail_lite::email_parse, a compatible array is passed
    to legacy_array_name, if parameter is used.
    </p>
    @see acs_mail_lite::email_parse
} {
    upvar 1 $h_array_name h_arr
    upvar 1 $p_array_name p_arr
    if { $legacy_array_name ne "" } {
        upvar 1 $legacy_array_name l_arr
        set build_l_arr_p 1
        # Save data in l_arr according to acs_mail_lite::parse_email
        # in incoming-mail-procs.tcl
    } else {
        set build_l_arr_p 0
    }

    # This query may be redundant to some info in acs_mail_lite_ie_headers.
    # acs_mail_lite_from_external
    set x_list [db_list_of_lists acs_mail_lite_from_external_r1 {
        select priority, to_email_addrs, from_email_addrs,
        subject, msg_id,
        size_chars, received_cs, processed_p, release_p
        from acs_mail_lite_from_external
        where aml_email_id=:aml_email_id
    }]
    lassign $x_list h_arr(aml_priority) \
        h_arr(aml_to_email_addrs) \
        h_arr(aml_from_email_addrs) \
        h_arr(aml_subject) \
        h_arr(aml_msg_id) \
        h_arr(aml_size_chars) \
        h_arr(aml_received_cs) \
        h_arr(aml_processed_p) \
        h_arr(aml_release_p) 

    # collect from acs_mail_lite_ie_headers
    set h_lists [db_list_of_lists acs_mail_lite_ie_headers_r1 {
        select h_name, h_value
        from acs_mail_lite_ie_headers
        where aml_email_id=:aml_email_id } ]
    set h_names_ul [list ]
    foreach {n v} $h_lists {
        set h_arr(${n}) "${v}"
        lappend h_names_ul $n
    }

    if { $build_l_arr_p } {
        set l_headers_ul [array get h_arr]
        lappend l_headers_ul message-id $h_arr(aml_msg_id)
        lappend l_headers_ul subject $h_arr(aml_subject)
        lappend l_headers_ul from $h_arr(aml_from_email_addrs)
        lappend l_headers_ul to $h_arr(aml_to_email_addrs)
        # provide lowercase of some headers if they exist
        set to_lc_list [list date references in-reply-to return-path]
        foreach tol $to_lc_list {
            set tol_idx [lsearch -exact -nocase $h_names_ul $tol ]
            if { $tol > -1 } {
                set tol_ref [lindex $h_names_ul $tol_idx]
                lappend l_headers_ul $tol $h_arr(${tol_ref})
            } 
        }
        if { $h_arr(received_cs) ne "" } {
            lappend l_headers_ul received [clock format $h_arr(received_cs) ]
        }
        set l_arr(headers) $l_headers_ul
    }

    # collect from acs_mail_lite_ie_parts
    set p_lists [db_list_of_lists acs_mail_lite_ie_parts_r1 {
        select section_id,c_type,filename,content,c_filepathname
        from acs_mail_lite_ie_parts
        where aml_email_id=:aml_email_id } ]
    foreach row $p_lists {
        set section_ref [acs_mail_lite::seciton_ref_of [lindex $row 0]]
        set p_arr(${section_ref},c_type) [lindex $row 1]
        set p_arr(${section_ref},filename) [lindex $row 2]
        set p_arr(${section_ref},content) [lindex $row 3]
        set p_arr(${section_ref},c_filepathname) [lindex $row 4]
        if { $section_ref ni $p_arr(section_ref_list) } {
            lappend p_arr(section_ref_list) $section_ref
        }
    }
    # collect from acs_mail_lite_ie_part_nv_pairs
    set nvp_lists [db_list_of_lists acs_mail_lite_ie_part_nv_pairs_r1 {
        select section_id, p_name, p_value
        from acs_mail_lite_ie_part_nv_pairs
        where aml_email_id=:aml_email_id } ]
    set reserved_fields_ul [list content c_type filename c_filename]
    foreach row $nvp_lists {
        set section_ref [acs_mail_lite::section_ref_of [lindex $row 0]]
        set name [lindex $row 1]
        set value [lindex $row 2]
        if { $name ni $reserved_fields_ul } {
            lappend p_arr(${section_ref},name_value_list) $name $value
        }
        if { $section_ref ni $p_arr(section_ref_list) } {
            lappend p_arr(section_ref_list) $section_ref
        }
    }
    if { $build_l_arr_p } {
        # Legacy approach assumes "application/octet-stream"
        # for all attachments and
        # base64 for encoding of all files.
        #
        # Encoding has already been handled for files before queing.

        # Legacy approach replaces nested parts with flat list
        # from parse_email:
        #   The bodies consists of a list with two elements: 
        #     content-type and content.
        #   The files consists of a list with three elements:
        #     content-type, filename and content.

        set bodies_list [list]
        set files_list [list]
        set default_encoding [encoding system]
        foreach part $p_arr(section_ref_list) {

            lappend bodies_list [list \
                                     $p_arr(${section_ref},c_type) \
                                     $p_arr(${section_ref},content) ]
            # check for local filename
            if { $p_arr(${section_ref},c_filepathname) ne "" } {
                # Since this is saved as a file and already decoded, 
                # guess content_type from file
                # instead of assuming content type is same
                # as type used in email transport.
                set content_type [ns_guesstype $p_arr(${section_ref},c_filepathname)]
                
                lappend files_list [list \
                                        $content_type \
                                        $default_encoding \
                                        $p_arr(${section_ref},filename) \
                                        $p_arr(${section_ref},c_filepathname) ]
                                    
            }
        }
        set l_arr(bodies) $bodies_list
        set l_arr(files) $files_list
    }

    return 1
}

ad_proc -private acs_mail_lite::inbound_queue_release {
} {
    Delete email from queue that have been flagged 'release'.

    This does not affect email via imap or other connections.
    
} {
    # To flag 'release', set acs_mail_lite_from_external.release_p 1
 
    set aml_ids_list [db_list acs_mail_lite_from_external_rn {
        select aml_email_id from acs_mail_lite_from_external
        where release_p='1' }]
    foreach aml_email_id $aml_ids_list {
        db_transaction {
            db_dml acs_mail_lite_from_external_dn {
                delete from acs_mail_lite_from_external
                where aml_email_id=:aml_email_id
            }
            db_dml acs_mail_lite_ie_headers_dn {
                delete from acs_mail_lite_ie_headers
                where aml_email_id=:aml_email_id
            }
            db_dml acs_mail_lite_ie_parts_dn {
                delete from acs_mail_lite_ie_parts
                where aml_email_id=:aml_email_id
            }
            db_dml acs_mail_lite_ie_part_nv_pairs_dn {
                delete from acs_mail_lite_ie_part_nv_pairs
                where aml_email_id=:aml_email_id
            }
        } on_error {
            ns_log Error "acs_mail_lite::inbound_queue_release. \
 Unable to release aml_mail_id '${aml_email_id}'. Error is: ${errmsg}"
        }
    }
    return 1
}


ad_proc -private acs_mail_lite::inbound_filters {
    -headers_arr_name
} {
    Flags to ignore an inbound email that does not pass filters.
    Returns 1 if email should be ignored, otherwise returns 0.

    Headers and values are not alphanumeric case sensitive.

    Inbound filters are dynamically updated via 
    acs_mail_lite::sched_parameters.

    Instead of rejecting, an email can be filtered to low priority
    by using acs_mail_lite::inbound_prioritize parameters
    
    @see acs_mail_lite::sched_parameters
    @see acs_mail_lite::inbound_prioritize
} {
    upvar 1 $headers_arr_name h_arr
    set reject_p 0
    set headers_list [array names h_arr]

    set p_lists [acs_mail_lite::sched_parameters]
    
    # For details on these filters, see tables:
    #      acs_mail_lite_ui.reject_on_hit
    #                      .reject_on_miss

    # h = hit
    set h_list [dict values $p_lists reject_on_hit]
    set h_names_list [list ]
    foreach {n v} $h_list {
        set n_idx [lsearch -nocase -exact $headers_list $n]
        if { $n_idx > -1 } {
            set h [lindex $n_idx]
            lappend h_names_list $h
            set vh_arr(${h}) $v
        }
    }
    set h_names_ct [llength $h_names_list]
    set i 0
    while { !$reject_p && $i < $h_names_ct } {
        set h [lindex $h_names_list $i]
        if { [string match -nocase $vh_arr(${h}) $h_arr(${h})] } {
            set reject_p 1
        }
        
        incr i
    }


    # m = miss
    set m_list [dict values $p_lists reject_on_miss]
    set m_names_list [list ]
    foreach {n v} $m_list {
        set n_idx [lsearch -nocase -exact $headers_list $n]
        if { $n_idx > -1 } {
            set h [lindex $n_idx]
            lappend m_names_list $h
            set vm_arr(${h}) $v
        }
    }
    set m_names_ct [llength $m_names_list]
    set i 0
    while { !$reject_p && $i < $m_names_ct } {
        set h [lindex $m_names_list $i]
        if { ![string match -nocase $vm_arr(${h}) $h_arr(${h})] } {
            set reject_p 1
        }
        
        incr i
    } 
    
    return $reject_p
}


ad_proc -private acs_mail_lite::inbound_cache_clear {
} {
    Clears table of all email uids for all history.
    All unread input emails will be considered new and reprocessed.
    To keep history, just temporarily forget it instead:
    append a revision date to acs_mail_lite_email_src_ext_id_map.src_ext
    <br/><br/>
    If you are not sure if this will do what you want, try setting
    reprocess_old_p to '1'.
    @see acs_mail_lite::sched_parameters
    
} {
    db_dml acs_mail_lite_email_uid_map_d {
        update acs_mail_lite_email_uid_id_map {
            delete from acs_mail_lite_email_uid_id_map
            
        }
    }
    return 1
}


ad_proc -private acs_mail_lite::inbound_cache_hit_p {
    email_uid
    uidvalidity
    mailbox_host_name
} {
    Check email unqiue id (UID) against history in table.
    If already exists, returns 1 otherwise 0.
    Adds checked case to cache if not already there.

    uidvalidity is defined by imap rfc3501 2.3.1.1
    https://tools.ietf.org/html/rfc3501#section-2.3.1.1
    Other protocols have an analog mechanism, or one
    can be made locally to be equivallent in use.
} {
    set hit_p 0
    set src_ext $mailbox_host_name
    append src_ext "-" $uidvalidity
    set aml_src_id ""
    db_0or1row -cache_key aml_in_src_id_${src_ext} \
        acs_mail_lite_email_src_ext_id_map_r1 {
            select aml_src_id from acs_mail_lite_email_src_ext_id_map
            where src_ext=:src_ext }
    if { $aml_src_id eq "" } {
        set aml_src_id [db_nextval acs_mail_lite_in_id_seq]
        db_dml acs_mail_lite_email_src_ext_id_map_c1 {
            insert into acs_mail_lite_email_src_ext_id_map
            (aml_src_id,src_ext)
            values (:aml_src_id,:src_ext)
        }
    }
    set aml_email_id ""
    db_0or1row acs_mail_lite_email_uid_id_map_r1 {
        select aml_email_id from acs_mail_lite_email_uid_id_map
        where uid_ext=:email_uid
        and src_ext_id=:aml_src_id
    }
    if { $aml_email_id eq "" } {
        set aml_email_id [db_nextval acs_mail_lite_in_id_seq]
        db_dml acs_mail_lite_email_uid_id_map_c1 {
            insert into acs_mail_lite_email_uid_id_map
            (aml_email_id,uid_ext,src_ext_id)
            values (:aml_email_id,:email_uid,:aml_src_id)
        }
    } else {
        set hit_p 1
    }
    return $hit_p
}

ad_proc -private acs_mail_lite::section_ref_of {
    section_id
} {
    Returns section_ref represented by section_id.
    Section_id is an integer. 
    Section_ref has format of counting numbers separated by dot.
    First used here by ns_imap body and adopted for general email part refs.

    Defaults to empty string (top level reference and a log warning) 
    if not found.
} {
    set section_ref ""
    set exists_p 0
    if { [string is wideinteger -strict $section_id] } {
        if { $section_id eq "-1" } {
            set exists_p 1
        } else {
            
            set exists_p [db_0or1row acs_mail_lite_ie_section_ref_map_r_id1 {
                select section_ref 
                from acs_mail_lite_ie_section_ref_map
                where section_id=:section_id
            } ]
        }
    }
    if { !$exists_p } {
        ns_log Warning "acs_mail_lite::section_ref_of '${section_id}' not found."
    }
    return $section_ref
}

ad_proc -private acs_mail_lite::section_id_of {
    section_ref
} {
    Returns section_id representing a section_ref.
    Section_ref has format of counting numbers separated by dot.
    Section_id is an integer. 
    First used here by ns_imap body and adopted for general email part refs.
} {
    set section_id ""
    if { [regexp -- {^[0-9\.]*$} $section_ref ] } {
        
        if { $section_ref eq "" } {
            set section_id -1
        } else {
            set ckey aml_section_ref_
            append ckey $section_ref
            set exists_p [db_0or1row -cache_key $ckey \
                              acs_mail_lite_ie_section_ref_map_r1 {
                                  select section_id 
                                  from acs_mail_lite_ie_section_ref_map
                                  where section_ref=:section_ref
                              } ]
            if { !$exists_p } {
                db_flush_cache -cache_key_pattern $ckey
                set section_id [db_nextval acs_mail_lite_in_id_seq]
                db_dml acs_mail_lite_ie_section_ref_map_c1 {
                    insert into acs_mail_lite_ie_section_ref_map
                    (section_ref,section_id)
                    values (:section_ref,:section_id)
                }
            }
        }
    }
    return $section_id
}

ad_proc -private acs_mail_lite::unique_id_create {
    {-unique_id ""}
    {-package_id ""}
    {-party_id ""}
    {-object_id ""}
    {-other ""}
} {
    Returns a unique_id for an outbound email header message-id.
    Signs unique_id when package_id, party_id, object_id, and/or other info are supplied. party_id is not supplied if its value is empty string or 0. 
    package_id not supplied when it is the default acs-mail-lite package_id. 
    If unique_id is empty string, creates a unique_id then processes it.

} {
    # remove quotes, adjust last_at_idx
    if { [string match "<*>" $unique_id] } {
        set unique_id [string range $unique_id 1 end-1]
    }
    set envelope_prefix [acs_mail_lite::bounce_prefix ]
    if { ![string match "${envelope_prefix}*" $unique_id ] } {
        set unique_id2 $envelope_prefix
        append unique_id2 $unique_id
        set unique_id $unique_id2
    }
    set last_at_idx [string last "@" $unique_id]
    if { $last_at_idx < 0 } {
        set unique_id $envelope_prefix
        append unique_id [string range [mime::uniqueID] 1 end-1]
        set last_at_idx [string last "@" $unique_id]
    }

    set bounce_domain [acs_mail_lite::address_domain]
    if { [string range $unique_id $last_at_idx+1 end-1] ne $bounce_domain } { 
        # Use bounce's address_domain instead
        # because message-id may also be used as originator
        set unique_id [string range $unique_id 0 $last_at_idx]
        append unique_id $bounce_domain
    }

    set aml_package_id [apm_package_id_from_key "acs-mail-lite"]
    if { ( $package_id ne "" && $package_id ne $aml_package_id ) \
             || ( $party_id ne "" && $party_id ne "0" ) \
             || $object_id ne "" \
             || $other ne "" } {
        # Sign this message-id, and map message-id to values
        set uid [string range $unique_id 0 $last_at_idx-1]
        set domain [string range $unique_id $last_at_idx+1 end]

        set uid_list [split $uid "."]
        if { [llength $uid_list] == 3 } {
            # Assume this is a unique id from mime::uniqueID
            
            # Replace clock seconds of uniqueID with a random integer
            # since cs is used to build signature, which defeats purpose.
            set uid_partial [lindex $uid_list 0]
            # Suppose:
            # max_chars = at least the same as length of clock seconds
            # It will be 10 for a while..
            # so use eleven 9's
            # Some cycles are saved by using a constant
            append uid_partial "." [randomRange 99999999999] 
            append uid_partial "." [lindex $uid_list 2]

            set uid $uid_partial
        }

        # Just sign the uid part
        set max_age [parameter::get -parameter "IncomingMaxAge" \
                         -package_id $aml_package_id ]
        ns_log Dev "acs_mail_lite::unique_id_create max_age '${max_age}'"
        if { $max_age eq "" || $max_age eq "0" } {
            # A max_age of 0 or '' expires instantly.
            # User expects signature to not expire.
            set signed_unique_id_list [ad_sign $uid]
            set delim "-"
        } else {
            set signed_unique_id_list [ad_sign -max_age $max_age $uid]
            set delim "+"
        }
        set signed_unique_id [join $signed_unique_id_list $delim]

        # Since signature is part of uniqueness of unique_id, 
        # use uid + signature for msg_id
        set msg_id $uid
        append msg_id "-" $signed_unique_id 

        set datetime_cs [clock seconds]
        db_dml acs_mail_lite_send_msg_id_map_w1 {
            insert into acs_mail_lite_send_msg_id_map
            (msg_id,package_id,party_id,object_id,other,datetime_cs)
            values (:msg_id,:package_id,:party_id,:object_id,:other,:datetime_cs)
        }
        set unique_id "<"
        append unique_id $msg_id "@" $domain ">"
    } 
    return $unique_id
}

ad_proc -private acs_mail_lite::unique_id_parse {
    -message_id:required
} {
    Parses a message-id compatible reference 
    created by acs_mail_lite::unique_id_create.
    Returns package_id, party_id, object_id, other, datetime_cs in a name value list.

    datetime_cs is approximate system time in seconds from epoch when header was created.

    @see acs_mail_lite::unique_id_create
} {
    if { [string match "<*>" $message_id] } {
        # remove quote which is not part of message id according to RFCs
        set message_id [string range $message_id 1 end-1]
    }
    set return_list [list ]
    lassign $return_list package_id party_id object_id other datetime_cs

    set last_at_idx [string last "@" $message_id]
    
    set domain [string range $message_id $last_at_idx+1 end]
    set unique_part [string range $message_id 0 $last_at_idx-1]
    set first_dash_idx [string first "-" $unique_part]
    
    if { $first_dash_idx > -1 } {
        # message-id is signed.
        ns_log Dev "acs_mail_lite::unique_id_parse message_id '${message_id}'"
        set unique_id [string range $unique_part 0 $first_dash_idx-1]
        set signature [string range $unique_part $first_dash_idx+1 end]
        set sign_list [split $signature "-+"]
        
        if { [llength $sign_list] == 3 } {
            # signature is in good form
            # Use the signature's delimiter instead of param IncomingMaxAge
            # so that this works even if there is a change in param value
            #set aml_package_id /apm_package_id_from_key "acs-mail-lite"/
            #set max_age /parameter::get -parameter "IncomingMaxAge" \
            #                 -package_id $aml_package_id /
            #ns_log Dev "acs_mail_lite::unique_id_parse max_age '${max_age}'"
            # if max_age is "" or "0" delim is "-". 
            #    See acs_mail_lite::unique_id_create
            if { [string first "-" $signature] } {
                # A max_age of 0 or '' expires instantly.
                # User expects signature to not expire.
                set expiration_cs [ad_verify_signature $unique_id $sign_list]
            } else {

                set expiration_cs [ad_verify_signature_with_expr $unique_id $sign_list]
            }
            if { $expiration_cs > 0 } {
                set p_lists [db_list_of_lists \
                                 acs_mail_lite_send_msg_id_map_r1all {
                                     select package_id,
                                     party_id,
                                     object_id,
                                     other,
                                     datetime_cs
                                     from acs_mail_lite_send_msg_id_map
                                     where msg_id=:unique_part } ]
                set p_list [lindex $p_lists 0]

                lassign $p_list package_id party_id object_id other datetime_cs
            } else {
                ns_log Dev "acs_mail_lite::unique_id_parse unverified signature unique_id '${unique_id}' signature '${sign_list}' expiration_cs '${expiration_cs}'"
            }
            set bounce_domain [acs_mail_lite::address_domain]
            if { $bounce_domain ne $domain } {
                ns_log Warning "acs_mail_lite::unique_id_parse \
 message_id '${message_id}' is not from '@${bounce_domain}'"
            }
        } else {
            ns_log Dev "acs_mail_lite::unique_id_parse \
 not in good form signature '${signature}'"
        }
    } else {
        set unique_id $unique_part
        set uid_list [split $unique_id "."]
        if { [llength $uid_list] == 3 } {
            # assume from a mime::uniqueID
            set date_time_cs [lindex $uid_list 1]
        } else {
            set date_time_cs ""
        }
        
    } 
    set r_list [list \
                    package_id $package_id \
                    party_id $party_id \
                    object_id $object_id \
                    other $other \
                    datetime_cs $datetime_cs ]
    return $r_list
}


ad_proc -private acs_mail_lite::inbound_email_context {
    -header_array_name
    {-header_name_list ""}

} {
    Returns openacs data associated with original outbound email in
    the header_array_name and as an ordered list of values:

    package_id, party_id, object_id, other, datetime_cs 

    datetime_cs is the time in seconds since tcl epoch.

    other can be most any data represented in sql text.

    By accessing all email headers, various scenarios of OpenACS sender
    and replies can be checked to increase likelihood of retrieving
    data in context of email.

    Array indexes have suffix aml_ added to index name:
    aml_package_id, aml_party_id, aml_object_id, aml_other, aml_datetime_cs 

    If a value is not found, an empty string is returned for the value.

    @see acs_mail_lite::unique_id_create
    @see acs_mail_lite::unique_id_parse

} {
    upvar 1 $header_array_name h_arr
    if { $header_name_list eq "" } {
        set header_name_list [array names h_arr]
    } 

    # Here are some procs that help create a message-id or orginator
    # or generated unique ids from inbound email headers
    # that are of historical importance in helping
    # shape this proc.
    #    acs_mail_lite::unique_id_create (current)
    #    acs_mail_lite::unique_id_parse (current)
    #    acs_mail_lite::generate_message_id
    #    acs_mail_lite::bounce_address
    #    acs_mail_lite::parse_bounce_address
    #    notification::email::reply_address_prefix
    #    notification::email::reply_address
    #    notification::email::address_domain
    #    notification::email::send
    #    acs_mail_lite::send
    #    mime::uniqueID
    #    acs_mail_lite::send_immediately



    # This proc should be capable of integrating with MailDir based service
    # whether as a legacy support or current choice (instead of IMAP).



    # Note for imap paradigm: message-id should be in form:
    # <unique_id@local_domain.example>
    # and unqiue_id should map to 
    # any package, party and/or object_id so
    # as to not leak info unnecessarily.
    # See table acs_mail_lite_send_msg_id_map
    # and acs_mail_lite::unique_id_create/find/parse


    # Bounce info needs to be placed in an rfc
    # compliant header. Replies can take many forms.
    # This could be a mess.
    # If a service using MailDir switches to use IMAP,
    # should we still try to make the MailDir work?
    # Should this work with MailDir regardless of IMAP?
    # Yes and yes.
    # This should be as generic as possible and include legacy permutations.

    # General constraints:
    # Header field characters limited to US-ASCII characters between 33 and 126
    # inclusive per rfc5322 2.2 https://tools.ietf.org/html/rfc5322#section-2.2
    # and white-space characters 32 and 9.

    # Per rfc6532 3.3 and 5322 2.1.1, "Each line of characters must be no more
    # than 998 characters, and should be no more than 78 characters.."
    # A domain name can take up to 253 characters.

    # Setting aside about 60 characters for a signature for a signed message-id
    # should be okay even though it almost guarantees all cases of message_id
    # will be over 78 characters.

    # Unique references are case sensitive per rfc3464 2.2.1
    # original email's envelope-id value is case sensitive per rfc3464 2.2.1
    # Angle brackets are used to quote a unique reference


    # According to RFCs,
    # these are the headers to check in a reply indicating original context:

    # original-message-id
    # original-envelope-id  
    # message-id            a unique message id per rfc2822 3.6.4
    #                       assigned by originator per rfc5598 3.4.1
    #                        https://tools.ietf.org/html/rfc5598#section-3.4.1
    #
    # originator            A special case alternate to 'From' header.
    #                       Usually defined by first SMTP MTA.
    #                       Notices may be sent to this address when
    #                       a bounce notice to the original email's 'From'
    #                       address bounces.
    #                       See RFC5321 2.3.1 
    #                        https://tools.ietf.org/html/rfc5321#section-2.3.1
    #                       and RFC5598 2.2.1 
    #                        https://tools.ietf.org/html/rfc5598#section-2.1
    # msg-id
    # In-Reply-to  space delimited list of unique message ids per rfc2822 3.6.4
    # References   space delimited list of unique message ids per rfc2822 3.6.4
    #
    # original-recipient    may contain original 'to' address of party_id
    # original-recipient-address
    #                       is an alternate to original-recipient 
    #                       used by rfc3461 4.2 
    #                        https://tools.ietf.org/html/rfc3461#section-4.2
    #                      Recipient could be used as an extra layer 
    #                       of authentication after parsing.
    #                      for example
    #                       'from' header is built as:
    #                        party::email -party-id user_id
    #                        in page: forums/www/message-email.tcl
    #

    # check_list should be prioritized to most likely casees first.
    set check_list [list \
                        original-message-id \
                        original-envelope-id \
                        originator \
                        message-id \
                        msg-id \
                        in-reply-to \
                        references \
                       ]
    #
    #
    #
    # existing oacs-5-9 'MailDir' ways to show context or authenticate origin:
    #


    # acs-mail-lite::send_immediately 
    # 'from' header defaults to acs_mail_lite parameter FixedSenderEmail
    # 'Reply-to' defaults to 'from' header value.
    # adds a different unique id to 'Return-Path'.
    # example: <bounce-lite-49020-5AA3B467C31BBE655281220B0583195B52956B70-2578@openacs.org>
    # address is built using acs_mail_lite::bounce_address
    # Parsing is done with:
    # acs_mail_lite::parse_bounce_address /acs_mail_lite::parse_email_address/
    # in callback acs_mail_lite::incoming_email -impl acs-mail-lite
    # message-id
    # Content-ID
    # adds same unique id to 'message-id' and 'content-id'.
    # example: <17445.1479806245.127@openacs.wu-wien.ac.at.wu-wien.ac.at>

    # Content-ID is added by proc:  build_mime_message
    # which relies on tcllib mime package
    # in file acs-tcl/tcl/html-email-procs.tcl
    # message-id is built by acs_mail_lite::generate_message_id
    #                     or mime::uniqueID 
    #              and used in acs_mail_lite::send_immediately 

    # acs_mail_lite::generate_message_id:
    #     return "/clock clicks/./ns_time/.oacs@/address_domain/>"
    # mime::uniqueID: 
    #     return "</pid/./clock seconds/./incr mime(cid)/@/info hostname/>"
    #     is defined in ns/lib/tcllib1.18/mime/mime.tcl
    #     mime(cid) is a counter that incriments by one each time called.

    lappend check_list content-id
    

    # To make acs_mail_lite_send_msg_id_map more robust,
    # should it be designed to import other references via a table map
    # so external references can be used?   No.

    # Replaced generic use of mime::uniqueID 
    # with acs_mail_lite::unique_id_create
    # Don't assume acs_mail_lite::valid_signature works. It appears to check
    # an unknown form and is orphaned (not used).


    #
    # Notifications package
    #
    # reply-to
    # Mail-Followup-To
    # parameter NotificationSender defaults to
    #     remainder@ acs_mail_lite::address_domain 
    # which defaults to:
    #   remainder@ parameter BounceDomain
    #   if set, otherwise to a driver hostname
    # which..
    # adds the same unique id to 'reply-to' and 'mail-followup-to'

    # message-id is a way to generate a dynamic reply-to.

    # example: "openacs.org mailer" <notification-5342759-2960@openacs.org>
    # apparently built in notification::email::send
    # located in file notifications/tcl/notification-email-procs.tcl
    # reply_to built by calling local notification::email::reply_address
    # where:
    # if $object_id or $type_id is empty string:
    #" /address_domain/ mailer \
    #    </reply_address_prefix/@/address_domain/>"
    # else
    # "/address_domain/ mailer \
    #    </reply_address_prefix/-$object_id-$type_id@/address_domain/>"
    # where address_domain gets notifications package parameter EmailDomain
    # and defaults to domain from ad_url
    # and where reply_address_prefix gets
    # notifications package parameter EmailReplyAddressPrefix
    # Mail-Followup-To is set to same value, then calls acs_mail_lite::send

    lappend check_list mail-followup-to to

    # Contribute x-envelope-from from legacy case in
    # acs_mail_lite::bounce_prefix?
    # No. It's only referenced in a proc doc comment.
    # lappend check_list x-envelope-from


    #
    # A legacy parameter from acs_mail_lite::parse_bounce_address
    #
    set bounce_prefix [acs_mail_lite::bounce_prefix]
    set regexp_str "\[${bounce_prefix}\]-(\[0-9\]+)-(\[^-\]+)-(\[0-9\]*)\@"

    #
    # setup for loop that checks headers
    #

    set context_list [list ]
    set check_list_len [llength $check_list]
    set header_id 0
    set prefix "aml_"
    set h_arr(aml_datetime_cs) ""

    # Check headers for signed context
    while { $header_id < $check_list_len && $h_arr(aml_datetime_cs) eq "" } {
        set header [lindex $check_list $header_id]
        set h_idx [lsearch -exact -nocase $header_name_list $header]
        if { $h_idx > -1 } {
            set h_name [lindex $check_list $h_idx] 

            # hv = header value
            if { $header eq "references" } {
                # references header may contain multiple message-ids
                set hv_list [split $h_arr(${h_name}) ]
            } else {
                # header has one vale
                set hv_list [list $h_arr(${h_name})]
            }
            set hv_list_len [llength $hv_list]
            set hv_i 0
            while { $hv_i < $hv_list_len && $h_arr(aml_datetime_cs) eq "" } {
                set hv [lindex $hv_list $hv_i]
                # remove quoting angle brackets if any
                if { [string match "<*>" $hv ] } {
                    set hv [string range $hv 1 end-1]
                } 
                set context_list [acs_mail_lite::unique_id_parse \
                                      -message_id $hv]
                if { $h_arr(aml_datetime_cs) eq "" \
                         && [string match "${bounce_addrs}*" $hv] } {


                    ##code developers of OpenACS core:
                    # Legacy case should be removed for strict, secure
                    # handling of context info
                    
                    # Check legacy case
                    # Regexp code is from acs_mail_lite::parse_bounce_address
                    if { [regexp $regexp_str $hv \
                              all user_id signature package_id] } {
                        set context_list [list \
                                              package_id $package_id \
                                              party_id $user_id \
                                              object_id "" \
                                              other "" ]
                        set sig_list [split $signature "."]
                        set sig_1 [lindex $sig_list 1]
                        if { [llength $sig_list ] == 3 \
                                 && [string is wideinteger -strict $sig_1] } {
                            lappend context_list datetime_cs $sig_1
                        } else {
                            lappend context_list datetime_cs [clock seconds]
                        }
                    }
                }
                # prefix = "aml_" as in cname becomes:
                #  aml_package_id aml_party_id aml_object_id aml_other aml_datetime_cs
                foreach {n v} $context_list {
                    set cname $prefix
                    append cname $n
                    set h_arr(${cname}) $v
                }
                
                incr hv_i
            }
        }

        incr header_id
    }

    return $context_list
}

ad_proc acs_mail_lite::bounce_ministry {
    -header_array_name:required
} {
    Check if this email is notifying original email bounced.
    If is a bounced notification, process it.

    Returns 1 if bounced or an auto generated reply that 
    should be ignored, otherwise returns 0

    Expects header_array to have been previously processed by these procs:

    @see acs_mail_lite::email_type
    @see acs_mail_lite::inbound_email_context
} {
    upvar 1 $header_array_name h_arr
    # This is called ministry, because it is expected to grow in complexity
    # as bounce policy becomes more mature.

    # The traditional OpenACS MailDir way: 
    # code in acs_mail_lite::load_mails 
    # in which, if there is a bounce, calls: 
    # acs_mail_lite::record_bounce
    # and later batches some admin via
    # acs_mail_lite::check_bounces
    # This approach likely does not work for 
    # standard email accounts where a FixedSenderEmail is expected and
    # a dynamic (unstatic) email
    # would bounce back again and therefore never be reported in system.

    # Specfics of the old way:
    # acs_mail_lite::record_bounce which calls:
    # acs_mail_lite::bouncing_user_p -user_id $h_arr(aml_user_id)

    # bounces are checked from the inbound queue
    # before checking other cases that may trigger callbacks


    set aml_list [list \
                      aml_package_id \
                      aml_party_id \
                      aml_object_id \
                      aml_other \
                      aml_type \
                      aml_to_addrs \
                      aml_from_addrs \
                      aml_datetime_cs ]
    foreach idx $aml_list {
        if { ![info exists h_arr(${idx})] } {
            set h_arr(aml_package_id) ""
        }
    }

    set ignore_p 0
    if { $h_arr(aml_type) ne "" && $h_arr(aml_type) ne "in_reply_to" } {
        set ignore_p 1
        # Record bounced email?
        set party_id_from_addrs [party::get_by_email \
                                     -email $h_arr(aml_from_addrs)]
        
        if { $party_id_from_addrs ne "" } {
            set user_id $party_id_from_addrs 
            if { ![acs_mail_lite::bouncing_user_p -user_id $user_id ] } {

                # Following literally from acs_mail_lite::record_bounce
                ns_log Debug "acs_mail_lite::bounce_ministry.2264 \
  Bouncing email from user '${user_id}'"
                # record the bounce in the database
                db_dml record_bounce {}
                if { ![db_resultrows]} {
                    db_dml insert_bounce {}
                }
                # end code from acs_mail_lite::record_bounce

                if { $h_arr(aml_party_id) ne $user_id \
                         || $h_arr(aml_datetime_cs) eq "" } {
                    # Log it, because it might be a false positive.
                    # Existence of aml_datetime_cs means unique_id was signed.
                    # See acs_mail_lite::unique_id_parse
                    ns_log Warning "acs_mail_lite::bounce_ministry.2275 \
 Bounced email apparently from user_id '${user_id}' \
 with headers: '[array get h_arr]'"

                }
            }
            
        } else {
            # This is probably a bounce, but not from a recognized party
            # Log it, because it might help with email related issues.
            ns_log Warning "acs_mail_lite::bounce_ministry.2287 \
  email_type '$h_arr(aml_type)' ignored. headers: '[array get h_arr]'"

        }
    }
   

    return $ignore_p
}

#            
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

