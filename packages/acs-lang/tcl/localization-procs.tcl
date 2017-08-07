#/packages/lang/tcl/localization-procs.tcl
ad_library {

    Routines for localizing numbers, dates and monetary amounts
    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    @creation-date 30 September 2000
    @author Jeff Davis (davis@xarg.net) 
    @author Ashok Argent-Katwala (akatwala@arsdigita.com)
    @cvs-id $Id$
}


ad_proc -public lc_parse_number { 
    num 
    locale 
    {integer_only_p 0}
} {
    Converts a number to its canonical 
    representation by stripping everything but the 
    decimal separator and triming left 0's so it 
    won't be octal. It can process the following types of numbers:
    <ul>
    <li>Just digits (allows leading zeros).
    <li>Digits with a valid thousands separator, used consistently (leading zeros not allowed)
    <li>Either of the above with a decimal separator plus optional digits after the decimal marker
    </ul>
    The valid separators are taken from the given locale. Does not handle localized signed numbers in this version.
    The sign may only be placed before the number (with/without whitespace).
    Also allows the empty string, returning same.

    @param num      Localized number
    @param locale   Locale
    @param integer_only_p True if only integers returned
    @error          If unsupported locale or not a number
    @return         Canonical form of the number

} {
    if {$num eq ""} {
	return ""
    }

    set dec  [lc_get -locale $locale "decimal_point"]
    set thou [lc_get -locale $locale "mon_thousands_sep"][lc_get -locale $locale "thousands_sep"]
    set neg  [lc_get -locale $locale "negative_sign"]
    set pos  [lc_get -locale $locale "positive_sign"]

    #
    # Sanity check: decimal point must be different from the thousands
    # separators. This test should be really either in regression
    # testing or be forumulated as constraint after changing the
    # message keys.  However, since a violation can lead to incorrect
    # results, the safety check is here as well.
    #
    if {[string first $dec $thou] > -1} {
	error "error in locale $locale: decimal point '$decimal_point' must be different\
		from thousands separator\
		(mon_thousands_sep '[lc_get -locale $locale mon_thousands_sep]'\
		and thousands_sep '[lc_get -locale $locale thousands_sep]')"
    }

    lang::util::escape_vars_if_not_null {dec thou neg pos}

    # Pattern actually looks like this (separators notwithstanding):
    # {^\ *([-]|[+])?\ *([0-9]+|[1-9][0-9]{1,2}([,][0-9]{3})+)([.][0-9]*)?\ *$}

    set pattern "^\\ *($neg|$pos)?\\ *((\[0-9\]+|\[1-9\]\[0-9\]{0,2}($thou\[0-9\]\{3\})+)"

    if {$integer_only_p} {
	append pattern "?)(${dec}0*)?"
    } else {
	append pattern "?($dec\[0-9\]*)?)"
    }

    append pattern "\\ *\$"

    set is_valid_number  [regexp -- $pattern $num match sign number]

    if {!$is_valid_number} {
	error "Not a number $num"
    } else {

	regsub -all $thou $number "" number

	if {!$integer_only_p} {
	    regsub -all $dec $number "." number
	}

        set number [util::trim_leading_zeros $number]
	
        # Last pathological case
	if {"." eq $number } {
	    set number 0
	}

	if {[string match "\\\\\\${sign}" $neg]} {
	    set number -$number
	}

	return $number
    }
}


ad_proc -private lc_sepfmt { 
    num 
    {grouping {3}}
    {sep ,} 
    {num_re {[0-9]}}
} { 
    Called by lc_numeric and lc_monetary.
    <p>
    Takes a grouping specifier and 
    inserts the given separator into the string. 
    Given a separator of : 
    and a number of 123456789 it returns:
    <pre>
    grouping         Formatted Value
    {3 -1}               123456:789     
    {3}                  123:456:789    
    {3 2 -1}             1234:56:789    
    {3 2}                12:34:56:789   
    {-1}                 123456789      
    </pre>

    @param num        Number
    @param grouping   Grouping specifier
    @param sep        Thousands separator
    @param num_re     Regular expression for valid numbers
    @return           Number formatted with thousand separator
} {
    # with empty separator or grouping string we behave 
    # posixly
    if {$grouping eq "" || $sep eq "" } { 
        return $num
    }
    
    # we need to sanitize the subspec
    regsub -all -- "(\[&\\\\\])" $sep "\\\\\\1" sep

    set match "^(-?$num_re+)("
    set group [lindex $grouping 0]
    
    while { $group > 0} { 
        set re "$match[string repeat $num_re $group])"
        if { ![regsub -- $re $num "\\1$sep\\2" num] } { 
            break 
        } 
        if {[llength $grouping] > 1} { 
            set grouping [lrange $grouping 1 end]
        }
        set group [lindex $grouping 0]
    } 
    
    return $num 
}


