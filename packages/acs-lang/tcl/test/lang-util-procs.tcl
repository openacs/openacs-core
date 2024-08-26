ad_library {

    Test cases for tcl/lang-util-procs.tcl

}

aa_register_case \
    -cats {smoke api production_safe} \
    -procs {
        lang::util::edit_lang_key_url
    } \
    test_edit_lang_key_url {

        Test for lang::util::edit_lang_key_url

    } {
        set url [lang::util::edit_lang_key_url \
                     -message somemessage \
                     -package_key package_key]
        aa_equals "Invalid message key returns empty URL" \
            $url ""

        set url [lang::util::edit_lang_key_url \
                     -message package_key.somemessage \
                     -package_key package_key]
        aa_false "Message was start with <package_key>." {
            $url eq ""
        }

        set url [lang::util::edit_lang_key_url \
                     -message "#package_key.somemessage#" \
                     -package_key package_key]

        aa_false "Message may be surrounded by '#'" {
            $url eq ""
        }

        aa_false "URL is a local URL" [util_complete_url_p $url]
        aa_true "URL contains the message key" {
            [string first somemessage $url] >= 0
        }

        aa_true "URL contains the current_locale" {
            [string first [ad_conn locale] $url] >= 0
        }

        aa_true "URL contains the return_url" {
            [string first [ns_urlencode [ad_return_url]] $url] >= 0
        }

    }

aa_register_case \
    -cats {smoke api production_safe} \
    -procs {
        lang::util::message_key_regexp
        lang::util::message_tag_regexp
    } \
    test_message_regexp {
        Test regexp api
    } {
        aa_section lang::util::message_key_regexp

        set r [lang::util::message_key_regexp]

        set values {
            "#apackage.amessage#" true
            "#apackage.amessage" false
            "#apackageamessage#" false
            "apackage.amessage" false
            "#alongpackage.m#" true
        }
        foreach {v e} $values {
            aa_${e} "'$v'" [regexp $r $v]
        }

        aa_section lang::util::message_tag_regexp
        set r [lang::util::message_tag_regexp]

        set values {
            "<#apackage amessage#>" true
            "<#apackageamessage#>" false
            "<#apackage.amessage#>" false
            "#apackage.amessage#>" false
            "<#apackage.amessage#" false
            "apackage.amessage" false
            "<#apackage a message with spaces#>" true
        }
        foreach {v e} $values {
            aa_${e} "'$v'" [regexp $r $v]
        }

    }

aa_register_case \
    -cats {smoke api production_safe} \
    -procs {
        lang::util::localize
        lang::util::localize_list_of_lists
    } \
    test_localize_list_of_lists {
        Test localizeing of a list of lists
    } {
        set list_of_lists [list]
        set list_of_expected [list]
        #
        # Avoid messages containing percentages
        #
        db_foreach get_messages {
            select message_key, package_key
            from lang_messages
            where package_key = 'acs-lang'
            and not message like '%\%%'  
            fetch first 10 rows only
        } {
            lappend list_of_lists [list \
                                       "Test 1 #${package_key}.${message_key}#" \
                                       "Test 2 #${package_key}.${message_key}#" \
                                       "Test 3 #${package_key}.${message_key}#"]
            lappend list_of_expected [list \
                                          [lang::util::localize "Test 1 #${package_key}.${message_key}#"] \
                                          [lang::util::localize "Test 2 #${package_key}.${message_key}#"] \
                                          [lang::util::localize "Test 3 #${package_key}.${message_key}#"]]
        }

        set result [lang::util::localize_list_of_lists -list $list_of_lists]

        foreach r $result e $list_of_expected {
            aa_equals "Result is expected" \
                $r $e
        }
    }

aa_register_case \
    -cats {smoke api} \
    -procs {
        lang::util::translator_mode_set
        lang::util::translator_mode_p
    } \
    test_translator_mode {
        Test localizeing of a list of lists
    } {
        lang::util::translator_mode_set 0
        aa_false "Translator mode is off" [lang::util::translator_mode_p]

        lang::util::translator_mode_set 1
        aa_true "Translator mode is on" [lang::util::translator_mode_p]

        lang::util::translator_mode_set false
        aa_false "Translator mode is off" [lang::util::translator_mode_p]

        lang::util::translator_mode_set true
        aa_true "Translator mode is on" [lang::util::translator_mode_p]

        lang::util::translator_mode_set 0
        aa_false "Translator mode is off" [lang::util::translator_mode_p]
    }
