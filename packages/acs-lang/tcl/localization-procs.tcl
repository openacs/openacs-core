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
    decimal seperator and triming left 0's so it 
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

    set dec [lc_get -locale $locale "decimal_point"]
    set thou [lc_get -locale $locale "mon_thousands_sep"][lc_get -locale $locale "thousands_sep"]
    set neg [lc_get -locale $locale "negative_sign"]
    set pos [lc_get -locale $locale "positive_sign"]

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

	regsub -all "$thou" $number "" number

	if {!$integer_only_p} {
	    regsub -all "$dec" $number "." number
	}


	# Strip leading zeros
	regexp -- "0*(\[0-9\.\]+)" $number match number
	
	# if number is real and mod(number)<1, then we have pulled off the leading zero; i.e. 0.231 -> .231 -- this is still fine for tcl though...
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
    inserts the given seperator into the string. 
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
    # with empty seperator or grouping string we behave 
    # posixly
    if {$grouping eq "" 
        || $sep eq "" } { 
        return $num
    }
    
    # we need to sanitize the subspec
    regsub -all -- "(\[&\\\\\])" $sep "\\\\\\1" sep

    set match "^(-?$num_re+)("
    set group [lindex $grouping 0]
    
    while { 1 && $group > 0} { 
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
    @param fmt      Format string used by the tcl format 
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

ad_proc -public lc_monetary_currency {
    { -label_p 0 }
    { -style local }
    num currency locale
} {
    Formats a monetary amount, based on information held on given currency (ISO code), e.g. GBP, USD.

    @param label_p     Set switch to a true value if you want to specify the label used for the currency.
    @param style       Set to int to display the ISO code as the currency label. Otherwise displays
                       an HTML entity for the currency. The label parameter must be true for this
                       flag to take effect.
    @param num         Number to format as a monetary amount.
    @param currency    ISO currency code.
    @param locale      Locale used for formatting the number.
    @return            Formatted monetary amount
} {

    set row_returned [db_0or1row lc_currency_select {}]

    if { !$row_returned } {
	ns_log Warning "lc_monetary_currency: Unsupported monetary currency, defaulting digits to 2"
	set fractional_digits 2
	set html_entity ""
    }
    
    if { $label_p } {
	if {$style eq "int" } {
	    set use_as_label $currency
	} else {
	    set use_as_label $html_entity
	}
    } else {
	set use_as_label ""
    }
    
    return [lc_monetary -- $num $locale $fractional_digits $use_as_label]
}


ad_proc -private lc_monetary {
    { -label_p 0 }
    { -style local }
    { -truncate_p "t"}
    num 
    locale 
    {forced_frac_digits ""} 
    {forced_currency_symbol ""}
} { 
    Returns the monetary amount formatted with (optional) currency symbol, decimal character and group separator. 
    Accepts as input a number num and the user's locale. Returns the number formatted as money with (optional) currency 
    symbol, decimal character and group separator based on the locale. It uses message keys to control these symbols - 
    the message keys are stored in the acs-lang catalog files. We should call lc_monetary with label_p set to "t", as we 
    want to display the currency symbol. We can override the locale's currency symbol by setting forced_currency_symbol 
    to whatever symbol we want to display (but should rarely need to do this). 
    
    By default, lc_monetary will truncate (round down) to the number of decimal places given by the 
    acs-lang.localization-trunc_decimal_places message key for the locale. This truncating behaviour can be changed to 
    instead round up by passing in to lc_monetary the value "f" for truncate_p. The lc_monetary proc will then round up 
    to the value of the acs-lang frac_digits message key for the locale (the value of which in turn can be over-ridden by 
    passing forced_frac_digits to lc_monetary). If truncate_p is true, forced_frac_digits will be ignored.
    
    
    @param label_p     Specify this switch if you want to specify the label used for the currency.
    @param style       Set to int to display the ISO code as the currency label. Otherwise displays
                       an HTML entity for the currency. The label parameter must be specified for this
                       flag to take effect.
    @param num         Number to format as a monetary amount. If this number could be negative
                       you should put &quot;--&quot; in your call before it.
    @param locale      Locale used for formatting the number - this uses the acs-lang message keys.
    @param forced_frac_digits      Pass this in to override the acs-lang frac_digits or int_frac_digits. If truncate_p is true, forced_frac_digits will be ignored.
    @param forced_currency_symbol  Pass this in to override the acs-lang int_curr_symbol or currency_symbol.
    @param truncate_p  Pass this in if you want to to truncate (round down) to a number of decimal places. The number of 
    decimal places is determined by the acs-lang.localization-trunc_decimal_places message key, and should be a positive integer. For AIMS
    we default this to true.
    @return            Formatted monetary amount
} { 

    if {$num eq ""} {
      #if they enter empty string, return empty string
      #pages like payments end up getting 0.00 in empty cells otherwise
      return $num
    } else {
		#first escape the locale's decimal character (dec) if it's in the list of chars that need to be escaped in regular expressions
		set dec [lc_get -locale $locale "mon_decimal_point"]
		set esc_dec $dec
		set special_chars {[\^$.|?*+()}
		if {[regexp $dec $special_chars]} {set esc_dec "\\$dec"}  
	  #need to strip all non-numerics except the locale's decimal character
  		if {![regexp {^\-?[0-9]+$} $num]} {
    		regexp {^(\-?)(.*)} $num "" negg numm
    		regsub -all "\[^0-9$esc_dec\]" $numm "" numm
    		set num ""
    		append num $negg $numm
  		}
 		#replace the locale's decimal character with the database's decimal character (assuming for now that it's ".")
		regsub -all "$esc_dec"  $num "." num

		if {![empty_string_p $forced_frac_digits] && [string is integer $forced_frac_digits]} {
		  set dig $forced_frac_digits
		} else {
		  # look up the digits
		  if {[string compare $style int] == 0} { 
			  set dig [lc_get -locale $locale "int_frac_digits"]
		  } else { 
			  set dig [lc_get -locale $locale "frac_digits"]
		  }
		}

		# figure out if negative 
		if {$num < 0} { 
			set num [expr abs($num)]
			set neg 1
		} else { 
			set neg 0
		}

		# generate formatted number
		# Check if we are truncating
		if {$truncate_p} {
		  set trunc_decimal_places [lc_get -locale $locale "trunc_decimal_places"]
		  set truncated_num [expr [expr floor([expr $num * pow(10,$trunc_decimal_places)])]/pow(10,$trunc_decimal_places)]
		  set out [format "%.${trunc_decimal_places}f" $truncated_num]
		} else {
		  set out [format "%.${dig}f" $num]    
		}


		# look up the label if needed 
		if {[empty_string_p $forced_currency_symbol]} {
		  if {$label_p} {
			if {[string compare $style int] == 0} { 
			  set sym [lc_get -locale $locale "int_curr_symbol"]
			} else { 
			  set sym [lc_get -locale $locale "currency_symbol"]
			}
		  } else { 
			  set sym {}
		  }
		} else {
		  set sym $forced_currency_symbol
		}

		# signorama
		if {$neg} { 
			set cs_precedes [lc_get -locale $locale "n_cs_precedes"]
			set sep_by_space [lc_get -locale $locale "n_sep_by_space"]
			set sign_pos [lc_get -locale $locale "n_sign_posn"]
			set sign [lc_get -locale $locale "negative_sign"]
		} else {
			set cs_precedes [lc_get -locale $locale "p_cs_precedes"]
			set sep_by_space [lc_get -locale $locale "p_sep_by_space"]
			set sign_pos [lc_get -locale $locale "p_sign_posn"]
			set sign [lc_get -locale $locale "positive_sign"]
		} 

		# change decimal seperator back from dot to locales version
		regsub {\.} $out $dec out

		# commify
		set sep [lc_get -locale $locale "mon_thousands_sep"]
		if {[ad_var_type_check_number_p $sep]} {
		    # The separator is a number. This is bad as it will bring bogus results and crash the server
		    set sep ","
		}
		
		set grouping [lc_get -locale $locale "mon_grouping"]
		set num [lc_sepfmt $out $grouping $sep]

		return [subst [nsv_get locale "money:$cs_precedes$sign_pos$sep_by_space"]]
	}
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
    @error                 Fails if given a non-existant locale or a malformed datetime
                           Doesn't check for impossible dates. Ask it for 29 Feb 1999 and it will tell you it was a Monday
                           (1st March was a Monday, it wasn't a leap year). Also it only works with the Gregorian calendar -
                           but that's reasonable, but could be a problem if you are running a seriously historical site 
                           (or have an 'on this day in history' style page that goes back a good few hundred years).
    @return                A date formatted for a locale
} {
    if { $datetime eq "" } {
        return ""
    }

    if { ![exists_and_not_null locale] } {
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

    set a [expr (14 - $lc_time_month) / 12]
    set y [expr {$lc_time_year - $a}]
    set m [expr {$lc_time_month + 12*$a - 2}]
    
    # day_no becomes 0 for Sunday, through to 6 for Saturday. Perfect for addressing zero-based lists pulled from locale info.
    set lc_time_day_no [expr (($lc_time_days + $y + ($y/4) - ($y / 100) + ($y / 400)) + ((31*$m) / 12)) % 7]
    
    return [subst [util_memoize "lc_time_fmt_compile {$fmt} $locale"]]
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
    if {$hours>12} {
	incr hours -12
    } elseif {$hours==0} {
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
