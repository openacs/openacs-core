#/packages/lang/www/test.tcl
ad_page_contract {

    Tests procedures in the lang package

    @author John Lowry (lowry@ardigita.com)
    @creation-date 29 September 2000
    @cvs-id $Id$
} { }

set title "Test acs-lang package formatting routines"
set header [ad_header $title]
# set navbar [ad_context_bar "Test"]
set footer [ad_footer]

db_1row lang_system_time_select "SELECT to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') AS system_time FROM dual"

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