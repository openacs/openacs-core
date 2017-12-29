# set-system-timezone.tcl
ad_page_contract {
  Set the acs-lang system parameter which says what the local timezone offset is
} {
    {timezone_all ""}
    {timezone_recommended ""}
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

if { $timezone_recommended ne "" } {
    lang::system::set_timezone $timezone_recommended
} elseif { $timezone_all ne "" } {
    lang::system::set_timezone $timezone_all
}

set page_title "Set System Timezone"
set context [list $page_title]

set system_timezone [lang::system::timezone]

set sysdate [db_string sysdate {}]

set sysdate_utc [db_string sysdate_utc {}]

set system_utc_offset [lang::system::timezone_utc_offset]

multirow create timezones label value selected_p
foreach entry [lc_list_all_timezones] {
    set tz [lindex $entry 0]

    multirow append timezones $entry $tz [string equal $tz $system_timezone]>
}

# Try to get the correct UTC time from www.timeanddate.com
ad_try {
    set h [ns_set create headers Accept-Language en-us]
    set result [util::http::get -url "http://www.timeanddate.com/worldclock/" -headers $h]
    set time_and_date_page [dict get $result page]
} on error {errorMsg} {
    ad_log Error "set-system-timezone.tcl: Error trying to get timeanddate.com/worldclock/"
    set utc_ansi {Couldn't get time from timeanddate.com, sorry.}
}

# example input:
# ss=m3><strong>UTC</strong> \(or GMT/Zulu\)-time used: <strong id=ctu>Friday, July 27, 2012 at 19:20:27</strong>

if { [regexp {<strong>UTC</strong>[^:]+[:][ ]*<strong[^>]*>([^<]+)</strong>} $time_and_date_page match utc_from_page] } {
    # UTC in format (including some historical ones to help keep a robust regexp:
    # Friday, July 27, 2012 at 19:20:27
    # Wednesday, 20 November 2002, at 2:49:07 PM
    # Wednesday, 6 August  2003, at 12:11:48
    # this regexp is a little more flexible and accepting of data types to help with parsing
    set reg_p [regexp -nocase -- {^([^,]+)[,][ ]+([a-z0-9]+)[ ]+([a-z0-9]+)[,]?[ ]+([a-z0-9]+)[at, ]+[ ]+(.*)$} $utc_from_page match weekday day month year time]

    if { $reg_p && [info exists month] && [info exists day] && [info exists year] && [info exists time] } {
        # did timeanddate swap day/month?
        if { [ad_var_type_check_number_p $month] } {
            set temp $day
            set day $month
            set month $temp
            if { $year < 32 } {
                # do you think they swapped day and year?
                set temp $day
                set day $year
                set year $temp
            }
        }
        set utc_epoch [clock scan "${month} ${day}, ${year} ${time}"]
        set utc_ansi [clock format $utc_epoch -format "%Y-%m-%d %T"]
    } else {
        set utc_ansi "Couldn't extract useful time from timeanddate.com, sorry. Got: utc_from_page='${utc_from_page}'"
        ns_log Error "acs-lang/www/admin/set-system-timezone.tcl: Problem extracting UTC time from timeanddate.com, they may have changed their design so our regexp stopped working."
    }
} else {
    set utc_ansi "Couldn't extract time from timeanddate.com, sorry. Got: time_and_date_page='${time_and_date_page}'"
    ns_log Error "acs-lang/www/admin/set-system-timezone.tcl: Problem getting UTC time from timeanddate.com, they may have changed their design so our regexp stopped working."
}

set correct_p {}

if { [info exists utc_epoch] } {
    ad_try {
        set sysdate_utc_epoch [clock scan $sysdate_utc]
        set delta_hours [expr {round(($sysdate_utc_epoch - $utc_epoch)*4.0 / (60*60)) / 4.0}]
        set recommended_offset [expr {$system_utc_offset + $delta_hours}]

        set recommended_offset_pretty "UTC [format {+%d:%02d} [expr {int($recommended_offset)}] [expr {int($recommended_offset*60) % 60}]]"

        if { $delta_hours == 0 } {
            set correct_p 1
        } else {
            set correct_p 0
        }

        set try_offsets [list]
        foreach offset [list $recommended_offset [expr {$recommended_offset -24}]] {
            if { $offset < 0 } {
                lappend try_offsets '[db_quote [expr {-int(abs($offset)*60*60)}]]'
            } else {
                lappend try_offsets '[db_quote [expr {int($offset*60*60)}]]'
            }
        }

        set query "
            select tz.tz, tz.gmt_offset
            from   timezones tz,
                   timezone_rules tzr
            where  tzr.gmt_offset in ([join $try_offsets ", "])
            and    tzr.tz_id = tz.tz_id
            and    to_date('$utc_ansi', 'YYYY-MM-DD HH24:MI:SS') between tzr.utc_start and tzr.utc_end
            order  by tz
        "

        db_multirow -extend { value label selected_p } suggested_timezones select_suggested_timezones $query {
            set selected_p [string equal $tz $system_timezone]
            set value $tz
            set label "$tz $gmt_offset"
        }
    } on error {errorMsg} {
        # Didn't work, too bad
        error $errorMsg $::errorInfo
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
