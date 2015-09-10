
ad_page_contract {
 Test system timezone offset mechanism

} {
}



append page "
ad_locale_system_timezone = [ad_locale_get_system_timezone]
ad_locale_system_tz_offset = [ad_locale_system_tz_offset]
<p>

"

set widget "<select name=gmt_offset>"

foreach {tz} [lc_list_all_timezones] {
    append widget "<option value=\"$tz\">$tz</option>"
}

append widget "</select>"

append page "
<form action=tz-test method=get>
Timezone $widget
<p>
<input type=submit>
</form>
"

doc_return 200 text/html $page


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
