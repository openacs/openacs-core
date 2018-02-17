ad_page_contract {
    Provies a framework for manually testing acs_mail_lite procs
    A dummy mailbox value provided to show example of what is expected.
} {
    {mail_dir ""}
}
set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set admin_p [permission::permission_p \
                 -party_id $user_id \
                 -object_id $package_id \
                 -privilege admin ]
if { !$admin_p } {
    set content "Requires admin permission"
    ad_script_abort
}

set content "www/doc/maildir-test start<br>"

if { $mail_dir eq "" } {
    # assume Ubuntu linux install based on installation script
    set mail_dir "/home/nsadmin/Maildir"
}
if { ![string match {/new/*} $mail_dir] } {
    append mail_dir "/new/*"
}
set messages_list [glob -nocomplain $mail_dir]
set s " : "


set var_list [list msg m_id c_type header_names_list headers_list part_ids_list body_parts_list datetime_cs property_names_list property_list body_parts_list ]

set var2_list [list part_id p_header_names_list p_headers_list p_property_names_list p_property_list p_body_parts_list ]

foreach msg $messages_list {
    
    set m_id [mime::initialize -file $msg]

    set header_names_list [mime::getheader $m_id -names]
    # a header returns multiple values in a list, if header element is repeated in email.
    set headers_list [mime::getheader $m_id]

    set r_idx [lsearch -nocase $header_names_list "received"]
    if { $r_idx > -1 } {
        set r_nam [lindex $header_names_list $r_idx]
        array set h_arr $headers_list
        if { [llength $h_arr(${r_nam}) ] > 1 } {
            set received_str [lindex $h_arr(${r_nam}) 0 ]
        } else {
            set received_str $h_arr(${r_nam})
        }
        if { [regexp -nocase -- {([a-z][a-z][a-z][ ,]+[0-9]+ [a-z][a-z][a-z][ ]+[0-9][0-9][0-9][0-9][ ]+[0-9][0-9][:][0-9][0-9][:][0-9][0-9][ ]+[\+\-][0-9]+)[^0-9]} $received_str match received_ts] } {
            set age_s [mime::parsedatetime $received_ts rclock]
            ns_log Notice "maildir-test.tcl.30 rclock $age_s"
            set datetime_cs [expr { [clock seconds] - $age_s } ]
        }
    }

    set property_names_list [mime::getproperty $m_id -names]
    set property_list [mime::getproperty $m_id]


    # following group are redundant to mime::getproperty $m_id
    set params_list [mime::getproperty $m_id params]
    set encoding_s [mime::getproperty $m_id encoding]
    set content_s [mime::getproperty $m_id content]
    ns_log Notice "maildir-test.tcl.22 m_id '${m_id}' content_s '${content_s}'"
    set size_s [mime::getproperty $m_id size]

    if { [string match "multipart/*" $content_s] \
             || [string match -nocase "inline*" $content_s ] } {
        # or 'parts' exists in property_list

        set part_ids_list [mime::getproperty $m_id parts]

    } else {
        # this is a leaf
#        set body_parts_list [mime::getbody $m_id]
        set body_parts_list [mime::buildmessage $m_id]
        set bpl "<pre>"
        append bpl [string range $body_parts_list 0 240]
        append bpl "<br>.. ..<br>" [string range $body_parts_list end-120 end]
        append bpl "</pre>"
        set body_parts_list $bpl
    }







    append content "<br><br>New message<br><br>"
    foreach var $var_list {
        if { [info exists $var] } {
            append content $var $s [set $var] " <br><br>"
        }

    }

    if { [info exists part_ids_list ] } {
        foreach part_id $part_ids_list {
            set p_header_names_list [mime::getheader $part_id -names]
            set p_headers_list [mime::getheader $part_id]
            set p_property_names_list [mime::getproperty $part_id -names]
            set p_property_list [mime::getproperty $part_id ]
            # includes params size content encoding
            # params is like flags in IMAP
            set p_params_list [mime::getproperty $part_id params]
            set p_content_s [mime::getproperty $part_id content]
            ns_log Notice "maildir-test.tcl.63 part_id '${part_id}' p_content_s '${p_content_s}'"
            set p_size_s [mime::getproperty $part_id size]
            if { [string match "multipart/*" $p_content_s] \
                     || [string match -nocase "inline*" $p_content_s ] } {

                set p_part_ids_list [mime::getproperty $part_id parts]

            } else {
                # this is a leaf
                set p_encoding_s [mime::getproperty $part_id encoding]
#                set p_body_parts_list [mime::getbody $part_id]
                set p_body_parts_list [mime::buildmessage $part_id]
                set bpl "<pre>"
                append bpl [string range $p_body_parts_list 0 240]
                append bpl "<br>.. ..<br>" [string range $p_body_parts_list end-120 end]
                append bpl "</pre>"
                set p_body_parts_list $bpl
            }
            
#            append content "part_id '${part_id}'<br>"
            foreach var $var2_list {
                if { [info exists $var] } {
                    append content $var $s [set $var] " <br><br>"
                }
            }
        }
    }
    # cleanup current message
    foreach var $var_list {
        if { [info exists $var] && $var ne "msg" && $var ne "m_id" } {
            unset $var
        }
    }
    foreach var $var2_list {
        if { [info exists $var] } {
            unset $var
        }
    }
    mime::finalize $m_id -subordinates all


}
