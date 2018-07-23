ad_library {
    Automated tests for acs-mail-lite/tcl/email-inbound
    @creation-date 2017-07-19
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        acs_mail_lite::email_type
        acs_mail_lite::imap_conn_close
        acs_mail_lite::imap_conn_go
        acs_mail_lite::imap_mailbox_join
        acs_mail_lite::imap_mailbox_split
        acs_mail_lite::inbound_prioritize
        acs_mail_lite::sched_parameters
        acs_mail_lite::section_id_of
        acs_mail_lite::section_ref_of
        acs_mail_lite::unique_id_create
        acs_mail_lite::unique_id_parse
        ad_system_owner
        ad_var_type_check_integer_p
        apm_package_id_from_key
        f::lmax
        party::get_by_email
    } acs_mail_lite_inbound_procs_check {
        Test acs-mail-lite procs in email-inbound-procs.tcl
    } {
    aa_run_with_teardown \
        -rollback \
        -test_code {

           ns_log Notice "aa_register_case:acs_mail_lite_inbound_procs_check"

           set a_list [acs_mail_lite::sched_parameters]
           array set params_def $a_list

           set bools_list [list reprocess_old_p]
           set integer_list [list sredpcs_override max_concurrent \
                                 max_blob_chars mpri_min mpri_max]
           set ints_list [list hpri_package_ids lpri_package_idx hpri_party_ids lpri_party_ids hpri_object_ids lpri_object_ids]
           set globs_list [list hpri_subject_glob lpri_subject_glob]
           set lists_list [list reject_on_hit reject_on_miss]

           set bools_v_list [list 0 1 t f true false]
           set nv_list_list [list \
                                 [list name1 value1 name2 value2 ] \
                                 [list a-dashed "a value in quotes" \
                                      b_unscored "b nother value in quotes" ] \
                                 [list a-dash {a val in parens} \
                                      b_underscore {value in parens} ] ]
            foreach p [array names params_def] {
                # test setting of each parameter separately
                set param "-"
                append param $p
                if { $p in $bools_list } {
                    set val_idx [randomRange 5]
                    set val [lindex $bools_v_list $val_idx]
                } elseif { $p in $integer_list } {
                    set val [randomRange 32767]
                } elseif { $p in $ints_list } {
                    set nums_list [list]
                    set up_to_10 [randomRange 10]
                    for {set i 0} {$i < $up_to_10 } {incr i} {
                        lappend nums_list [randomRange 32767]
                    }
                    set val [join $nums_list " "]
                } elseif { $p in $lists_list } {
                    set val_idx [randomRange 2]
                    set val [lindex $nv_list_list $val_idx]
                }
                aa_log "r41. Testing change of parameter '${p}' from \
 '$params_def(${p})' to '${val}'"

                set b_list [acs_mail_lite::sched_parameters $param $val]
                aa_log "param $param val $val b_list $b_list"
                array unset params_new
                array set params_new $b_list
                foreach pp [array names params_def] {
                    if { $pp eq $p } {
                        if { $pp in $bools_list } {
                            aa_equals "r48 Changed sched_parameter '${pp}' \
  value '$params_def(${pp})' to '${val}' set" \
                                [template::util::is_true $params_new(${pp})] \
                                [template::util::is_true $val]
                        } else {
                            if { $params_new(${pp}) eq $params_def(${pp}) } {
                                if { $pp eq "mpri_max" \
                                         && $val < $params_def(mpri_min) } {
                                    aa_log "r54a mpri_max<mpri_min no change"
                                } elseif { $pp eq "mpri_min" \
                                               && $val > $params_def(mpri_max) } {
                                    aa_log "r54b mpri_min>mpri_max no change."
                                } else {
                                    aa_log "r55 '${pp}' no change."
                                }
                            } else {
                                aa_equals "r56 Changed sched_parameter \
 '${pp}' value '$params_def(${pp})' to '${val}' set" $params_new(${pp}) $val

                            }
                        }
                    } else {
                        if { $pp in $bools_list } {
                            aa_equals "r62 Unchanged sched_parameter '${pp}' \
  value '$params_def(${pp})' to '$params_new(${pp})' set" \
                                [template::util::is_true $params_new(${pp})] \
                                [template::util::is_true $params_def(${pp})]
                        } else {
                            aa_equals "r67 Unchanged sched_parameter '${pp}' \
  value '$params_def(${pp})' to '$params_new(${pp})' set" \
                                $params_new(${pp}) $params_def(${pp})
                        }
                    }
                }
                array set params_def $b_list
            }

            set instance_id [ad_conn package_id]
            set sysowner_email [ad_system_owner]
            set sysowner_user_id [party::get_by_email -email $sysowner_email]
            set user_id [ad_conn user_id]
            set package_ids [list $instance_id]
            set party_ids [util::randomize_list \
                               [list $user_id $sysowner_user_id]]
            set object_ids [concat \
                                $party_ids \
                                $package_ids \
                                $user_id \
                                $sysowner_user_id]
           # in order of least significant first, regarding prioritization:
           # That is, object_id is more specific than glob_str or party_ids.
            set priority_types [list \
                                    package_ids \
                                    party_ids \
                                    glob_str \
                                    object_ids]
            set lh_list [list l h]
            set subject [ad_generate_random_string]
            set su_glob "*"
            append su_glob [string range $subject [randomRange 8] end]

           # priority_types are in order of least significant first.
           set p_type_i 0
            foreach p_type $priority_types {

                # reset parameters
                foreach {n v} $a_list {
                    #set $n $v
                    set p "-"
                    append p $n
                    aa_log "r106 resetting p '${p}' to v '${v}'"
                    set b_list [acs_mail_lite::sched_parameters $p $v]
                }

                # set new case of parameters
                set r [randomRange 10000]
                set p_min [expr { $r + 999 } ]
                set p_max [expr { $p_min * 1000 + $r } ]
                set su_max $p_max
                append su_max "00"

                set c_list [acs_mail_lite::sched_parameters \
                                -mpri_min $p_min \
                                -mpri_max $p_max]
                array set c_arr $c_list
                set p_min $c_arr(mpri_min)
                set p_max $c_arr(mpri_max)

                aa_log "r115 p_min '${p_min}' p_max '${p_max}'"


                set i 0
                set p_i [lindex $priority_types $i]
                while { $p_i ne $p_type && $i < $p_type_i } {
                    # set a random value to be ignored
                    # because p_i is lower significance than
                    # higher significance of p_type value

                    # make low or high?
                    set p [util::random_list_element $lh_list]
                    set pa "-"
                    append pa $p
                    switch -exact -- $p_i {
                        package_ids {
                            append pa "pri_package_ids"
                            set v $instance_id
                        }
                        party_ids {
                            append pa "pri_party_ids"
                            set v [join $party_ids " "]
                        }
                        glob_str {
                            append pa "pri_subject_glob"
                            set v $su_glob
                        }
                        object_ids {
                            append pa "pri_object_ids"
                            set v [join $object_ids " "]
                        }
                    }
                    aa_log "r148: pa '${pa}' v '${v}' gets overridden"
                    acs_mail_lite::sched_parameters ${pa} $v

                    incr i
                    set p_i [lindex $priority_types $i]
                }
                # What priority are we testing?
                set p [util::random_list_element $lh_list]
                aa_log "r163: Testing priority '${p}' for '${p_type}'"

                set pa "-"
                append pa $p
                switch -exact -- $p_type {
                    package_ids {
                        append pa "pri_package_ids"
                        set v $instance_id
                    }
                    party_ids {
                        append pa "pri_party_ids"
                        set v [join $party_ids " "]
                    }
                    glob_str {
                        append pa "pri_subject_glob"
                        set v $su_glob
                    }
                    object_ids {
                        append pa "pri_object_ids"
                        set v [join $object_ids " "]
                    }
                }
                aa_log "r185: pa '${pa}' v '${v}'"
                acs_mail_lite::sched_parameters ${pa} $v


                # make four tests for each priority p_arr
                # two vary in time, t1, t2
                # two vary in size, s1, s2

                set t0 [nsv_get acs_mail_lite si_start_t_cs]
                set dur_s [nsv_get acs_mail_lite si_dur_per_cycle_s]

                set size_list [list $su_max]
                set ns_section_list [list nssock nssock_v4 nssock_v6]
                foreach section $ns_section_list {
                    lappend size_list [ns_config -int -min 0 $section maxinput]
                }
                set s0  [f::lmax $size_list]

                aa_log "r161 given: t0 '${t0}' dur_s '${dur_s}'"
                aa_log "r161b given: s0 '${s0}' su_max '${su_max}'"

                set t1 [expr { int( $t0 - $dur_s * 1.9 * [random]) } ]
                set t2 [expr { int( $t0 - $dur_s * 1.9 * [random]) } ]
                set s1 [expr { int( $s0 * 0.9 * [random]) } ]
                set s2 [expr { int( $s0 * 0.9 * [random]) } ]
                aa_log "r167 priorities: t1 '${t1}' t2 '${t2}' s1 '${s1}' s2 '${s2}'"
                if { $t1 < $t2 } {
                    set t $t1
                    # first in chronology = f1
                    # second in chronology = f2
                    set f1 t1
                    set f2 t2
                } else {
                    set t $t2
                    set f1 t2
                    set f2 t1
                }

                if { $s1 < $s2 } {
                    set s $s1
                    # first in priority for size = z1
                    # second in priority for size = z2
                    set z1 s1
                    set z2 s2
                } else {
                    set s $s2
                    set z1 s2
                    set z2 s1
                }

                set p_arr(t1) [acs_mail_lite::inbound_prioritize \
                                       -size_chars $s \
                                       -received_cs $t1 \
                                       -subject $subject \
                                       -package_id $instance_id \
                                       -party_id $user_id \
                                       -object_id $instance_id]
                aa_log "p_arr(t1) = '$p_arr(t1)'"

                set p_arr(t2) [acs_mail_lite::inbound_prioritize \
                                   -size_chars $s \
                                   -received_cs $t2 \
                                   -subject $subject \
                                   -package_id $instance_id \
                                   -party_id $user_id \
                                   -object_id $instance_id]
                aa_log "p_arr(t2) = '$p_arr(t2)'"

                set p_arr(s1) [acs_mail_lite::inbound_prioritize \
                                   -size_chars $s1 \
                                   -received_cs $t \
                                   -subject $subject \
                                   -package_id $instance_id \
                                   -party_id $user_id \
                                   -object_id $instance_id]
                aa_log "p_arr(s1) = '$p_arr(s1)'"

                set p_arr(s2) [acs_mail_lite::inbound_prioritize \
                                   -size_chars $s2 \
                                   -received_cs $t \
                                   -subject $subject \
                                   -package_id $instance_id \
                                   -party_id $user_id \
                                   -object_id $instance_id]

                aa_log "p_arr(s2) = '$p_arr(s2)'"

                # verify earlier is higher priority
                if { $p_arr(${f1}) < $p_arr(${f2}) } {
                    set cron_p 1
                } else {
                    set cron_p 0
                }
                aa_true "earlier email assigned first \
 ${f1} '$p_arr(${f1})' < ${f2} '$p_arr(${f2})' " $cron_p

                # verify larger size has slower priority
                if { $p_arr(${z1}) < $p_arr(${z2}) } {
                    set size_p 1
                } else {
                    set size_p 0
                }
                aa_log "test r266 and r276 may fail when not testing \
 a default clean system"
                aa_true "smaller email assigned first \
 ${z1} '$p_arr(${z1})' < ${z2} '$p_arr(${z2})' " $size_p

                # verify that none hit or exceed the range limit
                if { $p eq "l" } {
                    foreach j [list t1 t2 s1 s2] {
                        if { $p_arr($j) > $p_max && $p_arr($j) < $s0 } {
                            set within_limits_p 1
                        } else {
                            set within_limits_p 0
                        }
                        aa_true "r266; prioirty for case '${j}' '${p_max}' < \
  '$p_arr(${j})' < '${s0}' is within limits." $within_limits_p
                    }
                } elseif { $p eq "h" } {
                    foreach j [list t1 t2 s1 s2] {
                        if { $p_arr($j) > 0 && $p_arr($j) < $p_min } {
                            set within_limits_p 1
                        } else {
                            set within_limits_p 0
                        }
                        aa_true "r276: prioirty for case '${j}' '0' < \
  '$p_arr(${j})' < '${p_min}' is within limits." $within_limits_p
                    }

                }

                incr p_type_i
                # end foreach p_type loop
            }

           set ho "localhost"
           set na "mail/INBOX"
           set ssl_p 0
           set t1 [acs_mail_lite::imap_mailbox_join \
                       -host $ho -name $na -ssl_p $ssl_p]
           set t2 {{localhost}mail/INBOX}
           aa_equals "Test acs_mail_lite::imap_mailbox_join" $t1 $t2

           set t2_list [acs_mail_lite::imap_mailbox_split $t2]
           set t1_list [list $ho $na $ssl_p]
           aa_equals "Test acs_mail_lite::imap_mailbox_split" $t1_list $t2_list

           if { [catch { set sid [acs_mail_lite::imap_conn_go] } errmsg ] } {
               set sid "z"
           }
           set sid_p [ad_var_type_check_integer_p $sid]
           aa_true "ref407. acs_mail_lite::imap_conn_go" $sid_p

           if { [catch {set sid4 [acs_mail_lite::imap_conn_go -conn_id ""] } errmsg] } {
               set sid4 "z"
           }
           set sid4_p [ad_var_type_check_integer_p $sid4]
           aa_true "ref424. acs_mail_lite::imap_conn_go -conn_id ''" $sid4_p
           
           aa_log "Checking whether ns_imap is installed..."
           set ns_imap_p [expr {[info commands ns_imap] ne ""}]
           set enabled [expr {$ns_imap_p ?
                              "enabled. Activating additional tests" :
                              "disabled. Some tests will be skipped"}]
           aa_log "...ns_imap $enabled."
           
           # Following tests are expected to work only when ns_imap is
           # installed and are therefore disabled otherwise.
           if {$ns_imap_p} {
               aa_log "Start of ns_imap dependent tests."
               
               aa_log "Testing imap open/close via default connection params"
               if { [catch {set conn_id [acs_mail_lite::imap_conn_close -conn_id "all"]} errmsg ] } {
                   set conn_id 1
               }
               set es ""

               aa_log "Following three tests 'pass' when no imap sessions open."
               aa_false "ref367. acs_mail_lite::imap_conn_close -conn_id 'all'" $conn_id

               set conn_id [randomRange 1000]
               if { [catch {set t3 [acs_mail_lite::imap_conn_close -conn_id $conn_id]} errmsg] } {
                   set t3 1
               }
               aa_false "ref373. acs_mail_lite::imap_conn_close -conn_id '${conn_id}'" $t3

               set conn_id ""
               if { [catch {set t3 [acs_mail_lite::imap_conn_close -conn_id $conn_id]} errmsg] } {
                   set t3 1
               }
               aa_false "ref379. acs_mail_lite::imap_conn_close -conn_id '${conn_id}'" $t3

               aa_log "Following tests various session cases with open/close"
               aa_log "Some will fail if a session cannot be established."


               # see Example of an IMAP LIST in rfc6154:
               # https://tools.ietf.org/html/rfc6154#page-7
               # ns_imap list $conn_id $mailbox pattern(* or %) substr


               #set list [ns_imap list $conn_id $mailbox_host {}]
               # returns: '{} noselect'  When logged in is not successful..
               # set list [ns_imap list $conn_id $mailbox_host {*}]
               # returns 'INBOX {} INBOX.Trash {} INBOX.sent-mail {}' when really logged in
               # and mailbox_name part of mailbox is "", and mailbox is in form {{mailbox_host}}
               # set list [ns_imap list $conn_id $mailbox_host {%}]
               # returns 'INBOX {}' when really logged in
               # and mailbox_name part of mailbox is ""
               # If mailbox_name exists and is included in mailbox_host, returns ''
               # If mailbox_name separate from mailbox_host, and exists and in place of %, returns 'mailbox {}'
               # for example 'INBOX.Trash {}'


               if { [catch { set sid2 [acs_mail_lite::imap_conn_close -conn_id $sid] } errmsg ] } {
                   set sid2 0
               }
               aa_true "ref412. acs_mail_lite::imap_conn_close -conn_id '${sid}'" $sid2

               if { [catch {set sid3 [acs_mail_lite::imap_conn_go -conn_id $sid] } errmsg ] } {
                   set sid3 "z"
               }
               set sid3_p [ad_var_type_check_integer_p $sid3]
               aa_false "ref418. acs_mail_lite::imap_conn_go -conn_id '${sid}'" $sid3_p

               set sid5 "all"
               if { [catch {set closed_p [acs_mail_lite::imap_conn_close -conn_id $sid5]} errmsg] } {
                   set closed_p 0
               }
               aa_true "ref430. acs_mail_lite::imap_conn_close -conn_id '${sid5}'" $closed_p

               aa_log "End of ns_imap dependent tests."
           }

           aa_log "Testing for auto replies"

           # load example headers
           set files_list [glob -directory [file join [acs_root_dir] \
                                                packages \
                                                acs-mail-lite \
                                                www \
                                                doc ] \
                               -- {headers-example-[0-9]*.txt} ]

           #NOTE: number 24 is example of auto-generated

           set i ""
           foreach f $files_list {

               if { [regexp {([0-9]+)} [file tail $f] i ] } {
                   set fid [open $f r ]
                   # headers-example = he
                   set he_arr(${i}) [read $fid ]

                   switch -exact -- $i {
                       3 {
                           set type_arr(${i}) "in_reply_to"
                       }
                       24 {
                           set type_arr(${i}) "auto_gen"
                       }
                       default {
                           set type_arr(${i}) ""
                       }
                   }


                   ns_log Notice "test/email-inbound-procs.tcl.394 i $i f $f"

                   close $fid
               } else {
                   ns_log Warning "test/email-inbound-procs.tcl.401 f ${f} not processed"
               }
           }



           aa_log "Test using full headers in text of default cases."
           set csp 0
           set su ""
           set from ""
           set i [llength $files_list]
           for {set ii 1} {$ii <= $i} {incr ii } {
               set type [acs_mail_lite::email_type \
                             -subject $su \
                             -from $from \
                             -headers $he_arr(${ii}) \
                             -check_subject_p $csp ]
               #aa_log "r401. headers '$he_arr(${ii})'"
               aa_equals "r402. unmodified headers-example-${ii}.txt of \
 type '$type_arr(${ii})'. type from acs_mail_lite::email_type" \
                   $type $type_arr(${ii})
           }

           aa_log "Test using full headers in modified cases, including
 false flags for subject and from fields that should be ignored."
           set csp 0
           set su "out of office"
           set from "mailer daemon"
           # ordered list, highest priority first.
           # See last if in acs_mail_lite::email_type
           set t_olist [list bounce auto_reply auto_gen in_reply_to ""]
           set s_list [list failed delayed relayed expanded]
           set ar_list [list auto-notified \
                            auto-replied \
                            auto-reply \
                            autoreply \
                            autoresponder \
                            x-autorespond ]
           for {set ii 1} {$ii <= $i} {incr ii } {
               # send garbage to try to confuse proc
               set t [randomRange 4]
               set h ""
               # Some examples already have header types that limit
               # test type.
               if { $type_arr(${ii}) eq "auto_gen" && $t > 2 } {
                   set t [randomRange 2]
               }

               if { $type_arr(${ii}) eq "in_reply_to" && $t > 1 } {
                   set t [randomRange 1]
               }
               set type_test [lindex $t_olist $t]

               if { $t == 3 || $t < 2  } {
                   # add in_reply_to headers
                   append h "in-reply-to : " [ad_generate_random_string 30]
                   append h "\n"
               }
               if { $t < 3 } {
                   # add auto_gen headers
                   append h "auto-submitted : " [ad_generate_random_string]
                   append h "\n"
                   append h "auto-generated : " [ad_generate_random_string]
                   append h "\n"
               }
               if { $t < 2 } {
                   # add auto_reply headers
                   switch [randomRange 2] {
                       0 {
                           append h [lindex $ar_list [randomRange 5]]
                           append h " : " [ad_generate_random_string]
                       }
                       1 {
                           append h "action : delivered"
                       }
                       2 {
                           set h2 [lindex $s_list [randomRange 3]]
                           append h "action : " $h2 "\n"
                           append h "status : thisis a test"
                       }
                   }
                   append h "\n"
               }
               if { $t < 1 } {
                   # add bounce headers
                   if { [randomRange 1] } {
                       # test original-recipient (diverted, reply)
                       append h "original-recipient : "
                       append h [ad_system_owner] "\n"
                   } else {
                       # test delivery status notification
                       append h action
                       append h " : " [lindex $s_list [randomRange 3]]
                       append h "\n" status " : "
                       append h [expr { 99 + [randomRange 900] } ] " "
                       append h [ad_generate_random_string [randomRange 9]]
                       append h "\n"
                   }
               }
               # maybe mess up capitalization
               set c [randomRange 3]
               switch -exact -- $c {
                   0 {
                       set h [string tolower $h]
                   }
                   1 {
                       set h [string toupper $h]
                   }
                   2 {
                       set h [string totitle $h]
                   }
                   default {
                       # do nothing
                   }
               }
               aa_log "t ${t} type_test '${type_test}' h '${h}'"
               ns_log Dev "t ${t} type_test '${type_test}' h '${h}'"
               set he $he_arr(${ii})
               append he "\n" $h
               set type [acs_mail_lite::email_type \
                             -subject $su \
                             -from $from \
                             -headers $he \
                             -check_subject_p $csp ]
               aa_equals "r501 headers-example-${ii}.txt \
 ($type_arr(${ii})) to '${type_test}'. Matches acs_mail_lite::email_type" \
                   $type $type_test
               ns_log Dev "r501n headers-example-${ii}.txt \
 ($type_arr(${ii})) to '${type_test}'. acs_mail_lite::email_type '${type}'"
           }


           aa_log "r600 test acs_mail_lite::section_id_of "
           aa_log "r601 test empty case ''"
           set section ""
           set sect_id1 [acs_mail_lite::section_id_of $section]
           set sect_id2 [acs_mail_lite::section_id_of $section]
           set sect_arr(${sect_id1}) $section
           aa_equals "r601 test empty case section '${section}'" \
               $sect_id2 $sect_id1
           set section [ad_generate_random_string]
           # Some random strings are integers.
           append section A
           set sect_id1 [acs_mail_lite::section_id_of $section]
           set sect_id2 [acs_mail_lite::section_id_of $section]
           aa_equals "r602 test bad ref case section '${section}'" \
               $sect_id2 $sect_id1
           set sect_arr(${sect_id1}) $section
           aa_equals "r603 test bad ref case section '${section}' returns ''" \
               $sect_id1 ""


           set section [randomRange 100]
           set sect_id1 [acs_mail_lite::section_id_of $section]
           set sect_id2 [acs_mail_lite::section_id_of $section]
           aa_equals "r605 test case section '${section}'" \
               $sect_id2 $sect_id1
           set sect_arr(${sect_id1}) $section
           for {set i 0} {$i < 6} {incr i} {
               append section "." [randomRange 100]
               set sect_id1 [acs_mail_lite::section_id_of $section]
               set sect_id2 [acs_mail_lite::section_id_of $section]
               aa_equals "r606 test case section '${section}'" \
                   $sect_id2 $sect_id1
               set sect_arr(${sect_id1}) $section
           }

           aa_log "r610 test acs_mail_lite::section_ref_of "
           aa_log "r611 test empty case ''"
           set sect_ref1 ""
           set sect_ref2 [acs_mail_lite::section_ref_of ""]
           aa_equals "r616 test case section '${sect_ref1}'" \
               $sect_id2 $sect_id1

           foreach sect_id [array names sect_arr] {

               set sect_ref1 $sect_arr(${sect_id})
               if { $sect_id ne "" } {

                   set sect_ref2 [acs_mail_lite::section_ref_of $sect_id]
                   aa_equals "r616 test case section '${sect_id}'" \
                       $sect_ref2 $sect_ref1
               }
           }


           aa_log "r700 test acs_mail_lite::unique_id_create/parse paradigm"

           set integer_max 2147483647
           incr integer_max -2
           set fields_list [list package_id party_id object_id other]
           set package_id_list [db_list apm_package_ids_rall { select
               distinct package_id from apm_packages } ]
           set aml_package_id [apm_package_id_from_key "acs-mail-lite"]
           set party_id_list [db_list parties_rall { select
               distinct party_id from parties }]
           set object_id_list [db_list acs_objects_rall { select
               distinct object_id from acs_objects} ]
           set package_ct [llength $package_id_list]
           set party_ct [llength $party_id_list]
           set object_ct [llength $object_id_list]
           for {set i 0} {$i < 12} {incr i } {
               set package_id [lindex $package_id_list \
                                   [randomRange $package_ct]]
               set party_id [lindex $party_id_list \
                                 [randomRange $party_ct]]
               set object_id [lindex $object_id_list \
                                  [randomRange $object_ct]]
               set other [ad_generate_random_string]
               set blank_id [randomRange 3]
               set blank_field [lindex $fields_list $blank_id]
               set $blank_field ""
               # if package_id = aml_package_id, it still is signed here
               set m_arr(package_id,${i}) $package_id
               set m_arr(party_id,${i}) $party_id
               set m_arr(object_id,${i}) $object_id
               set m_arr(other,${i}) $other
               set m_arr(msg_id,${i}) [acs_mail_lite::unique_id_create \
                                           -package_id $package_id \
                                           -party_id $party_id \
                                           -object_id $object_id \
                                           -other $other ]
           }
           for {set i 0} {$i < 12} {incr i } {
               array unset e_arr
               aa_log "r701 test message-id '$m_arr(msg_id,${i})'"
               set e_list [acs_mail_lite::unique_id_parse \
                               -message_id $m_arr(msg_id,${i}) ]
               array set e_arr $e_list
               foreach field $fields_list {
                       aa_equals "r703 test acs_mail_lite::unique_id \
 i '${i}' field '${field}'" $e_arr(${field}) $m_arr(${field},${i})

               }

           }
           aa_log "test default case"
           set msg_id [acs_mail_lite::unique_id_create ]
           set e_list [acs_mail_lite::unique_id_parse -message_id $msg_id]
           foreach {n v} $e_list {
               switch -- $n {
                   object_id -
                   package_id -
                   party_id -
                   datetime_cs -
                   other {
                       aa_equals "r710 test acs_mail_lite::unqiue_id $n has val ''" $v ""
                   }
                   datetime_not {
                       set is_integer_p [string is wideinteger -strict $v]
                       aa_true "r711 test acs_mail_lite::unique_id $n is integer" $is_integer_p

                   }
               }
           }
           aa_log "test passing blank case as external"
               set msg_id [acs_mail_lite::unique_id_create -unique_id [mime::uniqueID]]
               set e_list [acs_mail_lite::unique_id_parse -message_id $msg_id]
           foreach {n v} $e_list {
               switch -- $n {
                   object_id -
                   package_id -
                   party_id -
                   datetime_cs -
                   other {
                       aa_equals "r710 test acs_mail_lite::unqiue_id $n has val ''" $v ""
                   }
                   datetime_not {
                       set is_integer_p [string is wideinteger -strict $v]
                       aa_true "r711 test acs_mail_lite::unique_id $n is integer" $is_integer_p

                   }
               }
           }
       }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
