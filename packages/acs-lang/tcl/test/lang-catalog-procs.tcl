ad_library {

    Test cases for tcl/lang-catalog-procs.tcl

}

aa_register_case \
    -cats {smoke api} \
    -procs {
        lang::catalog::export
        lang::catalog::import
        lang::catalog::package_delete
        lang::message::cache
        lang::message::message_exists_p
        lang::message::update_description
        lang::audit::changed_message
    } \
    test_catalog_import_export {

        Test import/export of catalog files

    } {
        aa_run_with_teardown -rollback -test_code {
            set catalog_path [lang::catalog::get_catalog_file_path \
                                  -package_key acs-lang -locale en_US]

            set catalog_checksum [ns_md file $catalog_path]
            set catalog_mtime [file mtime $catalog_path]

            lang::catalog::export \
                -package_key acs-lang -locales en_US

            aa_equals "Catalog was unchanged after export" \
                $catalog_checksum [ns_md file $catalog_path]

            aa_true "File was actually touched" {
                $catalog_mtime < [file mtime $catalog_path]
            }

            set n_messages [db_string count {
                select count(*) from lang_messages
                where package_key = 'acs-lang' and locale = 'en_US'
            }]

            db_1row get_one_message {
                select message_key, message
                from lang_messages
                where package_key = 'acs-lang'
                and locale = 'en_US'
                fetch first 1 rows only
            }
            set key acs-lang.${message_key}

            aa_true "Message key '$message_key' exists" \
                [lang::message::message_exists_p -varname exist_var en_US $key]
            aa_equals "Message key '$message_key' was retrieved" $exist_var $message

            set old_description [db_string desc {
                select description from lang_message_keys
                where message_key = :message_key
                and package_key = 'acs-lang'
            }]

            aa_log "Update description for '$key'"
            lang::message::update_description \
                -package_key acs-lang \
                -message_key $message_key \
                -description {Test Description}

            aa_equals "Description was updated" \
                [db_string desc {
                    select description from lang_message_keys
                    where message_key = :message_key
                    and package_key = 'acs-lang'
                }] \
                {Test Description}

            aa_log "Reset description for '$key'"
            lang::message::update_description \
                -package_key acs-lang \
                -message_key $key \
                -description $old_description

            aa_log "Store an audit message for '$key'"
            lang::audit::changed_message \
                $message \
                acs-lang \
                $message_key \
                en_US \
                {Audit Comment} \
                false \
                [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}] \
                false \
                "no_upgrade"

            db_1row get_audit {
                select audit_id, comment_text, overwrite_user
                from lang_messages_audit
                order by audit_id desc
                fetch first 1 rows only
            }
            aa_equals "The comment text was stored" $comment_text {Audit Comment}
            aa_equals "The comment user is us" $overwrite_user [ad_conn user_id]

            aa_log "Cleanup test audit message"
            db_dml cleanup {delete from lang_messages_audit where audit_id = :audit_id}

            set result [lang::catalog::import \
                            -package_key acs-lang -locales en_US]

            aa_equals "All keys for this package and locale have been processed" \
                [dict get $result processed] \
                $n_messages
            aa_equals "All keys added"  [dict get $result added]   0
            aa_equals "No keys deleted" [dict get $result deleted] 0
            aa_equals "No keys updated" [dict get $result updated] 0

            aa_log "Delete all message keys and reload them"
            lang::catalog::package_delete -package_key acs-lang

            aa_equals "There are no messages for this package anymore" \
                [db_string count {
                    select count(*) from lang_message_keys
                    where package_key = 'acs-lang'
                }] \
                0

            unset -nocomplain exist_var
            aa_false "Message key '$message_key' does not exist" \
                [lang::message::message_exists_p -varname exist_var en_US $key]
            aa_false "Message key '$message_key' was not retrieved" [info exists exist_var]

            set result [lang::catalog::import \
                            -package_key acs-lang -locales en_US]

            #
            # Avoid test side-effects by re-loading also other locales
            #
            lang::catalog::import \
                -package_key acs-lang -locales [lang::system::get_locales]

            aa_equals "All keys for this package and locale have been processed" \
                [dict get $result processed] \
                $n_messages
            aa_equals "No keys added"   [dict get $result added]   $n_messages
            aa_equals "No keys deleted" [dict get $result deleted] 0
            aa_equals "No keys updated" [dict get $result updated] 0

            aa_true "Message key '$message_key' exists" \
                [lang::message::message_exists_p -varname exist_var en_US $key]
            aa_equals "Message key '$message_key' was retrieved" $exist_var $message
        }
    }
