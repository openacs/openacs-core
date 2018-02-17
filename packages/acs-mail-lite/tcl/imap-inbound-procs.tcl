ad_library {

    Provides API for importing email via nsimap
    
    @creation-date 19 Jul 2017
    @cvs-id $Id$

}

#package require mime 1.4  ? (no. Choose ns_imap option if available
# at least to avoid tcl's 1024 open file descriptors limit[1].
# 1. http://openacs.org/forums/message-view?message_id=5370874#msg_5370878
# base64 and qprint encoding/decoding available via:
# ns_imap encode/decode type data

namespace eval acs_mail_lite {}


ad_proc -private acs_mail_lite::imap_conn_set {
    {-host ""}
    {-password ""}
    {-port ""}
    {-timeout ""}
    {-user ""}
    {-name_mb ""}
    {-flags ""}
} {
    Returns a name value list of parameters
    used by ACS Mail Lite imap connections

    If a parameter is passed with value, the value is assigned to parameter.
    
    @param name_mb See nsimap documentaion for mailbox.name. 
    @param port Ignored for now. SSL automatically switches port.
} {
    # See one row table acs_mail_lite_imap_conn
    # imap_conn_ = ic
    set ic_list [list \
                     host \
                     password \
                     port \
                     timeout \
                     user \
                     name_mb \
                     flags]
    # ic fields = icf
    set icf_list [list ]
    foreach ic $ic_list {
        set icf [string range $ic 0 1]
        lappend icf_list $icf
        if { [info exists $ic] } {
            set new_arr(${ic}) [set $ic]
        }
    }
    set changes_p [array exists new]
    set exists_p [db_0or1row acs_mail_lite_imap_conn_r {
        select ho,pa,po,ti,us,na,fl
        from acs_mail_lite_imap_conn limit 1
    } ]
    
    if { !$exists_p } {
        # set initial defaults
        set mb [ns_config nsimap mailbox ""]
        set mb_good_form_p [regexp -nocase -- \
                                {^[{]([a-z0-9\.\/]+)[}]([a-z0-9\/\ \_]+)$} \
                                $mb x ho na] 
        # ho and na defined by regexp?
        set ssl_p 0
        if { !$mb_good_form_p } {
            ns_log Notice "acs_mail_lite::imap_conn_set.463. \
 config.tcl's mailbox '${mb}' not in good form. \
 Quote mailbox with curly braces like: {{mailbox.host}mailbox.name} "
            set mb_list [acs_mail_lite::imap_mailbox_split $mb]
            if { [llength $mb_list] eq 3 } {
                set ho [lindex $mb_list 0]
                set na [lindex $mb_list 1]
                set ssl_p [lindex $mb_list 2]
                ns_log Notice "acs_mail_lite::imap_conn_set.479: \
 Used alternate parsing. host '${ho}' mailbox.name '${na}' ssl_p '${ssl_p}'"
            } else {
                set ho [ns_config nssock hostname ""]
                if { $ho eq "" } {
                    set ho [ns_config nssock_v4 hostname ""]
                }
                if { $ho eq "" } {
                    set ho [ns_config nssock_v6 hostname ""]
                }
                set na "mail/INBOX"
                set mb [acs_mail_lite::imap_mailbox_join -host $ho -name $na]

                ns_log Notice "acs_mail_lite::imap_conn_set.482: \
 Using values from nsd config.tcl. host '${ho}' mailbox.name '${na}'"

            }
        }
        
        set pa [ns_config nsimap password ""]
        set po [ns_config nsimap port ""]
        set ti [ns_config -int nsimap timeout 1800]
        set us [ns_config nsimap user ""]
        if { $ssl_p } {
            set fl "/ssl"
        } else {
            set fl ""
        }
    }

    if { !$exists_p || $changes_p } {
        set validated_p 1
        set n_pv_list [array names new]
        if { $changes_p } {
            # new = n
            foreach n $n_pv_list {
                switch -exact -- $n {
                    port -
                    timeout {
                        if { $n_arr(${n}) eq "" } {
                            set v_p 1
                        } else {
                            set v_p [string is digit -strict $n_arr(${n})]
                            if { $v_p } {
                                if { $n_arr(${n}) < 0 } {
                                    set v_p 0
                                }
                            }
                        }
                    }
                    name_mb -
                    flags -
                    host -
                    password -
                    user {
                        if { $n_arr(${n}) eq "" } {
                            set v_p 1
                        } else {
                            set v_p [regexp -- {^[[:graph:]\ ]+$} $n_arr(${n})]
                            if { $v_p && \
                                     [string match {*[\[;]*} $n_arr(${n}) ] } {
                                set v_p 0
                            }
                        }
                    }
                    defaults {
                        ns_log Warning "acs_mail_lite::imap_conn_set \
 No validation check made for parameter '${n}'"
                    }
                }
                if { !$v_p } {
                    set validated_p 0
                    ns_log Warning "acs_mail_lite::imap_conn_set \
 value '$n_arr(${n})' for parameter '${n}' not allowed."
                }
            }
        }
        
        if { $validated_p } {
            foreach ic_n $n_pv_list {
                set ${ic_n} $n_arr($ic_n)
            }

            db_transaction {
                if { $changes_p } {
                    db_dml acs_mail_lite_imap_conn_d {
                        delete from acs_mail_lite_imap_conn
                    }
                }
                db_dml acs_mail_lite_imap_conn_i {
                    insert into acs_mail_lite_imap_conn 
                    (ho,pa,po,ti,us,na,fl)
                    values (:ho,:pa,:po,:ti,:us,:na,:fl)
                }
            }
        } 
    }
    set i_list [list ]
    foreach i $ic_list {
        set svi [string range $i 0 1]
        set sv [set ${svi}]
        lappend i_list ${i} $sv
    }
    return $i_list
}

ad_proc -private acs_mail_lite::imap_conn_go {
    {-conn_id ""}
    {-host ""}
    {-password ""}
    {-port ""}
    {-timeout ""}
    {-user ""}
    {-flags ""}
    {-name_mb ""}
    {-default_to_inbox_p "0"}
    {-default_box_name "inbox"}
} {
    Verifies connection (connId) is established.
    Tries to establish a connection if it doesn't exist.
    If mailbox doesn't exist, tries to find an inbox at root of tree
    or as close as possible to it.

    If -host parameter is supplied, will try connection with supplied params.
    Defaults to use connection info provided by parameters 
    via acs_mail_lite::imap_conn_set.

    @param port Ignored for now. SSL automatically switches port.

    @param default_to_inbox_p  If set to 1 and name_mb not found, \
        assigns an inbox if found.
    @param default_box_name Set if default name for default_to_inbox_p \
        should be something other than inbox.

    @return connectionId or empty string if unsuccessful.
    @see acs_mail_lite::imap_conn_set
} {
    # imap_conn_go = icg
    # imap_conn_set = ics
    if { $host eq "" } {
        set default_conn_set_p 1
        set ics_list [acs_mail_lite::imap_conn_set ]
        foreach {n v} $ics_list {
            set $n "${v}"
            ns_log Dev "acs_mail_lite::imap_conn_go.596. set ${n} '${v}'"
        }
    } else {
        set default_conn_set_p 0
    }

    set fl_list [split $flags " "]

    set connected_p 0
    set prior_conn_exists_p 0

    if { $conn_id ne "" } {
        # list {id opentime accesstime mailbox} ...
        set id ""
        set opentime ""
        set accesstime ""
        set mailbox ""

        set sessions_list [ns_imap sessions]
        set s_len [llength $sessions_list]
        ns_log Dev "acs_mail_lite::imap_conn_go.612: \
 sessions_list '${sessions_list}'"
        # Example session_list as val0 val1 val2 val3 val4 val5 val6..:
        #'40 1501048046 1501048046 {{or97.net:143/imap/tls/user="testimap1"}<no_mailbox>} 
        # 39 1501047978 1501047978 {{or97.net:143/imap/tls/user="testimap1"}<no_mailbox>}'
        set i 0
        while { $i < $s_len && $id ne $conn_id }  {
            set s_list [lindex $sessions_list 0]
            set id [lindex $s_list 0]
            if { $id eq $conn_id } {
                set prior_conn_exists_p 1
                set opentime [lindex $s_list 1]
                set accesstime [lindex $s_list 2]
                set mailbox [lindex $s_list 3]
            }
            incr i
        }
        if { $prior_conn_exists_p eq 0 } {
            ns_log Warning "acs_mail_lite::imap_conn_go.620: \
 Session broken? conn_id '${conn_id}' not found."
        }
    }

    if { $prior_conn_exists_p } {
        # Test connection.
        # status_flags = sf
        if { [catch { set sf_list [ns_imap status $conn_id ] } err_txt ] } {
            ns_log Warning "acs_mail_lite::imap_conn_go.624 \
 Error connection conn_id '${conn_id}' unable to get status. Broken? \
 Set to retry. Error is: ${err_txt}"
            set prior_conn_exists_p 0
        } else {
            set connected_p 1
            ns_log Dev "acs_mail_lite::imap_conn_go.640: fl_list '${fl_list}'"
        }
    }
    
    if { !$prior_conn_exists_p && $host ne "" } {
        if { "ssl" in $fl_list } {
            set ssl_p 1
        } else {
            set ssl_p 0
        }
        set mb [acs_mail_lite::imap_mailbox_join \
                    -host $host \
                    -name $name_mb \
                    -ssl_p $ssl_p]
        if { "novalidatecert" in $fl_list } {
            if { [catch { set conn_id [ns_imap open \
                                           -novalidatecert \
                                           -mailbox "${mb}" \
                                           -user $user \
                                           -password $password] \
                          } err_txt ] \
                 } { ns_log Warning "acs_mail_lite::imap_conn_go.653 \
 Error attempting ns_imap open. Error is: '${err_txt}'" 
            } else {
                set connected_p 1
                ns_log Dev "acs_mail_lite::imap_conn_go.662: \
 new session conn_id '${conn_id}'"
            }
        } else {
            if { [catch { set conn_id [ns_imap open \
                                           -mailbox "${mb}" \
                                           -user $user \
                                           -password $password] \
                          } err_txt ] \
                 } { ns_log Warning "acs_mail_lite::imap_conn_go.653 \
 Error attempting ns_imap open. Error is: '${err_txt}'" 
            } else {
                set connected_p 1
                ns_log Dev "acs_mail_lite::imap_conn_go.675: \
 new session conn_id '${conn_id}'"
            }
        }

    }
    if { !$connected_p } {
        set conn_id ""
    } else {
        # Check if mailbox exists.
        set status_nv_list [ns_imap status $conn_id]
        array set stat_arr $status_nv_list
        set stat_n_list [array get names stat_arr]
        set msg_idx [lsearch -nocase -exact $stat_n_list "messages"]
        if { $msg_idx < 0 } {
            set mb_exists_p 0
            ns_log Warning "acs_mail_lite::imap_conn_go.723 \
 mailbox name '${name_mb}' not found."
            # top level = t
            set t_list [ns_imap list $conn_id $host {%}]
            ns_log Notice "acs_mail_lite::imap_conn_go.725 \
 available top level mailbox names '${t_list}'"
            if { [llength $t_list < 2] && !$default_to_inbox_p } {
                # Provide more hints. 
                set t_list [ns_imap list $conn_id $host {*}]
                ns_log Notice "acs_mail_lite::imap_conn_go.727 \
 available mailbox names '${t_list}'"
            }
        } else {
            set mb_exists_p 1
        }
        
        if { !$mb_exists_p && $default_to_inbox_p } {
            set mb_default ""
            set idx [lsearch -exact -nocase $t_list "${default_box_name}"]
            if { $idx < 0 } {
                set idx [lsearch -glob -nocase $t_list "${default_box_name}*"]
            }
            if { $idx < 0 } {
                set idx [lsearch -glob -nocase $t_list "*${default_box_name}*"]
            }
            if { $idx < 0 } {
                set t_list [ns_imap list $conn_id $mailbox_host {*}]
                set idx_list \
                    [lsearch -glob -nocase $t_list "*${default_box_name}*"]
                set i_pos_min 999
                # find inbox closest to tree root
                foreach mb_q_idx $idx_list {
                    set mb_q [lindex $tv_list $mb_q_idx]
                    set i_pos [string first ${default_box_name} \
                                   [string tolower $mb_q]]
                    if { $idx < 0 || $i_pos < $i_pos_min } {
                        set i_pos_min $i_pos
                        set idx $mb_q_idx
                    }
                }

            }
            # choose a box closest to tree root.
            if { $idx > -1 } {
                set mb_default [lindex $t_list $idx]
                if { $default_conn_set_p } {
                    ns_log Notice "acs_mail_lite::imap_conn_go.775 \
 Setting default mailbox.name to '${mb_default}'"
                    acs_mail_lite::imap_conn_set -name_mb $mb_default
                }
                set mb [acs_mail_lite::imap_mailbox_join \
                            -host $host \
                            -name $name_mb \
                            -ssl_p $ssl_p]
                if { "novalidatecert" in $fl_list } {
                    set conn_id [ns_imap reopen \
                                     -novalidatecert \
                                     -mailbox "${mb}" \
                                     -user $user \
                                     -password $password]
                } else {
                    set conn_id [ns_imap open \
                                     -mailbox "${mb}" \
                                     -user $user \
                                     -password $password] 
                }
            }
        }
        
    }
    return $conn_id
}


ad_proc -public acs_mail_lite::imap_conn_close {
    {-conn_id:required }
} {
    Closes nsimap session with conn_id.
    If conn_id is 'all', then all open sessions are closed.

    Returns 1 if a session is closed, otherwise returns 0.
} {
    set sessions_list [ns_imap sessions]
    set s_len [llength $sessions_list]
    ns_log Dev "acs_mail_lite::imap_conn_close.716: \
 sessions_list '${sessions_list}'"
    # Example session_list as val0 val1 val2 val3 val4 val5 val6..:
    #'40 1501048046 1501048046 {{or97.net:143/imap/tls/user="testimap1"}<no_mailbox>} 
    # 39 1501047978 1501047978 {{or97.net:143/imap/tls/user="testimap1"}<no_mailbox>}'
    set id ""
    set i 0
    set conn_exists_p 0
    while { $i < $s_len && $id ne $conn_id }  {
        set id [lindex [lindex $sessions_list 0] 0]
        if { $id eq $conn_id || $conn_id eq "all" } {
            set conn_exists_p 1
            ns_log Dev "acs_mail_lite::imap_conn_close.731 session_id '${id}'"
            if { [catch { ns_imap close $id } err_txt ] } {
                ns_log Warning "acs_mail_lite::imap_conn_close.733 \
 session_id '${id}' error on close. Error is: ${err_txt}"
            }
        }
        incr i
    }
    if { $conn_exists_p eq 0 } {
        ns_log Warning "acs_mail_lite::imap_conn_close.732: \
 Session(s) broken? conn_id '${conn_id}' not found."
    } 
    return $conn_exists_p
}

ad_proc -public acs_mail_lite::imap_mailbox_join {
    {-host ""}
    {-name ""}
    {-ssl_p "0"}
} {
    Creates an ns_imap usable mailbox consisting of curly brace quoted
    {mailbox.host}mailbox.name.
} {
    # Quote mailbox with curly braces per nsimap documentation.
    set mb "{"
    append mb ${host}
    if { [string is true -strict $ssl_p] && ![string match {*/ssl} $host] } {
        append mb {/ssl}
    }
    append mb "}" ${name}

    return $mb
}

ad_proc -public acs_mail_lite::imap_mailbox_split {
    {mailbox ""}
} {
    Returns a list: mailbox.host mailbox.name ssl_p,
    where mailbox.host and mailbox.name are defined in ns_map documentation.
    If mailbox.host has suffix "/ssl", suffix is removed and ssl_p is "1",
    otherwise ssl_p is "0".

    If mailbox cannot be parsed, returns an empty list.
} {
    set cb_idx [string first "\}" $mailbox]
    if { $cb_idx > -1  && [string range $mailbox 0 0] eq "\{" } {
        set ho [string range $mailbox 1 $cb_idx-1]
        set na [string range $mailbox $cb_idx+1 end]
        if { [string match {*/ssl} $ho ] } {
            set ssl_p 1
            set ho [string range $ho 0 end-4]
        } else {
            set ssl_p 0
        }
        set mb_list [list $ho $na $ssl_p]
    } else {
        # Not a mailbox
        set mb_list [list ]
    }
    return $mb_list
}

ad_proc -private acs_mail_lite::imap_check_incoming {
} {
    Checks for new, actionable incoming email via imap connection.
    Email is actionable if it is identified by acs_mail_lite::email_type.

    When actionable, email is buffered in table acs_mail_lite_from_external
    and callbacks are triggered.

    @see acs_mail_lite::email_type

} {
    set error_p 0
    if { [nsv_exists acs_mail_lite si_configured_p ] } {
        set si_configured_p [nsv_get acs_mail_lite si_configured_p]
    } else {
        set si_configured_p 1
        # Try to connect at least once
    }
    # This proc is called by ad_schedule_proc regularly

    # scan_in_ = scan_in_est_ = scan_in_estimate = si_
    if { $si_configured_p } {
        set cycle_start_cs [clock seconds]
        nsv_lappend acs_mail_lite si_actives_list $cycle_start_cs
        set si_actives_list [nsv_get acs_mail_lite si_actives_list]
        
        set si_dur_per_cycle_s \
            [nsv_get acs_mail_lite si_dur_per_cycle_s]
        set per_cycle_s_override [nsv_get acs_mail_lite \
                                      si_dur_per_cycle_s_override]
        set si_quit_cs \
            [expr { $cycle_start_cs + int( $si_dur_per_cycle_s \
                                               * .8 ) } ]
        if { $per_cycle_s_override ne "" } {
            set si_quit_cs [expr { $si_quit_cs - $per_cycle_s_override } ]
            # deplayed
        } else {
            set per_cycle_s_override $si_dur_per_cycle_s
        }
        
        
        set active_cs [lindex $si_actives_list end]
        set concurrent_ct [llength $si_actives_list]
        # pause is in seconds
        set pause_s 10
        set pause_ms [expr { $pause_s * 1000 } ]
        while { $active_cs eq $cycle_start_cs \
                    && [clock seconds] < $si_quit_cs \
                    && $concurrent_ct > 1 } {

            incr per_cycle_s_override $pause_s
            nsv_set acs_mail_lite si_dur_per_cycle_s_override \
                $per_cycle_s_override
            set si_actives_list [nsv_get acs_mail_lite si_actives_list]
            set active_cs [lindex $si_actives_list end]
            set concurrent_ct [llength $si_actives_list]
            ns_log Notice "acs_mail_lite::imap_check_incoming.1198. \
 pausing ${pause_s} seconds for prior invoked processes to stop. \
 si_actives_list '${si_actives_list}'"
            after $pause_ms
        }

        if { [clock seconds] < $si_quit_cs \
                 && $active_cs eq $cycle_start_cs } {
            
            set cid [acs_mail_lite::imap_conn_go ]
            if { $cid eq "" } {
                set error_p 1
            }

            if { !$error_p } {

                array set conn_arr [acs_mail_lite::imap_conn_set]
                unset conn_arr(password)
                set mailbox_host_name "{{"
                append mailbox_host_name $conn_arr(host) "}" \
                    $conn_arr(name_mb) "}"

                set status_list [ns_imap status $cid]
                if { ![f::even_p [llength $status_list]] } {
                    lappend status_list ""
                }
                array set status_arr $status_list
                set uidvalidity $status_arr(Uidvalidity)
                if { [info exists status_arr(Uidnext) ] \
                         && [info exists status_arr(Messages) ] } {

                    set aml_package_id [apm_package_id_from_key "acs-mail-lite"]
                    set filter_proc [parameter::get -parameter "IncomingFilterProcName" \
                                         -package_id $aml_package_id]
                    #
                    # Iterate through emails
                    #
                    # ns_imap search should be faster than ns_imap sort
                    set m_list [ns_imap search $cid ""]

                    foreach msgno $m_list {
                        set struct_list [ns_imap struct $cid $msgno]

                        # add struct info to headers for use with ::email_type
                        # headers_arr = hdrs_arr
                        array set hdrs_arr $struct_list
                        set uid $hdrs_arr(uid)

                        set processed_p [acs_mail_lite::inbound_cache_hit_p \
                                             $uid \
                                             $uidvalidity \
                                             $mailbox_host_name ]

                        if { !$processed_p } {
                            set headers_list [ns_imap headers $cid $msgno]
                            array set hdrs_arr $headers_list
                            
                            set type [acs_mail_lite::email_type \
                                          -header_arr_name hdrs_arr ]
                            

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
                            
                            set error_p [acs_mail_lite::imap_email_parse \
                                             -headers_arr_name hdrs_arr \
                                             -parts_arr_name parts_arr \
                                             -conn_id $cid \
                                             -msgno $msgno \
                                             -struct_list $struct_list]

                            if { !$error_p && [string match {[a-z]*_[a-z]*} $filter_proc] } {
                                set hdrs_arr(aml_package_ids_list) [safe_eval ${filter_proc}]
                            }
                            if { !$error_p } {
                                
                                set id [acs_mail_lite::inbound_queue_insert \
                                            -parts_arr_name parts_arr 
                                        \
                                            -headers_arr_name hdrs_arr \
                                            -error_p $error_p ]
                                ns_log Notice "acs_mail_lite::imap_check_incoming \
 inserted to queue aml_email_id '${id}'"
                            }

                        }
                    }
                } else {
                    ns_log Warning "acs_mail_lite::imap_check_incoming.1274. \
 Unable to process email. \
 Either Uidnext or Messages not in status_list: '${status_list}'"
                }

                if { [expr { [clock seconds] + 65 } ] < $si_quit_cs } {
                    # Regardless of parameter SMPTTimeout,
                    # if there is more than 65 seconds to next cycle,
                    # close connection
                    acs_mail_lite::imap_conn_close -conn_id $cid
                }
                
            }
            # end if !$error

            # remove active_cs from si_actives_list
            set si_idx [lsearch -integer -exact $si_actives_list $active_cs]
            # We call nsv_get within nsv_set to reduce chances of dropping
            # a new list entry.
            nsv_set acs_mail_lite si_actives_list \
                [lreplace \
                     [nsv_get acs_mail_lite si_actives_list] $si_idx $si_idx]

        } else {
            nsv_set acs_mail_lite si_configured_p 0
        }
        # acs_mail_lite::imap_check_incoming should quit gracefully 
        # when not configured or there is error on connect.

    }
    return $si_configured_p
}

ad_proc -private acs_mail_lite::imap_email_parse {
    -headers_arr_name
    -parts_arr_name
    -conn_id
    -msgno
    -struct_list
    {-section_ref ""}
    {-error_p "0"}
} {
    Parse an email from an imap connection into array array_name
    for adding to queue via acs_mail_lite::inbound_queue_insert

    Parsed data is set in headers and parts arrays in calling environment.

    struct_list expects output list from ns_imap struct conn_id msgno
} {
    # Put email in a format usable for
    # acs_mail_lite::inbound_queue_insert to insert into queue

    # for format this proc is to generate.

    # Due to the hierarchical nature of email and ns_imap struct 
    # this proc is recursive.
    upvar 1 $headers_arr_name h_arr
    upvar 1 $parts_arr_name p_arr
    upvar 1 __max_txt_bytes __max_txt_bytes
    set has_parts_p 0
    set section_n_v_list [list ]
    if { ![info exists __max_txt_bytes] } {
        set sp_list [acs_mail_lite::sched_parameters]
        set __max_txt_bytes [dict get $sp_list max_blob_chars]
    }
    if { !$error_p } {

        if { [string range $section_ref 0 0] eq "." } {
            set section_ref [string range $section_ref 1 end]
        } 
        ns_log Dev "acs_mail_lite::imap_email_parse.706 \
msgno '${msgno}' section_ref '${section_ref}'"

        # Assume headers and names are unordered

        foreach {n v} $struct_list {
            if { [string match {part.[0-9]*} $n] } {
                set has_parts_p 1
                set subref $section_ref
                append subref [string range $n 4 end]
                acs_mail_lite::imap_email_parse \
                    -headers_arr_name h_arr \
                    -parts_arr_name p_arr \
                    -conn_id $conn_id \
                    -msgno $msgno \
                    -struct_list $v \
                    -section_ref $subref
            } else {
                switch -exact -nocase -- $n {
                    bytes {
                        set bytes $v
                    }
                    disposition.filename {
                        regsub -all -nocase -- {[^0-9a-zA-Z\-.,\_]} $v {_} v
                        set filename $v
                    }
                    type {
                        set type $v
                    }
                    
                    default {
                        # do nothing
                    }
                }
                if { $section_ref eq "" } {
                    set h_arr(${n}) ${v}
                } else {
                    lappend section_n_v_list ${n} ${v}
                }
            }
        }

        if { $section_ref eq "" && !$has_parts_p } {
            # section_ref defaults to '1'
            set section_ref "1"
        }

        set section_id [acs_mail_lite::section_id_of $section_ref]
        ns_log Dev "acs_mail_lite::imap_email_parse.746 \
msgno '${msgno}' section_ref '${section_ref}' section_id '${section_id}'"

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
                ns_log Dev "acs_mail_lite::imap_email_parse.775 \
 ns_imap body '${conn_id}' '${msgno}' '${section_ref}' \
 -file '${filepathname}'"
                ns_imap body $conn_id $msgno ${section_ref} \
                    -file $filepathname
            } else {
                ns_log Dev "acs_mail_lite::imap_email_parse.780 \
 ns_imap body '${conn_id}' '${msgno}' '${section_ref}' \
 -file '${filepathname}' -decode"

                ns_imap body $conn_id $msgno ${section_ref} \
                    -file $filepathname \
                    -decode
            } 
        } elseif { $section_ref ne "" } {
            # text content
            set p_arr(${section_id},content) [ns_imap body $conn_id $msgno $section_ref]
            ns_log Dev "acs_mail_lite::imap_email_parse.792 \
 text content '${conn_id}' '${msgno}' '${section_ref}' \
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
                set msg_txt [ns_imap text $conn_id $msgno ]
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
                ns_log Dev "acs_mail_lite::imap_email_parse.818 IGNORED \
 ns_imap text '${conn_id}' '${msgno}' '${section_ref}' \n \
 msg_txte '${msg_txte}'"
            } else {
                ns_log Dev "acs_mail_lite::imap_email_parse.822 ignored \
 ns_imap text '${conn_id}' '${msgno}' '${section_ref}'"
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


