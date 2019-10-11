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

db_1row lang_system_time_select {}

# Test 5 checks the localization routines
set us_number [lc_numeric 123456.789 {} en_US]
set fr_number [lc_numeric 123456.789 {} fr_FR]
set us_parse [lc_parse_number 123,456.789 en_US]
set fr_parse [lc_parse_number "123 456,789" fr_FR]
set us_time [lc_time_fmt $system_time "%c" en_US]
set fr_time [lc_time_fmt $system_time "%c" fr_FR]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
