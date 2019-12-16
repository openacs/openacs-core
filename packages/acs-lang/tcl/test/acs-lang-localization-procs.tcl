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
  }
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs lc_content_size_pretty \
    lang_test__lc_content_size_pretty {

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

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
