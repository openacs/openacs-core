ad_library {
    Helper test Tcl procedures.

    @author Gustaf Neumann
    @creation-date Sept 2013
}

namespace eval lang::test {}


aa_register_case \
    -procs {

      lc_numeric
      lc_parse_number
      lc_time_fmt
      lc_time_utc_to_local
      lc_time_local_to_utc
      lc_clock_to_ansi
      lc_time_conn_to_system
      lc_time_system_to_conn
      lc_time_tz_convert
      lang::system::set_timezone
      lang::conn::timezone

      lang::catalog::import
      lang::catalog::import
      lang::system::locale_set_enabled

    } lang_test__lc_procs {

    Minimal testset for localization functions. To be extended.

    @author Gustaf Neumann
    @creation-date Sept 2013
} {

  aa_run_with_teardown -rollback -test_code {

    lang::system::locale_set_enabled -locale de_DE -enabled_p true
    lang::system::locale_set_enabled -locale it_IT -enabled_p true

    lang::catalog::import -locales it_IT -package_key acs-lang
    lang::catalog::import -locales de_DE -package_key acs-lang

    aa_equals "format us number" [lc_numeric 123456.789 {} en_US] 123,456.789
    aa_equals "format de number" [lc_numeric 123456.789 {} de_DE] 123.456,789
    aa_equals "format it number" [lc_numeric 123456.789 {} it_IT] 123.456,789

    aa_equals "parse us number" [lc_parse_number 123,456.789 en_US] 123456.789
    aa_equals "parse de number" [lc_parse_number 123.456,789 de_DE] 123456.789
    aa_equals "parse it number" [lc_parse_number 123.456,789 it_IT] 123456.789

    set time [lc_time_fmt "2013-09-21 23:11:22" "%c" en_US]
    aa_equals "format us time" [lrange $time 0 end-1] "Sat September 21, 2013 11:11 PM"

    set time [lc_time_fmt "2013-09-21 23:11:22" "%c" de_DE]
    aa_equals "format us time" [lrange $time 0 end-1] "Sa, 21. September 2013 23:11"

    set time [lc_time_fmt "2013-09-21 23:11:22" "%c" it_IT]
    aa_equals "format us time" [lrange $time 0 end-1] "Sab 21 Settembre 2013 23:11"

    aa_equals "asian time " [lc_time_utc_to_local "2013-09-21 23:11:22" "Asia/Tokyo"] "2013-09-22 08:11:22"
    aa_equals "local time " [lc_time_local_to_utc "2013-09-22 08:11:22" "Asia/Tokyo"] "2013-09-21 23:11:22"

    set time [lc_time_fmt "2013-09-21 23:11:22" "%c" en_US]
    aa_equals "format en_US time" [lrange $time 0 end-1] "Sat September 21, 2013 11:11 PM"

    set time [lc_time_fmt "2013-09-21 23:11:22" "%c" de_DE]
    aa_equals "format de_DE time" [lrange $time 0 end-1] "Sa, 21. September 2013 23:11"

    set time [lc_time_fmt "2013-09-21 23:11:22" "%c" it_IT]
    aa_equals "format it_IT time" [lrange $time 0 end-1] "Sab 21 Settembre 2013 23:11"

    aa_equals "asian time " [lc_time_utc_to_local "2013-09-21 23:11:22" "Asia/Tokyo"] "2013-09-22 08:11:22"
    aa_equals "local time " [lc_time_local_to_utc "2013-09-22 08:11:22" "Asia/Tokyo"] "2013-09-21 23:11:22"

    set db_timestamp "2019-12-16 12:11:52.125541+01"
    set time [lc_time_fmt $db_timestamp "%c" en_US]
    aa_equals "format en_US time" [lrange $time 0 end-1] "Mon December 16, 2019 12:11 PM"

    set time [lc_time_fmt $db_timestamp "%c" de_DE]
    aa_equals "format de_DE time" [lrange $time 0 end-1] "Mo, 16. Dezember 2019 12:11"

    set time [lc_time_fmt $db_timestamp "%c" it_IT]
    aa_equals "format it_IT time" [lrange $time 0 end-1] "Lun 16 Dicembre 2019 12:11"

    set short_timestamp "2019-12-16 12:11"
    set time [lc_time_fmt $short_timestamp "%c" en_US]
    aa_equals "format en_US time" [lrange $time 0 end-1] "Mon December 16, 2019 12:11 PM"

    set time [lc_time_fmt $short_timestamp "%c" de_DE]
    aa_equals "format de_DE time" [lrange $time 0 end-1] "Mo, 16. Dezember 2019 12:11"

    set time [lc_time_fmt $short_timestamp "%c" it_IT]
    aa_equals "format it_IT time" [lrange $time 0 end-1] "Lun 16 Dicembre 2019 12:11"

    set time [lc_clock_to_ansi 1613657099]
    aa_equals "lc_clock_to_ansi" $time "2021-02-18 15:04:59"

    set time [lc_time_tz_convert -from Europe/Vienna -to Europe/Vienna -time_value "2021-02-18 15:04:59"]
    aa_equals "lc_time_tz_convert from and to Europe/Vienna" $time "2021-02-18 15:04:59"

    set time [lc_time_tz_convert -from Europe/Vienna -to America/New_York -time_value "2021-02-18 15:04:59"]
    aa_equals "lc_time_tz_convert from and to Europe/Vienna" $time "2021-02-18 09:04:59"

    set time [lc_time_tz_convert -from Europe/Vienna -to Europe/Vienna -time_value "2021-02-18 15:04"]
    aa_equals "lc_time_tz_convert from and to Europe/Vienna (short time format)" $time "2021-02-18 15:04:00"

    set time [lc_time_tz_convert -from Europe/Vienna -to America/New_York -time_value "2021-02-18 15:04"]
    aa_equals "lc_time_tz_convert from and to Europe/Vienna (short time format)" $time "2021-02-18 09:04:00"

    #
    # There is no easy way to change the conn::timezone. So set the
    # system timezone to the lang::conn::timezone to get a
    # reproducible result. Since we are running in a transaction, no
    # harm is done.
    #
    lang::system::set_timezone [lang::conn::timezone]
    set time [lc_time_conn_to_system "2021-02-18 15:04:59"]
    aa_equals "lc_time_conn_to_system" $time "2021-02-18 15:04:59"

    set time [lc_time_system_to_conn "2021-02-18 15:04:59"]
    aa_equals "lc_time_system_to_conn" $time "2021-02-18 15:04:59"

  }
}

