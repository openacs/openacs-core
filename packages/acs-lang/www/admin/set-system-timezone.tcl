# set-system-timezone.tcl
ad_page_contract {
  Set the acs-lang system parameter which says what the local timezone offset is
} {
    {timezone ""}
} -properties {
    page_title
    system_timezone
    sysdate
    system_utc_offset
    timezones:multirow
    utc_ansi
}

if { ![lang::system::timezone_support_p] } {
    ad_return_error "Timezone support not installed" "This installation of the acs-lang package does not support timezone settings. The ref-timezones package needs to be installed first"
    ad_script_abort
}

if {![empty_string_p $timezone]} {
    lang::system::set_timezone $timezone
}

set page_title "Set System Timezone"

set system_timezone [lang::system::timezone]

set sysdate [db_string sysdate {}]

set sysdate_utc [db_string sysdate_utc {}]

set system_utc_offset [lang::system::timezone_utc_offset]

multirow create timezones label value selected_p
foreach entry [lc_list_all_timezones] {
    set tz [lindex $entry 0]
    
    multirow append timezones $entry $tz [string equal $tz $system_timezone]
}

# Try to get the correct UTC time from www.timeanddate.com
if { [catch {
    set time_and_date_page [util_httpget "http://www.timeanddate.com/worldclock/"]

    regexp {Current <b>UTC</b> \(or GMT\)-time used: <b>([^<]*)</b>} $time_and_date_page match utc_from_page

    # UTC in format:
    # Wednesday, November 20, 2002, at 2:49:07 PM

    regexp {^([^,]*), ([^ ]*) ([0-9]*), ([0-9]*), at (.*)$} $utc_from_page match weekday month day year time

    set utc_epoch [clock scan "${month} ${day}, ${year} ${time}"]
    
    set utc_ansi [clock format $utc_epoch -format "%Y-%m-%d %T"]

} errmsg] } {
    global errorInfo
    ns_log Error "Problem getting UTC time from timeanddate.com, they may have changed their design so our regexp stopped working.\n$errorInfo"
    
    set utc_ansi {Couldn't get time from timeanddate.com, sorry.}
}