ad_proc -public lc_numeric {
    num 
    {fmt {}} 
    {locale ""}
} { 

    Given a number and a locale return a formatted version of the number
    for that locale.

    @param num      Number in canonical form
    @param fmt      Format string used by the Tcl format 
                    command (should be restricted to the form "%.Nf" if present).
    @param locale   Locale
    @return         Localized form of the number

} { 
    if {$fmt ne ""} { 
        set out [format $fmt $num]
    } else { 
        set out $num
    }

    set sep [lc_get -locale $locale "thousands_sep"]
    set dec [lc_get -locale $locale "decimal_point"]
    set grouping [lc_get -locale $locale "grouping"]

    # Fall back on en_US if grouping is not on valid format
    if { $locale ne "en_US" && ![regexp {^[0-9 -]+$} $grouping] } {
        ns_log Warning "lc_numeric: acs-lang.localization-grouping key has invalid value $grouping for locale $locale"
        set sep ,
        set dec .
        set grouping 3
        
    }
    
    regsub {\.} $out $dec out
    return [lc_sepfmt $out $grouping $sep]
}

ad_proc -public clock_to_ansi {
    seconds
} {
    Convert a time in the Tcl internal clock seeconds format to ANSI format, usable by lc_time_fmt.
    
    @author Lars Pind (lars@pinds.com)
    @return ANSI (YYYY-MM-DD HH24:MI:SS) formatted date.
    @see lc_time_fmt
} {
    return [clock format $seconds -format "%Y-%m-%d %H:%M:%S"]
}

ad_proc -public lc_get {
    {-locale ""}
    key
} {
    Get a certain format string for the current locale.

    @param key the key of for the format string you want.
    @return the format string for the current locale.

    @author Lars Pind (lars@pinds.com)
} {
    # All localization message keys have a certain prefix
    set message_key "acs-lang.localization-$key"

    # Set upvar level to 0 so that no attempt is made to interpolate variables
    # into the string
    # Set translator_mode_p to 0 so we don't dress the message up with a link to translate
    return [lang::message::lookup $locale $message_key {} {} 0 0]
}

