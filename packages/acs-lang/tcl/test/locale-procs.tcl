ad_library {

    Test cases for tcl/locale-procs.tcl

}

aa_register_case \
    -cats {smoke api} \
    -procs {
        lang::system::get_locales
        lang::system::get_locale_options
        lang::system::language
        lang::system::locale
        lang::util::iso6392_from_language
        lang::system::package_level_locale
        lang::system::use_package_level_locales_p
        lang::user::locale
        lang::user::language
        lang::user::package_level_locale
        lang::system::set_locale
        lang::user::set_locale
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

            aa_equals "lang::system::get_locale_options returns expected" \
                [lsort [lang::system::get_locale_options]] \
                [lsort [db_list_of_lists q {
                    select label, locale from ad_locales where enabled_p = 't'
                }]]

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

            lang::user::set_locale -package_id $package_id -user_id $user_id de_DE

            aa_equals "Package locale on, user locale on" \
                [lang::user::locale -package_id $package_id -user_id $user_id] \
                de_DE

            aa_equals "User language returns expected" \
                [lang::user::language -package_id $package_id -user_id $user_id] de
            aa_equals "User language returns expected (iso6392)" \
                [lang::user::language -package_id $package_id -user_id $user_id -iso6392] \
                [lang::util::iso6392_from_language -language de]

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
        }

    }


