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
        lang::message::delete
    } \
    test_message_register {

        Test the registration of a new message key, retrieval, soft
        deletion and reinstating.

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

        aa_log "Soft-delete the message"
        lang::message::delete \
            -package_key $package_key \
            -message_key $message_key \
            -locale $locale

        set key "${package_key}.${message_key}"
        aa_false "The nsv was deleted" [nsv_exists lang_message_$locale $key]

        aa_log "Delete the nsv regardless to simulate the behavior after restart"
        nsv_unset -nocomplain -- lang_message_$locale $key

        aa_true "Message still exists, flagged as deleted" [db_0or1row check {
            select 1 from lang_messages
            where locale = :locale
            and package_key = :package_key
            and message_key = :message_key
            and deleted_p
        }]

        # Register the message again
        lang::message::register $locale $package_key $message_key $message

        aa_true "Message was reinstated" [db_0or1row check {
            select 1 from lang_messages
            where locale = :locale
            and package_key = :package_key
            and message_key = :message_key
            and not deleted_p
        }]
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
