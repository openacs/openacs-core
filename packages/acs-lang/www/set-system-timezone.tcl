# set-system-timezone.tcl

ad_page_contract {
  Set the acs-lang system parameter which says what the local timezone  offset is

} {
    {timezone ""}
}

if {![empty_string_p $timezone]} {
    ad_locale_set_system_timezone $timezone
}
set title "Set System Timezone"

append page "
[ad_admin_header $title]
<h2>$title</h2>
[ad_context_bar]
<hr>


ACS currently believes that Oracle is running in the
timezone <b>[ad_locale_get_system_timezone]</b>
<p>

If this is correct, then the offset between the time returned by
SYSDATE, [db_string sysdate {select to_char(sysdate, 'YYYY-MM-DD
HH24:MI:SS') from dual }], and UTC time should be [ad_locale_system_tz_offset] hours.
<p>


"

set widget "<select name=timezone>"
set systz [ad_locale_get_system_timezone]

foreach {entry} [lc_list_all_timezones] {
    set tz [lindex $entry 0]
    set offset [lindex $entry 1]
    if {[string compare $tz $systz] == 0} {
	append widget "<option selected value=\"$tz\">$entry</option>"
    } else {
	append widget "<option value=\"$tz\">$entry</option>"
    }

}

append widget "</select>"

append page "
<hr>

You can use the form below to tell ACS what timezone Oracle is operating in.
(There does not appear to be a nice way to ask Oracle this question automatically).
<p>

<form action=set-system-timezone method=get>

Set Timezone $widget
<p>
<input type=submit>
</form>
"

doc_return 200 text/html $page