aa_register_case \
    -cats {
        api smoke production_safe
    } \
    -procs {
        lc_time_tz_convert
        lc_time_local_to_utc
        lc_list_all_timezones
    } lang_test__lc_timezones {

        Test conversion between timezones and other timezone-related
        behavior.

    } {
        set tcl9 [string match 9* $::tcl_version]
        aa_section "From and to the same timezone"

        set time [lc_time_tz_convert -from Europe/Vienna -to Europe/Vienna -time_value "2021-02-18 15:04:59"]
        aa_equals "lc_time_tz_convert from and to Europe/Vienna (2021-02-18 15:04:59)" $time "2021-02-18 15:04:59"

        set time [lc_time_tz_convert -from Europe/Vienna -to Europe/Vienna -time_value "0621-01-01 00:00:00"]
        aa_equals "lc_time_tz_convert from and to Europe/Vienna (0621-01-01 00:00:00)" $time "0621-01-01 00:00:00"

        set time [lc_time_tz_convert -from Europe/Vienna -to Europe/Vienna -time_value "1581-01-01 00:00:00"]
        aa_equals "lc_time_tz_convert from and to Europe/Vienna (1581-01-01 00:00:00)" $time "1581-01-01 00:00:00"

        set time [lc_time_tz_convert -from Europe/Vienna -to Europe/Vienna -time_value "1583-01-01 00:00:00"]
        aa_equals "lc_time_tz_convert from and to Europe/Vienna (1583-01-01 00:00:00)" $time "1583-01-01 00:00:00"

        if {!$tcl9} {
            #
            # In Tcl9 "2000-00-00 00:00:00" is an invalid date
            #
            set time [lc_time_tz_convert -from Europe/Vienna -to Europe/Vienna -time_value "2000-00-00 00:00:00"]
            aa_equals "lc_time_tz_convert from and to Europe/Vienna (2000-00-00 00:00:00)" $time "1999-11-30 00:00:00"
        }

        aa_silence_log_entries -severities warning {
            aa_equals "lc_time_tz_convert from and to Europe/Vienna ('Broken!', invalid date)" \
                [lc_time_tz_convert -from Europe/Vienna -to Europe/Vienna -time_value "Broken!"] ""
        }

        set time [lc_time_tz_convert -from Europe/Vienna -to Europe/Vienna -time_value "1900-01-01 00:00:00"]
        aa_equals "lc_time_tz_convert from and to Europe/Vienna (1900-01-01 00:00:00)" $time "1900-01-01 00:00:00"


        aa_section "From one timezone to another"

        set time [lc_time_tz_convert -from Europe/Vienna -to America/New_York -time_value "2021-02-18 15:04:59"]
        aa_equals "lc_time_tz_convert from Europe/Vienna to America/New_York (2021-02-18 15:04:59)" $time "2021-02-18 09:04:59"

        set time [lc_time_tz_convert -from Europe/Vienna -to America/New_York -time_value "0621-01-01 00:00:00"]
        aa_equals "lc_time_tz_convert from Europe/Vienna to America/New_York (0621-01-01 00:00:00, before USA Timezones 1893-11-18)" $time "0620-12-31 17:58:37"

        set time [lc_time_tz_convert -from Europe/Vienna -to America/New_York -time_value "1581-01-01 00:00:00"]
        aa_equals "lc_time_tz_convert from Europe/Vienna to America/New_York (1581-01-01 00:00:00, before USA Timezones 1893-11-18)" $time "1580-12-31 17:58:37"

        set time [lc_time_tz_convert -from Europe/Vienna -to America/New_York -time_value "1893-11-19 00:00:00"]
        aa_equals "lc_time_tz_convert from Europe/Vienna to America/New_York (1893-11-19 00:00:00, after USA Timezones 1893-11-18)" $time "1893-11-18 18:00:00"

        if {!$tcl9} {
            set time [lc_time_tz_convert -from Europe/Vienna -to America/New_York -time_value "2000-00-00 00:00:00"]
            aa_equals "lc_time_tz_convert from Europe/Vienna to America/New_York (2000-00-00 00:00:00)" $time "1999-11-29 18:00:00"
        }

        set time [lc_time_tz_convert -from Europe/Vienna -to America/New_York -time_value "1900-01-01 00:00:00"]
        aa_equals "lc_time_tz_convert from Europe/Vienna to America/New_York (1900-01-01 00:00:00)" $time "1899-12-31 18:00:00"

        set time [lc_time_tz_convert -from Europe/Vienna -to America/New_York -time_value "3000-01-01 00:00:00"]
        aa_equals "lc_time_tz_convert from Europe/Vienna to America/New_York (3000-01-01 00:00:00, distant future)" $time "2999-12-31 18:00:00"

        aa_silence_log_entries -severities warning {
            aa_equals "lc_time_tz_convert from Europe/Vienna to America/New_York ('Broken!', invalid date)" \
                [lc_time_tz_convert -from Europe/Vienna -to America/New_York -time_value "Broken!"] ""
        }


        aa_section "From one timezone to another, checking daylight savings"

        set time [lc_time_tz_convert -from Europe/Vienna -to Brazil/East -time_value "2016-02-01 00:00:00"]
        aa_equals "lc_time_tz_convert from Europe/Vienna to Brazil/East (2016-02-01 00:00:00)" $time "2016-01-31 21:00:00"

        set time [lc_time_tz_convert -from Europe/Vienna -to Brazil/East -time_value "2016-02-22 00:00:00"]
        aa_equals "lc_time_tz_convert from Europe/Vienna to Brazil/East (2016-02-22 00:00:00)" $time "2016-02-21 20:00:00"

        set time [lc_time_tz_convert -from Europe/Vienna -to Brazil/East -time_value "2016-03-28 00:00:00"]
        aa_equals "lc_time_tz_convert from Europe/Vienna to Brazil/East (2016-03-28 00:00:00)" $time "2016-03-27 19:00:00"

        set time [lc_time_tz_convert -from Europe/Vienna -to Brazil/East -time_value "2016-10-17 00:00:00"]
        aa_equals "lc_time_tz_convert from Europe/Vienna to Brazil/East (2016-10-17 00:00:00)" $time "2016-10-16 20:00:00"

        set time [lc_time_tz_convert -from Europe/Vienna -to Brazil/East -time_value "2016-10-31 00:00:00"]
        aa_equals "lc_time_tz_convert from Europe/Vienna to Brazil/East (2016-10-31 00:00:00)" $time "2016-10-30 21:00:00"

        aa_section "Check that conversion to/from every supported timezone succeeds"

        set timezones [lc_list_all_timezones]

        foreach to $timezones {
            set to [lindex $to 0]
            aa_silence_log_entries -severities notice {
                aa_false "Converting valid date '2021-02-18 15:04:59' from 'Europe/Vienna' to valid timezone '$to' does not return empty" \
                    [expr {[lc_time_tz_convert -from Europe/Vienna -to $to -time_value "2021-02-18 15:04:59"] eq ""}]
            }
        }

        foreach from $timezones {
            set from [lindex $from 0]
            aa_silence_log_entries -severities notice {
                aa_false "Converting valid date '2021-02-18 15:04:59' from valid timezone '$from' to 'Europe/Vienna' does not return empty" \
                    [expr {[lc_time_tz_convert -from $from -to Europe/Vienna -time_value "2021-02-18 15:04:59"] eq ""}]
            }
        }

        aa_section "Check that invalid timezones are rejected instead"

        aa_equals "Converting to an invalid 'Bogus' timezone returns empty" \
            [lc_time_tz_convert -from Europe/Vienna -to Bogus -time_value "2021-02-18 15:04:59"] ""

        aa_equals "Converting from an invalid 'Bogus' timezone returns empty" \
            [lc_time_tz_convert -from Bogus -to Europe/Vienna -time_value "2021-02-18 15:04:59"] ""


        aa_section "Convert to UTC"

        set tz Europe/Vienna

        set time [lc_time_local_to_utc "2021-02-18 15:04:59" $tz]
        aa_equals "lc_time_local_to_utc from Europe/Vienna (2021-02-18 15:04:59)" $time "2021-02-18 14:04:59"

        set time [lc_time_local_to_utc "0621-01-01 00:00:00" $tz]
        aa_equals "lc_time_local_to_utc from Europe/Vienna (0621-01-01 00:00:00)" $time "0620-12-31 22:54:39"

        set time [lc_time_local_to_utc "1581-01-01 00:00:00" $tz]
        aa_equals "lc_time_local_to_utc from Europe/Vienna (1581-01-01 00:00:00)" $time "1580-12-31 22:54:39"

        set time [lc_time_local_to_utc "1583-01-01 00:00:00" $tz]
        aa_equals "lc_time_local_to_utc from Europe/Vienna (1583-01-01 00:00:00)" $time "1582-12-31 22:54:39"

        if {!$tcl9} {
            set time [lc_time_local_to_utc "2000-00-00 00:00:00" $tz]
            aa_equals "lc_time_local_to_utc from Europe/Vienna (2000-00-00 00:00:00)" $time "1999-11-29 23:00:00"
        }

        aa_silence_log_entries -severities warning {
            aa_equals "lc_time_local_to_utc from Europe/Vienna ('Broken!', invalid date)" \
                [lc_time_local_to_utc "Broken!" $tz] ""
        }

        set time [lc_time_local_to_utc "1900-01-01 00:00:00" $tz]
        aa_equals "lc_time_local_to_utc from Europe/Vienna (1900-01-01 00:00:00)" $time "1899-12-31 23:00:00"

        foreach from $timezones {
            break
            set from [lindex $from 0]
            aa_false "Converting valid date '2021-02-18 15:04:59' from valid timezone '$from' to 'UTC' does not return empty or 0" \
                [expr {[lc_time_local_to_utc "2021-02-18 15:04:59" $from] eq ""}]
        }

    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        lc_get
        lc_numeric
        lc_content_size_pretty
    } lang_test__lc_content_size_pretty {

        Test lc_content_size_pretty proc

        @author Héctor Romojaro <hector.romojaro@gmail.com>
        @creation-date 2019-06-25

} {
    #
    # Localized byte/s
    #
    set byte  [lc_get "byte"]
    set bytes [lc_get "bytes"]

    aa_equals "No arguments binary"     [lc_content_size_pretty -standard "binary"]                                          "[lc_numeric 0] $bytes"
    aa_equals "No arguments legacy"     [lc_content_size_pretty -standard "legacy"]                                          "[lc_numeric 0] $bytes"
    aa_equals "No arguments decimal"    [lc_content_size_pretty]                                                             "[lc_numeric 0] $bytes"
    aa_equals "Empty value binary"      [lc_content_size_pretty -size "" -standard "binary"]                                 "[lc_numeric 0] $bytes"
    aa_equals "Empty value legacy"      [lc_content_size_pretty -size "" -standard "legacy"]                                 "[lc_numeric 0] $bytes"
    aa_equals "Empty value decimal"     [lc_content_size_pretty -size ""]                                                    "[lc_numeric 0] $bytes"
    aa_equals "1 byte"                  [lc_content_size_pretty -size 1 -standard "binary"]                                  "[lc_numeric 1] $byte"
    aa_equals "1 byte"                  [lc_content_size_pretty -size 1 -standard "legacy"]                                  "[lc_numeric 1] $byte"
    aa_equals "1 byte"                  [lc_content_size_pretty -size 1]                                                     "[lc_numeric 1] $byte"
    aa_equals "1.0 KiB"                 [lc_content_size_pretty -size 1024 -standard "binary"]                               "[lc_numeric 1.0] KiB"
    aa_equals "1.0 KB"                  [lc_content_size_pretty -size 1024 -standard "legacy"]                               "[lc_numeric 1.0] KB"
    aa_equals "1.0 KB"                  [lc_content_size_pretty -size 1000]                                                  "[lc_numeric 1.0] kB"
    aa_equals "1.0 MiB"                 [lc_content_size_pretty -size 1048576 -standard "binary"]                            "[lc_numeric 1.0] MiB"
    aa_equals "1.0 MB"                  [lc_content_size_pretty -size 1048576 -standard "legacy"]                            "[lc_numeric 1.0] MB"
    aa_equals "1.0 MB"                  [lc_content_size_pretty -size 1000000]                                               "[lc_numeric 1.0] MB"
    aa_equals "1.0 GiB"                 [lc_content_size_pretty -size 1073741824 -standard "binary"]                         "[lc_numeric 1.0] GiB"
    aa_equals "1.0 GB"                  [lc_content_size_pretty -size 1073741824 -standard "legacy"]                         "[lc_numeric 1.0] GB"
    aa_equals "1.0 GB"                  [lc_content_size_pretty -size 1000000000]                                            "[lc_numeric 1.0] GB"
    aa_equals "1.0 TiB"                 [lc_content_size_pretty -size 1099511627800 -standard "binary"]                      "[lc_numeric 1.0] TiB"
    aa_equals "1.0 TB"                  [lc_content_size_pretty -size 1099511627800 -standard "legacy"]                      "[lc_numeric 1.0] TB"
    aa_equals "1.0 TB"                  [lc_content_size_pretty -size 1000000000000]                                         "[lc_numeric 1.0] TB"
    aa_equals "1.0 PiB"                 [lc_content_size_pretty -size 1125899906842620 -standard "binary"]                   "[lc_numeric 1.0] PiB"
    aa_equals "1.0 PB"                  [lc_content_size_pretty -size 1125899906842620 -standard "legacy"]                   "[lc_numeric 1.0] PB"
    aa_equals "1.0 PB"                  [lc_content_size_pretty -size 1000000000000000]                                      "[lc_numeric 1.0] PB"
    aa_equals "1.0 EiB"                 [lc_content_size_pretty -size 1152921504606850000 -standard "binary"]                "[lc_numeric 1.0] EiB"
    aa_equals "1.0 EB"                  [lc_content_size_pretty -size 1152921504606850000 -standard "legacy"]                "[lc_numeric 1.0] EB"
    aa_equals "1.0 EB"                  [lc_content_size_pretty -size 1000000000000000000]                                   "[lc_numeric 1.0] EB"
    aa_equals "1.0 ZiB"                 [lc_content_size_pretty -size 1180591620717410000000 -standard "binary"]             "[lc_numeric 1.0] ZiB"
    aa_equals "1.0 ZB"                  [lc_content_size_pretty -size 1180591620717410000000 -standard "legacy"]             "[lc_numeric 1.0] ZB"
    aa_equals "1.0 ZB"                  [lc_content_size_pretty -size 1000000000000000000000]                                "[lc_numeric 1.0] ZB"
    aa_equals "1.0 YiB"                 [lc_content_size_pretty -size 1208925819614630000000000 -standard "binary"]          "[lc_numeric 1.0] YiB"
    aa_equals "1.0 YB"                  [lc_content_size_pretty -size 1208925819614630000000000 -standard "legacy"]          "[lc_numeric 1.0] YB"
    aa_equals "1.0 YB"                  [lc_content_size_pretty -size 1000000000000000000000000]                             "[lc_numeric 1.0] YB"
    aa_equals "1.3 YiB"                 [lc_content_size_pretty -size 1571603565499020000000000 -standard "binary"]          "[lc_numeric 1.3] YiB"
    aa_equals "1.3 YB"                  [lc_content_size_pretty -size 1571603565499020000000000 -standard "legacy"]          "[lc_numeric 1.3] YB"
    aa_equals "1.3 YB"                  [lc_content_size_pretty -size 1300000000000000000000000]                             "[lc_numeric 1.3] YB"
    aa_equals "1.000 KiB"               [lc_content_size_pretty -size 1024 -precision 3 -standard "binary"]                  "[lc_numeric 1.000] KiB"
    aa_equals "1.000 KB"                [lc_content_size_pretty -size 1024 -precision 3 -standard "legacy"]                  "[lc_numeric 1.000] KB"
    aa_equals "1.000 kB"                [lc_content_size_pretty -size 1000 -precision 3]                                     "[lc_numeric 1.000] kB"
    aa_equals "1 KiB"                   [lc_content_size_pretty -size 1024 -precision 0 -standard "binary"]                  "[lc_numeric 1] KiB"
    aa_equals "1 KB"                    [lc_content_size_pretty -size 1024 -precision 0 -standard "legacy"]                  "[lc_numeric 1] KB"
    aa_equals "1 kB"                    [lc_content_size_pretty -size 1000 -precision 0]                                     "[lc_numeric 1] kB"
    aa_equals "1 KiB"                   [lc_content_size_pretty -size 1044 -precision 0 -standard "binary"]                  "[lc_numeric 1] KiB"
    aa_equals "1 KB"                    [lc_content_size_pretty -size 1044 -precision 0 -standard "legacy"]                  "[lc_numeric 1] KB"
    aa_equals "1 kB"                    [lc_content_size_pretty -size 1080 -precision 0]                                     "[lc_numeric 1] kB"
    aa_equals "1.01953 -> 1.020 KiB"    [lc_content_size_pretty -size 1044 -precision 3 -standard "binary"]                  "[lc_numeric 1.020] KiB"
    aa_equals "1.01953 -> 1.020 KB"     [lc_content_size_pretty -size 1044 -precision 3 -standard "legacy"]                  "[lc_numeric 1.020] KB"
    aa_equals "1.080 kB"                [lc_content_size_pretty -size 1080 -precision 3]                                     "[lc_numeric 1.080] kB"
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs lang::util::convert_to_i18n \
    lang_test__convert_to_i18n {

        Tests lang::util::convert_to_i18n

    } {
        aa_run_with_teardown -rollback -test_code {
            set package_key acs-translations
            set message_key [ad_generate_random_string]
            set it_text [ad_generate_random_string]
            aa_log "Registering new #${package_key}.$message_key# in it_IT first"
            lang::util::convert_to_i18n \
                -locale it_IT \
                -package_key $package_key \
                -message_key $message_key \
                -text $it_text

            aa_true "#${package_key}.$message_key#: fallback en_US message was registered" [db_string check {
                select case when exists (select 1 from lang_messages
                               where package_key = :package_key
                               and message_key = :message_key
                               and locale = 'en_US'
                               and message = :it_text) then 1 else 0 end
                from dual
            }]

            aa_log "#${package_key}.$message_key#: en_US message"
            set en_text [ad_generate_random_string]
            lang::util::convert_to_i18n \
                -locale en_US \
                -package_key $package_key \
                -message_key $message_key \
                -text $en_text
            aa_true "#${package_key}.$message_key#: en_US message was updated, while it_IT message was not affected" [db_string check {
                select case when exists (select 1 from lang_messages
                                         where package_key = :package_key
                                         and message_key = :message_key
                                         and locale = 'en_US'
                                         and message = :en_text) and
                                 exists (select 1 from lang_messages
                                         where package_key = :package_key
                                         and message_key = :message_key
                                         and locale = 'it_IT'
                                         and message = :it_text) then 1 else 0 end
                from dual
            }]

            aa_log "Update the it_IT message for #${package_key}.$message_key#"
            set it_text [ad_generate_random_string]
            lang::util::convert_to_i18n \
                -locale it_IT \
                -package_key $package_key \
                -message_key $message_key \
                -text $it_text
            aa_true "#${package_key}.$message_key#: it_IT message was updated, while en_US message was not affected" [db_string check {
                select case when exists (select 1 from lang_messages
                                         where package_key = :package_key
                                         and message_key = :message_key
                                         and locale = 'en_US'
                                         and message = :en_text) and
                                 exists (select 1 from lang_messages
                                         where package_key = :package_key
                                         and message_key = :message_key
                                         and locale = 'it_IT'
                                         and message = :it_text) then 1 else 0 end
                from dual
            }]
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        lang::user::set_locale
        lang::user::site_wide_locale
        lang::util::localize
    } \
    lang_test__lang_user_site_wide_locale {

        Tests what happens when a user has an unsupported locale
        stored in the preferences.

    } {
        aa_run_with_teardown -rollback -test_code {
            set one_user_id [db_string q {select user_id from user_preferences fetch first 1 rows only}]

            set user_locale [lang::user::site_wide_locale -user_id $one_user_id]
            aa_log "Locale for user '$one_user_id' is '$user_locale'"

            set unsupported_locale [db_string q {
                select min(locale) from ad_locales
                where enabled_p = 'f'
            } -default ""]

            if {$unsupported_locale eq ""} {
                aa_log "There are no unsupported locales on the system."
            } else {
                lang::user::set_locale -user_id $one_user_id $unsupported_locale

                set user_locale_db [db_string q {
                    select locale from user_preferences where user_id = :one_user_id
                }]
                aa_equals "Locale was stored in the user_preferences" \
                    $user_locale_db $unsupported_locale

                set user_locale [lang::user::site_wide_locale -user_id $one_user_id]
                aa_equals "The api retrieves the unsupported locale" \
                    $user_locale $unsupported_locale

                set error_p [catch {
                    set t [lang::util::localize \
                               {lang_test__lang_user_site_wide_locale #acs-lang.Locale#} \
                               $user_locale]
                } errmsg]
                aa_false "Localizing a message key using an unsupported locale does not fail" $error_p

                if {$error_p} {
                    aa_log "Error: $errmsg"
                } else {
                    aa_true "Test string was localized as '$t'" \
                        [regexp {^lang_test__lang_user_site_wide_locale .*$} $t]
                }
            }
        }
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
