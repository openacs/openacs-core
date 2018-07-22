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

    } lang_test__lc_numeric {

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

  }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
