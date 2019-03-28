#/packages/lang/www/test.tcl
ad_page_contract {

    Tests procedures in the lang package

    @author John Lowry (lowry@ardigita.com)
    @creation-date 29 September 2000
    @cvs-id $Id$
} { }

set title "Test lang package"
set header [ad_header $title]
# set navbar [ad_context_bar "Test"]
set footer [ad_footer]

# Test 1 verifies that the message catalog has loaded successfully
set english [_ en test.English]
set french [_ fr test.French]
set spanish [_ es test.Spanish]
set german [_ de test.German]

#set lang [lang::user::language]
set lang [ad_get_client_property lang locale]
if {$lang eq ""} {
    set lang "en"
}

db_1row lang_get_lang_name "SELECT nls_language as language FROM ad_locales WHERE language = :lang"
if {$language eq ""} {
    set language English
}

# Test 2 checks the locale cookie to display in user's preferred language.
# We cannot embed the tags in the template because they will not get run each time.
# So we won't see the results of changing the locale cookie immediately.
set trn_english [ns_adp_parse "<trn key=\"test.English\">English</trn>"]
set trn_french [ns_adp_parse "<trn key=\"test.French\">French</trn>"]
set trn_spanish [ns_adp_parse "<trn key=\"test.Spanish\">Spanish</trn>"]
set trn_german [ns_adp_parse "<trn key=\"test.German\">German</trn>"]

# Test 3 checks that the timezone tables are installed
# Need this data to check that test 4 works
set tz_sql "SELECT tz as timezone
                   ,local_start
                   ,local_end
                   ,ROUND(timezones.gmt_offset * 24) as utc_offset
              FROM timezone_rules, timezones
             WHERE timezones.tz = 'Europe/Paris'
                   and timezone_rules.tz_id = timezones.tz_id
               AND local_start > sysdate - 365
               AND local_end < sysdate + 365
          ORDER BY local_start"
db_multirow tz_results lang_tz_get_data $tz_sql

# Test 4 checks that we can convert from local time to UTC
db_1row lang_system_time_select "SELECT to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') AS system_time FROM dual"

set paris_time [lc_time_utc_to_local $system_time "Europe/Paris"]
set local_time [lc_time_local_to_utc $paris_time "Europe/Paris"]


set tokyo_time [lc_time_utc_to_local $system_time "Asia/Tokyo"]
set tokyo_utc_time [lc_time_local_to_utc $paris_time "Asia/Tokyo"]


# Test 5 checks the localization routines
set us_number [lc_numeric 123456.789 {} en_US]
set fr_number [lc_numeric 123456.789 {} fr_FR]
set us_parse [lc_parse_number 123,456.789 en_US]
set fr_parse [lc_parse_number "123 456,789" fr_FR]
set us_currency [lc_monetary_currency -label_p 1 -style local 123.4 USD en_US]
set fr_currency [lc_monetary_currency -label_p 1 -style local 123.4 USD fr_FR]
set us_label [lc_monetary_currency -label_p 1 -style local 1234 FRF en_US]
set fr_label [lc_monetary_currency -label_p 1 -style local 1234 FRF fr_FR]
set us_time [lc_time_fmt $system_time "%c" en_US]
set fr_time [lc_time_fmt $system_time "%c" fr_FR]

ad_return_template