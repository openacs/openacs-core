ad_library {
   Test cases for lang-message-procs
   @author Veronica De La Cruz (veronica@viaro.net)
   @creation-date 11 Aug 2006
}

aa_register_case \
    -cats {smoke api} \
    -procs {
        lang::message::register
        lang::message::get
    } \
    test_message_register {
    Simple test that registrates a new message to the BD.

} {
    aa_run_with_teardown -rollback -test_code {

        set message_key [ad_generate_random_string]
        set message [ad_generate_random_string]
        set package_key "acs-translations"
        set locale "en_US"
        aa_log "Creating message : $message || message key: $message_key"

        # Creates the new message
        lang::message::register $locale $package_key $message_key $message

        # Try to retrieve the new message created.

        lang::message::get \
            -package_key $package_key \
            -message_key $message_key \
            -locale $locale \
            -array message_new

        aa_equals "Message add succeeded" $message_new(message) $message
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