ad_proc -public lc_time_fmt {
    datetime 
    fmt 
    {locale ""}
} {
    Formats a time for the specified locale.  

    @param datetime        Strictly in the form &quot;YYYY-MM-DD HH24:MI:SS&quot;.
                           Formulae for calculating day of week from the Calendar FAQ 
                           (<a href="http://www.tondering.dk/claus/calendar.html">http://www.tondering.dk/claus/calendar.html</a>)
    @param fmt             An ISO 14652 LC_TIME style formatting string.  The <b>highlighted</b> functions localize automatically based on the user's locale; other strings will use locale-specific text but not necessarily locale-specific formatting.
    <pre>    
      %a           FDCC-set's abbreviated weekday name.
      %A           FDCC-set's full weekday name.
      %b           FDCC-set's abbreviated month name.
      %B           FDCC-set's full month name.
      <b>%c           FDCC-set's appropriate date and time
                   representation.</b>
      %C           Century (a year divided by 100 and truncated to
                   integer) as decimal number (00-99).
      %d           Day of the month as a decimal number (01-31).
      %D           Date in the format mm/dd/yy.
      %e           Day of the month as a decimal number (1-31 in at
                   two-digit field with leading <space> fill).
      %E           Month number as a decimal number (1-12 in at
                   two-digit field with leading <space> fill).
      %f           Weekday as a decimal number (1(Monday)-7).
      %F           is replaced by the date in the format YYYY-MM-DD
                   (ISO 8601 format)
      %h           A synonym for %b.
      %H           Hour (24-hour clock) as a decimal number (00-23).
      %I           Hour (12-hour clock) as a decimal number (01-12).
      %j           Day of the year as a decimal number (001-366).
      %m           Month as a decimal number (01-13).
      %M           Minute as a decimal number (00-59).
      %n           A <newline> character.
      %p           FDCC-set's equivalent of either AM or PM.
      %r           Hours and minutes using 12-hour clock AM/PM
                   notation, e.g. '06:12 AM'. 
      <b>%q           Long date without weekday (OpenACS addition to the standard)</b>
      <b>%Q           Long date with weekday (OpenACS addition to the standard)</b>
      %S           Seconds as a decimal number (00-61).
      %t           A <tab> character.
      %T           24-hour clock time in the format HH:MM:SS.
      %u           Week number of the year as a decimal number with
                   two digits and leading zero, according to "week"
                   keyword.
      %U           Week number of the year (Sunday as the first day of
                   the week) as a decimal number (00-53).
      %w           Weekday as a decimal number (0(Sunday)-6).
      %W           Week number of the year (Monday as the first day of
                   the week) as a decimal number (00-53).
      <b>%x           FDCC-set's appropriate date representation.</b>
      <b>%X           FDCC-set's appropriate time representation.</b>
      %y           Year (offset from %C) as a decimal number (00-99).
      %Y           Year with century as a decimal number.
      %Z           The connection's timezone, e.g. 'America/New_York'.
      %%           A <percent-sign> character.
    </pre>
    See also <pre>man strftime</pre> on a UNIX shell prompt for more of these abbreviations.
    @param locale          Locale identifier must be in the locale database
    @error                 Fails if given a non-existent locale or a malformed datetime
                           Doesn't check for impossible dates. Ask it for 29 Feb 1999 and it will tell you it was a Monday
                           (1st March was a Monday, it wasn't a leap year). Also it only works with the Gregorian calendar -
                           but that's reasonable, but could be a problem if you are running a seriously historical site 
                           (or have an 'on this day in history' style page that goes back a good few hundred years).
    @return                A date formatted for a locale
} {
    if { $datetime eq "" } {
        return ""
    }

    if { $locale eq "" } {
        set locale [ad_conn locale]
    }
    
    # Some initialisation...
    # Now, expect d_fmt, t_fmt and d_t_fmt to exist of the form in ISO spec
    # Rip $date into $lc_time_* as numbers, no leading zeroes
    set matchdate {([0-9]{4})\-0?(1?[0-9])\-0?([1-3]?[0-9])}
    set matchtime {0?([1-2]?[0-9]):0?([1-5]?[0-9]):0?([1-6]?[0-9])}
    set matchfull "$matchdate $matchtime"
    
    set lc_time_p 1
    if {![regexp -- $matchfull $datetime match lc_time_year lc_time_month lc_time_days lc_time_hours lc_time_minutes lc_time_seconds]} {
	if {[regexp -- $matchdate $datetime match lc_time_year lc_time_month lc_time_days]} {
	    set lc_time_hours 0
	    set lc_time_minutes 0
	    set lc_time_seconds 0
	} else {
	    error "Invalid date: $datetime"
	}
    }
    set lc_time_year [util::trim_leading_zeros $lc_time_year]
    
    set a [expr {(14 - $lc_time_month) / 12}]
    set y [expr {$lc_time_year - $a}]
    set m [expr {$lc_time_month + 12*$a - 2}]
    
    # day_no becomes 0 for Sunday, through to 6 for Saturday. Perfect for addressing zero-based lists pulled from locale info.
    set lc_time_day_no [expr {(($lc_time_days + $y + $y/4 - $y/100 + $y/400) + (31 * $m / 12)) % 7}]
    
    return [subst [util_memoize [list lc_time_fmt_compile $fmt $locale]]]
}

ad_proc -public lc_time_fmt_compile {
    fmt 
    locale
} {
    Compiles ISO 14652 LC_TIME style formatting string to variable substitions and proc calls.

    @param fmt             An ISO 14652 LC_TIME style formatting string.
    @param locale          Locale identifier must be in the locale database
    @return                A string that should be subst'ed in the lc_time_fmt proc
                           after local variables have been set.
} {
    set to_process $fmt
        
    set compiled_string ""
    while {[regexp -- {^(.*?)%(.)(.*)$} $to_process match done_portion percent_modifier remaining]} {
	
	switch -exact -- $percent_modifier {
	    x {
		append compiled_string $done_portion
		set to_process "[lc_get -locale $locale "d_fmt"]$remaining"
	    }
	    X {
		append compiled_string $done_portion
		set to_process "[lc_get -locale $locale "t_fmt"]$remaining"
	    }
	    c {
		append compiled_string $done_portion
		set to_process "[lc_get -locale $locale "d_t_fmt"]$remaining"	
	    }
	    q {
		append compiled_string $done_portion
		set to_process "[lc_get -locale $locale "dlong_fmt"]$remaining"	
	    }
	    Q {
		append compiled_string $done_portion
		set to_process "[lc_get -locale $locale "dlongweekday_fmt"]$remaining"	
	    }
	    default {
		append compiled_string "${done_portion}$::lang::util::percent_match($percent_modifier)"
		set to_process $remaining
	    }
	}
    }
    
    # What is left to_process must be (%.)-less, so it should be included without transformation.
    append compiled_string $to_process
    
    return $compiled_string
}

ad_proc -public lc_time_utc_to_local {
    time_value 
    {tz ""}
} {
    Converts a Universal Time to local time for the specified timezone.

    @param time_value        UTC time in the ISO datetime format.
    @param tz                Timezone that must exist in tz_data table.
    @return                  Local time
} {
    if { $tz eq "" } {
        set tz [lang::conn::timezone]
    }

    set local_time $time_value

    if {[catch {
	set local_time [db_exec_plsql utc_to_local {}]
    } errmsg]
    } {
	ns_log Warning "lc_time_utc_to_local: Query exploded on time conversion from UTC, probably just an invalid date, $time_value: $errmsg"
    }

    if {$local_time eq ""} {
	# If no conversion possible, log it and assume local is as given (i.e. UTC)	    
	ns_log Notice "lc_time_utc_to_local: Timezone adjustment in ad_localization.tcl found no conversion to UTC for $time_value $tz"	
    }

    return $local_time
}

ad_proc -public lc_time_local_to_utc {
    time_value 
    {tz ""}
} {
    Converts a local time to a UTC time for the specified timezone.

    @param time_value        Local time in the ISO datetime format, YYYY-MM-DD HH24:MI:SS
    @param tz                Timezone that must exist in tz_data table.
    @return                  UTC time.
} {
    if { $tz eq "" } {
        set tz [lang::conn::timezone]
    }

    set utc_time $time_value
    if {[catch {
	set utc_time [db_exec_plsql local_to_utc {}]
    } errmsg]
    } {
	ns_log Warning "lc_time_local_to_utc: Query exploded on time conversion to UTC, probably just an invalid date, $time_value: $errmsg"
    }

    if {$utc_time eq ""} {
	# If no conversion possible, log it and assume local is as given (i.e. UTC)	    
	ns_log Notice "lc_time_local_to_utc: Timezone adjustment in ad_localization.tcl found no conversion to local time for $time_value $tz"	
    }

    return $utc_time
}




ad_proc -public lc_time_system_to_conn {
    time_value 
} {
    Converts a date from the system (database) to the connection's timezone,
    using the OpenACS timezone setting and user's preference

    @param time_value        Timestamp from the database in the ISO datetime format.
    @return                  Timestamp in conn's local time, also in ISO datetime format.
} {
    if { ![ad_conn isconnected] } {
        return $time_value
    }

    set system_tz [lang::system::timezone]
    set conn_tz [lang::conn::timezone]

    if { $conn_tz eq "" || $system_tz eq $conn_tz } {
        return $time_value
    }

    return [lc_time_tz_convert -from $system_tz -to $conn_tz -time_value $time_value]
}

ad_proc -public lc_time_conn_to_system {
    time_value 
} {
    Converts a date from the connection's timezone to the system (database) timezone, 
    using the OpenACS timezone setting and user's preference

    @param time_value        Timestamp from conn input in the ISO datetime format.
    @return                  Timestamp in the database's time zone, also in ISO datetime format.
} {
    if { ![ad_conn isconnected] } {
        return $time_value
    }

    set system_tz [lang::system::timezone]
    set conn_tz [lang::conn::timezone]

    if { $conn_tz eq "" || $system_tz eq $conn_tz } {
        return $time_value
    }

    return [lc_time_tz_convert -from $conn_tz -to $system_tz -time_value $time_value]
}


ad_proc -public lc_time_tz_convert {
    {-from:required}
    {-to:required}
    {-time_value:required}
} {
    Converts a date from one timezone to another.

    @param time_value        Timestamp in the 'from' timezone, in the ISO datetime format.
    @return                  Timestamp in the 'to' timezone, also in ISO datetime format.
} {
    with_catch errmsg {
        set time_value [db_exec_plsql convert {}]
    } {
        ns_log Warning "lc_time_tz_convert: Error converting timezone: $errmsg"
    }
    return $time_value
}







ad_proc -public lc_list_all_timezones { } {
    @return list of pairs containing all  timezone names and offsets.
    Data drawn from acs-reference package timezones table
} {
    return [db_list_of_lists all_timezones {}]
}



ad_proc -private lc_time_drop_meridian { hours } {
    Converts HH24 to HH12.
} {
    if {$hours > 12} {
	incr hours -12
    } elseif {$hours == 0} {
	set hours 12
    }
    return $hours
}

ad_proc -private lc_wrap_sunday { day_no } {
    To go from 0(Sun) - 6(Sat)
    to 1(Mon) - 7(Sun)
} {
    if {$day_no==0} {
	return 7
    } else {
	return $day_no
    }
}

ad_proc -private lc_time_name_meridian { locale hours } {
    Returns locale data depending on AM or PM.
} {
    if {$hours > 11} {
	return [lc_get -locale $locale "pm_str"]
    } else {
	return [lc_get -locale $locale "am_str"]
    }
}

ad_proc -private lc_leading_space {num} {
    Inserts a leading space for numbers less than 10.
} {
    if {$num < 10} {
	return " $num"
    } else {
	return $num
    }
}


ad_proc -private lc_leading_zeros {
    the_integer 
    n_desired_digits
} {
    Adds leading zeros to an integer to give it the desired number of digits
} {
    return [format "%0${n_desired_digits}d" $the_integer]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
