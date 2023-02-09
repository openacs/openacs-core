ad_library {

    Test cases for tcl/lang-util-procs.tcl

}

aa_register_case \
    -cats {smoke api} \
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
