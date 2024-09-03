ad_library {

    Tests for utilities

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        util::zip
        util::unzip
        util::file_content_check
        ad_mktmpdir
        ad_opentmpfile
    } \
    zip_and_unzip {
        Test zip and unzip utilities: we create a tempfile in a
        tempfilder, we zip it, then unzip it and check that everything
        is fine.
    } {
        aa_section "Creating a zip file"

        set tmpdir [ad_mktmpdir]
        set wfd [ad_opentmpfile tmpname]
        puts $wfd ABCD
        close $wfd
        set checksum [ns_md file $tmpname]
        file rename -- $tmpname $tmpdir

        util::zip -source $tmpdir -destination $tmpdir/test.zip

        aa_true "Zip '$tmpdir/test.zip' was created" \
            [util::file_content_check \
                 -type zip \
                 -filename $tmpdir/test.zip]


        aa_section "Unzipping the file"

        set tmpdir2 [ad_mktmpdir]
        util::unzip -source $tmpdir/test.zip -destination $tmpdir2

        set tmpname [file tail $tmpname]
        aa_true "File '$tmpdir2/$tmpname' was created" [file exists $tmpdir2/$tmpname]
        aa_equals "File content is correct" [ns_md file $tmpdir2/$tmpname] $checksum


        aa_section "Unzipping on existing content (no overwrite)"

        aa_log "Write different content in '$tmpdir2/$tmpname'"
        set wfd [open $tmpdir2/$tmpname w]
        puts $wfd EFGH
        close $wfd
        set checksum2 [ns_md file $tmpdir2/$tmpname]

        aa_log "Replace '$tmpdir/test.zip' with a new one with both the an existing and a non-existing file"
        file copy $tmpdir2/$tmpname $tmpdir/second-file.txt
        util::zip -source $tmpdir -destination $tmpdir/test.zip

        aa_false "Extracting again the same stuff in the same folder will not fail" [catch {
            util::unzip -source $tmpdir/test.zip -destination $tmpdir2
        }]

        aa_equals "File '$tmpdir2/$tmpname' was NOT overwritten" \
            [ns_md file $tmpdir2/$tmpname] $checksum2
        aa_equals "File '$tmpdir2/second-file.txt' was extracted correctly" \
            [ns_md file $tmpdir2/second-file.txt] $checksum2

        aa_section "Unzipping on existing content (overwrite)"

        aa_false "Extracting again the same stuff in the same folder will not fail" [catch {
            util::unzip -overwrite -source $tmpdir/test.zip -destination $tmpdir2
        }]

        aa_equals "File '$tmpdir2/$tmpname' was overwritten as expected with the file from the zip" \
            [ns_md file $tmpdir2/$tmpname] $checksum
        aa_equals "File '$tmpdir2/second-file.txt' was extracted correctly" \
            [ns_md file $tmpdir2/second-file.txt] $checksum2

        file delete -force $tmpdir
        file delete -force $tmpdir2
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        ad_safe_eval
    } \
    ad_safe_eval {
        Test ad_safe_eval
    } {
        aa_equals "Eval of expr returns expected" \
            [ad_safe_eval expr {1 + 1}] 2
        aa_equals "Eval of snippet returns expected" \
            [ad_safe_eval {
                set a 1
                set b 2
                expr {$a + $b}
            }] \
            3
        aa_true "Subcommands in the code will fail (args)" [catch {
            ad_safe_eval expr {1 + [expr {1 + 3}]}
        }]
        aa_true "Subcommands in the code will fail (snippet)" [catch {
            ad_safe_eval {
                set test "The clock is now [clock seconds]"
            }
        }]
        aa_true "Chaining commands via semicolon in the code will fail" [catch {
            ad_safe_eval {
                expr {1 + 1}; expr {1 + 2}
            }
        }]
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_sanitize_filename
    } \
    ad__sanitize_filename {
        Tests that sanitizing a filename works as expected.
    } {
        aa_section "Sanitized string without an extension"
        set str "A;\\  <<<ß*>CoOO/etc/passwdl# \"\u001f:: f__?ilename \u0000"
        # Our test string is poisonous enough that this log command
        # would fail...
        # aa_log "Checking against '$str'"
        aa_equals "Basic sanitizing" [ad_sanitize_filename $str] "A  ßCoOOetcpasswdl#  f__ilename "
        aa_equals "Collapsing spaces" [ad_sanitize_filename -collapse_spaces $str] "A-ßCoOOetcpasswdl#-f__ilename-"
        aa_equals "Collapsing spaces with a custom separator" [ad_sanitize_filename -replace_with _ -collapse_spaces $str] "A_ßCoOOetcpasswdl#_f__ilename_"
        aa_equals "Collapsing spaces with a custom separator, to lowercase" [ad_sanitize_filename -tolower -replace_with _ -collapse_spaces $str] [string tolower "A_ßCoOOetcpasswdl#_f__ilename_"]

        aa_true "Sanitizing to an existing filename without resolving throws an error" [catch {
            ad_sanitize_filename \
                -tolower \
                -replace_with _ \
                -collapse_spaces \
                -no_resolve \
                -existing_names {a_ßcoooetcpasswdl#_f__ilename_} \
                $str
        }]
        aa_false "Sanitizing without resolving does not throw an error with an empty list fo existing names" [catch {
            ad_sanitize_filename \
                -tolower \
                -replace_with _ \
                -collapse_spaces \
                -no_resolve \
                -existing_names {} \
                $str
        }]

        set resolved [ad_sanitize_filename \
                          -tolower \
                          -replace_with _ \
                          -collapse_spaces \
                          -existing_names {a_ßcoooetcpasswdl#_f__ilename_} \
                          $str]
        aa_equals "Sanitizing to an existing filename with resolving is fine" $resolved [string tolower "A_ßCoOOetcpasswdl#_f__ilename_"]_2

        aa_section "Sanitized string containing an extension"
        set str "A;\\  <<<ß*>CoOO/etc/passwdl# \"\u001f:: f__?ilename \u0000.extension"
        aa_equals "Basic sanitizing" [ad_sanitize_filename $str] "A  ßCoOOetcpasswdl#  f__ilename .extension"
        aa_equals "Collapsing spaces" [ad_sanitize_filename -collapse_spaces $str] "A-ßCoOOetcpasswdl#-f__ilename-.extension"
        aa_equals "Collapsing spaces with a custom separator" [ad_sanitize_filename -replace_with _ -collapse_spaces $str] "A_ßCoOOetcpasswdl#_f__ilename_.extension"
        aa_equals "Collapsing spaces with a custom separator, to lowercase" [ad_sanitize_filename -tolower -replace_with _ -collapse_spaces $str] [string tolower "A_ßCoOOetcpasswdl#_f__ilename_.extension"]

        aa_true "Sanitizing to an existing filename without resolving throws an error" [catch {
            ad_sanitize_filename \
                -tolower \
                -replace_with _ \
                -collapse_spaces \
                -no_resolve \
                -existing_names {a_ßcoooetcpasswdl#_f__ilename_.extension} \
                $str
        }]
        aa_false "Sanitizing without resolving does not throw an error with an empty list fo existing names" [catch {
            ad_sanitize_filename \
                -tolower \
                -replace_with _ \
                -collapse_spaces \
                -no_resolve \
                -existing_names {} \
                $str
        }]

        set resolved [ad_sanitize_filename \
                          -tolower \
                          -replace_with _ \
                          -collapse_spaces \
                          -existing_names {a_ßcoooetcpasswdl#_f__ilename_.extension} \
                          $str]
        aa_equals "Sanitizing to an existing filename with resolving is fine" $resolved [string tolower "A_ßCoOOetcpasswdl#_f__ilename_.extension"]_2

        aa_false "Sanitizing with not balanced parentheses in the filename does not throw an error" [catch {
            aa_equals "Sanitizing to an existing filename with resolving is fine" [ad_sanitize_filename -existing_names {foo( foo(-3} "foo("] "foo(-4"
        }]
    }


aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    ad_outgoing_sender
    ad_host_administrator
    util_email_valid_p
} host_admin_and_outgoing_sender {
    Test the ad_outgoing_sender and ad_host_administrator procs.
} {
    #
    # HostAdministrator and OutgoingSender should be empty, or valid emails
    #
    set host_admin [ad_host_administrator]
    aa_true "HostAdministrator email ($host_admin) is valid or empty" \
        {$host_admin eq "" || [util_email_valid_p $host_admin]}
    set out_sender [ad_outgoing_sender]
    aa_true "OutgoingSender email ($out_sender) is valid or empty" \
        {$out_sender eq "" || [util_email_valid_p $out_sender]}
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    util_email_valid_p
} util_email_valid_p {
    Test the util_email_valid_p proc.
} {
    #
    # Valid emails
    #
    # See: https://en.wikipedia.org/wiki/Email_address#Examples
    #
    set valid_mails {
        la@lala.la
        openacs@openacs.org
        whatever.is.this@my.mail.com
        discouraged@butvalid
        disposable.style.email.with+symbol@example.com
        other.email-with-hyphen@example.com
        fully-qualified-domain@example.com
        user.name+tag+sorting@example.com
        x@example.com
        example-indeed@strange-example.com
        test/test@test.com
        example@s.example
        john..doe@example.org
        mailhost!username@example.org
        user%example.com@example.org
        user-@example.org
    }
    foreach mail $valid_mails {
        aa_true "Is $mail valid?" [util_email_valid_p $mail]
    }
    #
    # Invalid emails
    #
    set invalid_mails {
        @no.valid
        no.valid
        nope
        A@b@c@example.com
        {a"b(c)d,e:f;g<h>i[j\k]l@example.com}
        {just"not"right@example.com}
        {this is"not\allowed@example.com}
        {this\ still\"not\\allowed@example.com}
        i_like_underscore@but_its_not_allowed_in_this_part.example.com
        {QA[icon]CHOCOLATE[icon]@test.com}
    }
    foreach mail $invalid_mails {
        aa_false "Is $mail valid?" [util_email_valid_p $mail]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    util::name_to_path
} name_to_path {
    Test the util::name_to_path proc.
} {
    set name_paths {
        test1 test1
        "test 2" test-2
        test-3 test-3
        "test 4 is actually pretty long" "test-4-is-actually-pretty-long"
        "TEST 5" "test-5"
        "TeSt 6" "test-6"
        "   test 7    " "test-7"
    }
    dict for {name path} $name_paths {
        aa_equals "Name $name" "[util::name_to_path -name $name]" $path
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    util::string_length_compare
} string_length_compare {
    Test the util::string_length_compare proc.
} {
    #
    # Equal length
    #
    set strings {
        test1 test1
        "test 2" test-2
        test-3 test-3
        "test 4 is actually pretty long" "test-4-is-actually-pretty-long"
        "TEST 5" "test-5"
        "TeSt 6" "test-6"
        "" ""
    }
    dict for {s1 s2} $strings {
        aa_equals "Strings $s1 and $s2" [util::string_length_compare $s1 $s2] 0
    }
    #
    # s1 longer than s2
    #
    set strings {
        test1asdf test1
        "test 2 asdfs " test-2
        test-3- test-3
        "test 4 is actually pretty long !" "test-4-is-actually-pretty-long"
        "TEST 5asd " "test-5"
        "TeSt 6 asd" "test-6"
        " " ""
    }
    dict for {s1 s2} $strings {
        aa_equals "Strings $s1 and $s2" [util::string_length_compare $s1 $s2] 1
    }
    #
    # s2 longer than s1
    #
    set strings {
        test1 test1asdf
        "test 2" test-2sdf
        test-3 test-3ssas
        "test 4 is actually pretty long" "test-4-is-actually-pretty-long-sadfas"
        "TEST 5" "test-5   "
        "TeSt 6" "test-6 sadfsda"
        "" " "
    }
    dict for {s1 s2} $strings {
        aa_equals "Strings $s1 and $s2" [util::string_length_compare $s1 $s2] -1
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    util::word_diff
} word_diff {
    Test the util::word_diff proc.
} {
    #
    # Equal length
    #
    set cases {
        {
            -name "add"
            -old "hello world"
            -new "hello2 world"
            -result {hello<u><b><font color="red">2</font></b></u> world}
        }

        {
            -name "delete"
            -old "hello2 world"
            -new "hello world"
            -result {hello<strike><i><font color="blue">2</font></i></strike> world}
        }

        {
            -name "add begin end"
            -old "ello"
            -new "hello2"
            -result {<u><b><font color="red">h</font></b></u>ello<u><b><font color="red">2</font></b></u>}
        }

        {
            -name "delete begin end"
            -old "hello2"
            -new "ello"
            -result {<strike><i><font color="blue">h</font></i></strike>ello<strike><i><font color="blue">2</font></i></strike>}
        }
    }
    foreach case $cases {
        aa_equals "diff [dict get $case -name]" \
            [util::word_diff -old [dict get $case -old] -new [dict get $case -new]] \
            [dict get $case -result]
    }
}

aa_register_case -cats {
    api
    production_safe
} -procs {
    util::split_location
    util::join_location
} util__split_and_join_location {
    Test util::split_location and util::join_location.
} {
    foreach {location expected_proto expected_hostname expected_port expected_success} {
        aaa "" "" "" 0
        http://miao.bau.com http miao.bau.com 80 1
        aaa.bbb.ccc "" "" "" 0
        https://website.at.domain https website.at.domain 443 1
        http://another.website.com:666 http another.website.com 666 1
        ftp:/ciao.broken.it "" "" "" 0
        aaa.bbb.ccc/path "" "" "" 0
        https://website.at.domain/afile https website.at.domain 443 1
        http://another.website.com:666/andsomecontent http another.website.com 666 1
    } {
        aa_silence_log_entries -severities warning {
            set success [util::split_location $location proto hostname port]
        }
        set expected_success_pretty [expr {$expected_success ? "succeeds" : "fails"}]
        aa_equals "Parsing '$location' $expected_success_pretty" $expected_success $success

        if {$expected_success} {
            aa_equals "Protocol for '$location' is '$expected_proto'" $expected_proto $proto
            aa_equals "Hostname for '$location' is '$expected_hostname'" $expected_hostname $hostname
            aa_equals "Port for '$location' is '$expected_port'" $expected_port $port

            aa_true "Joining back the parsing of '$location' returns the URL itself" \
                [regexp \
                     {^[util::join_location -proto $proto -hostname $hostname -port $port].*$} \
                     $location]
        }
    }
}

aa_register_case -cats {
    api
    production_safe
} -procs {
    util::file_content_check
} util__file_content_check {
    Test util::file_content_check.
} {
    set sourcefile $::acs::rootdir/packages/acs-tcl/tcl/test/utilities-procs.tcl

    set gzip [::util::which gzip]
    if {$gzip ne ""} {
        set file [ad_tmpnam]
        ad_file copy $sourcefile $file
        if {[ad_file exists $file.gz]} {
            ad_file delete $file.gz
        }
        exec $gzip < $file > $file.gz
        aa_true "check detection of gzip file" [util::file_content_check -type gzip -file $file.gz]
        ad_file delete $file.gz
    }
}

aa_register_case -cats {
    api
    smoke
} -procs {
    util_user_message
    util_get_user_messages
    template::multirow
} util_user_messages {
    Test api to provide user messages
} {
    aa_section "Replacing existing messages"

    util_user_message -message ciao
    util_user_message -message ciao
    util_user_message -message ciao
    util_user_message -message miao
    util_user_message -message ciao

    util_user_message -replace -message test

    util_get_user_messages -multirow test_util_get_user_messages

    aa_equals "We have only one message" \
        [template::multirow size test_util_get_user_messages] 1
    aa_equals "Message is the last one" \
        [template::multirow get test_util_get_user_messages 1 message] test


    aa_section "Quoting HTML in messages"

    util_user_message -html -message <div>ciao</div>
    util_user_message -message <div>ciao</div>

    util_get_user_messages -multirow test_util_get_user_messages

    aa_equals "We have only one message" \
        [template::multirow size test_util_get_user_messages] 2
    aa_equals "First message was NOT quoted" \
        [template::multirow get test_util_get_user_messages 1 message] <div>ciao</div>
    aa_equals "Second message was quoted" \
        [template::multirow get test_util_get_user_messages 2 message] [ns_quotehtml <div>ciao</div>]


    aa_section "Repeating messages"

    util_user_message -message ciao
    util_user_message -message ciao
    util_user_message -message ciao
    util_user_message -message miao
    util_user_message -message ciao

    util_get_user_messages -multirow test_util_get_user_messages

    aa_equals "We have 2 messages" \
        [template::multirow size test_util_get_user_messages] 2
    aa_equals "Repeated message includes a counter" \
        [template::multirow get test_util_get_user_messages 1 message] "ciao (4)"
    aa_equals "Single message is unchanged" \
        [template::multirow get test_util_get_user_messages 2 message] miao


    aa_section "Keeping messages"

    util_user_message -message ciao
    util_user_message -message ciao
    util_user_message -message ciao
    util_user_message -message miao
    util_user_message -message ciao

    util_get_user_messages -keep -multirow test_util_get_user_messages

    aa_equals "We have 2 messages" \
        [template::multirow size test_util_get_user_messages] 2

    aa_log "Creating multirow"
    util_get_user_messages -multirow test_util_get_user_messages

    aa_equals "We have 2 messages again" \
        [template::multirow size test_util_get_user_messages] 2
}

aa_register_case -cats {
    api
    smoke
} -procs {
    ad_job
} ad_job {
    Test ad_job proc
} {
    set queue __test_acs_tcl_ad_job

    set result [ad_job -queue $queue expr {1 + 1}]

    aa_equals "Result is 2" \
        $result 2

    aa_true "Error when timeout is reached" [catch {
        ad_job -queue $queue -timeout 0.1 after 200
    }]

    aa_true "Queue exists after calling the proc" {
        $queue in [ns_job queues]
    }
}

aa_register_case -cats {
    api
    smoke
} -procs {
    ad_schedule_proc
    server_cluster_enabled_p
    ad_canonical_server_p
} ad_schedule_proc {
    Test ad_schedule_proc
} {
    set cluster_p [server_cluster_enabled_p]

    try {
        set canonical_server_p [ad_canonical_server_p]
    } on error {errmsg} {
        aa_false "Cluster not enabled, retrieving the canonical server will fail" $cluster_p
        set canonical_server_p false
    }

    foreach all_servers_p {t f} {
        #
        # We schedule a trivial proc.
        #
        set schedule_id [ad_schedule_proc \
                             -thread t \
                             -once t \
                             -debug t \
                             -all_servers $all_servers_p \
                             100 \
                             expr {1 + 1}]

        #
        # According to the instance configuration, our scheduling may
        # be rejected.
        #
        set schedule_p [expr {$canonical_server_p || !$cluster_p || $all_servers_p}]

        if {!$schedule_p} {
            aa_equals "Proc should not be scheduled" \
                $schedule_id ""
        } else {
            set found_p false
            set proc ""
            foreach s [ns_info scheduled] {
                #
                # We may test the correctness of all of these fields,
                # but we will stick to the basics: the scheduled proc
                # is there and the command is the right one.
                #
                set id          [lindex $s 0]
                set flags       [lindex $s 1]
                set next        [lindex $s 3]
                set lastqueue   [lindex $s 4]
                set laststart   [lindex $s 5]
                set lastend     [lindex $s 6]
                set proc        [lindex $s 7]
                set arg         [lrange $s 8 end]
                if {$id == $schedule_id} {
                    set found_p true
                    aa_true "Command was scheduled as expected" \
                        [regexp {^ad_run_scheduled_proc.*expr \{\{1 \+ 1\}\}.*$} $arg]
                    aa_log "Unscheduling the proc"
                    ns_unschedule_proc $id
                }
            }
            aa_true "We found the scheduled proc" \
                $found_p
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
