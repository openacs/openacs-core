ad_library {

    Tests for utilities

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

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
