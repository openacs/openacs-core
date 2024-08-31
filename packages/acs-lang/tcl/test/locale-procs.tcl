ad_library {

    Test cases for tcl/locale-procs.tcl

}

aa_register_case \
    -cats {smoke api} \
    -procs {
        lang::system::timezone_utc_offset
        lang::system::timezone
    } \
    test_timezone_offset {

        Test for api retrieving the locales

    } {
        set clock_offset [clock format [clock seconds] -format %z -timezone [lang::system::timezone]]
        regexp {^(\+|-)0*(\d+)$} $clock_offset _ op hours
        if {$op eq "-"} {
            set expected -
        }
        append expected [expr {$hours / 100}]

        aa_equals "lang::system::timezone_utc_offset returns expected" \
            [lang::system::timezone_utc_offset] $expected
    }

aa_register_case \
    -cats {smoke api} \
    -procs {
        lang::system::get_locales
        lang::system::get_locale_options
        lang::util::get_locale_options
        lang::system::language
        lang::system::locale
        lang::util::get_label
        lang::util::language_label
        lang::util::iso6392_from_language
        lang::util::iso6392_from_locale
        lang::util::nls_language_from_language
        lang::system::package_level_locale
        lang::system::use_package_level_locales_p
        lang::user::locale
        lang::user::language
        lang::user::package_level_locale
        lang::system::set_locale
        lang::user::set_locale
        lang::conn::locale
        lang::conn::charset
        lang::conn::language
        lang::util::charset_for_locale
    } \
    test_get_locales {

        Test for api retrieving the locales

    } {
        aa_run_with_teardown -rollback -test_code {

            set system_locale [lang::system::locale]
            set system_locales [lang::system::get_locales]

            aa_equals "lang::system::get_locales returns expected" \
                [lsort $system_locales] \
                [lsort [db_list q {select locale from ad_locales where enabled_p = 't'}]]

            set enabled_locale_options [lang::system::get_locale_options]
            aa_equals "lang::system::get_locale_options returns expected" \
                [lsort $enabled_locale_options] \
                [lsort [db_list_of_lists q {
                    select label, locale from ad_locales where enabled_p = 't'
                }]]

            foreach l $enabled_locale_options {
                lassign $l label locale
                set language [lindex [split $locale _] 0]
                aa_equals "lang::util::nls_language_from_language returns expected for '$language'" \
                    [lang::util::nls_language_from_language $language] \
                    [db_string nls_language_from_language {
                        select nls_language
                        from   ad_locales
                        where  lower(trim(language)) = lower(:language)
                        and  enabled_p = 't'
                        fetch first 1 rows only
                    }]
            }

            set locale_options [lang::util::get_locale_options]
            aa_equals "lang::util::get_locale_options returns expected" \
                $locale_options \
                [db_list_of_lists q {
                    select label, locale from ad_locales order by label
                }]

            foreach l $locale_options {
                lassign $l label locale
                aa_equals "lang::util::get_label returns expected for '$locale'" \
                    [lang::util::get_label $locale] $label

                set language [lindex [split $locale _] 0]
                set iso6392 [lang::util::iso6392_from_locale -locale $locale]
                aa_equals "lang::util::iso6392_from_locale returns expected for '$locale'" \
                    $iso6392 \
                    [lang::util::iso6392_from_language -language $language]

                if {$iso6392 ne ""} {
                    aa_equals "lang::util::iso6392_from_language returns expected for '$locale'" \
                        [lang::util::iso6392_from_language -language $language] \
                        [db_string q {
                            select iso_639_2 from language_639_2_codes
                            where iso_639_1 = :language or iso_639_2 = :language
                        }]

                    aa_equals "lang::util::language_label returns expected for '$locale'" \
                        [lang::util::language_label -language $language] \
                        [db_string q {
                            select label from language_639_2_codes
                            where iso_639_1 = :language or iso_639_2 = :language
                        }]
                }
            }

            aa_true "System locale belongs to the list of enabled locales" {
                $system_locale in $system_locales
            }

            aa_equals "System language returns expected" \
                [lang::system::language] [string range $system_locale 0 1]
            aa_equals "System language returns expected (iso6392)" \
                [lang::system::language -iso6392] \
                [lang::util::iso6392_from_language -language [string range $system_locale 0 1]]

            set package_id [apm_package_id_from_key "acs-lang"]

            parameter::set_value \
                -parameter UsePackageLevelLocalesP \
                -package_id $package_id -value 1

            lang::system::set_locale -package_id $package_id it_IT

            aa_true "Package level locale is enabled" [lang::system::use_package_level_locales_p]
            aa_equals "Package level locale is it_IT" \
                [lang::system::package_level_locale $package_id] \
                it_IT

            set user_id [ad_conn user_id]

            aa_equals "Package locale on, user locale off" \
                [lang::user::locale -package_id $package_id -user_id $user_id] \
                it_IT

            #
            # Here are the specs for two different languages to reduce
            # assumptions about potential predefined locales.
            #
            lassign {de_DE de deu} testLocale testLang testIso6392
            #lassign {es_ES es spa} testLocale testLang testIso6392

            lang::system::locale_set_enabled -locale $testLocale -enabled_p t

            lang::user::set_locale -package_id $package_id -user_id $user_id $testLocale

            aa_equals "Package locale on, user locale on" \
                [lang::user::locale -package_id $package_id -user_id $user_id] \
                $testLocale

            db_foreach q {
                select locale, mime_charset
                from ad_locales
            } {
                aa_equals "lang::util::charset_for_locale returns expected for '$locale'" \
                    [lang::util::charset_for_locale $locale] $mime_charset

                lappend charsets($locale) $mime_charset
            }

            set conn_locale [lang::conn::locale -package_id $package_id -user_id $user_id]
            aa_equals "Conn locale is correct" $conn_locale $testLocale

            aa_equals "Conn language is correct" \
                [lang::conn::language -package_id $package_id -user_id $user_id] $testLang
            aa_equals "Conn language is correct" \
                [lang::conn::language -package_id $package_id -user_id $user_id -iso6392] $testIso6392

            set conn_charset [lang::conn::charset]
            aa_equals "Conn charset is correct" \
                $conn_charset $charsets($system_locale)
            aa_equals "Conn charset is correct" \
                $conn_charset [lang::util::charset_for_locale $system_locale]

            aa_equals "User language returns expected" \
                [lang::user::language -package_id $package_id -user_id $user_id] $testLang
            aa_equals "User language returns expected (iso6392)" \
                [lang::user::language -package_id $package_id -user_id $user_id -iso6392] \
                [lang::util::iso6392_from_language -language $testIso6392]

            parameter::set_value \
                -parameter UsePackageLevelLocalesP \
                -package_id $package_id -value 0
            aa_false "Package level locale is disabled" [lang::system::use_package_level_locales_p]

            aa_equals "Package locale off, user locale on" \
                [lang::user::locale -package_id $package_id -user_id $user_id] \
                $system_locale

            aa_equals "User language returns expected" \
                [lang::user::language -package_id $package_id -user_id $user_id] en
            aa_equals "User language returns expected (iso6392)" \
                [lang::user::language -package_id $package_id -user_id $user_id -iso6392] \
                [lang::util::iso6392_from_language -language en]

            set conn_locale [lang::conn::locale -package_id $package_id -user_id $user_id]
            set conn_language [lang::conn::language -package_id $package_id -user_id $user_id]
            aa_equals "Conn locale is correct (Cached by request!)" $conn_locale $testLocale
            aa_equals "Conn language is correct (Cached by request!)" \
                [lang::conn::language -package_id $package_id -user_id $user_id] $testLang
            aa_equals "Conn language is correct (Cached by request!)" \
                [lang::conn::language -package_id $package_id -user_id $user_id -iso6392] $testIso6392
        }

    }
