#/packages/lang/tcl/ad-locale.tcl
ad_library {

    Localization procedures for the ArsDigita Publishing System
    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    @creation-date 28 September 2000
    @author Henry Minsky (hqm@mit.edu)
    @cvs-id $Id$
}


ad_proc -public ad_locale_set_system_timezone { timezone }  { Tell the ACS 
what timezone Oracle thinks it is running in. 

  @param timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
} {
    set pid [apm_package_id_from_key "acs-lang"]
    ad_parameter -set $timezone -package_id $pid SystemTimezone acs-lang 0
}


ad_proc -public ad_locale_get_system_timezone { }  { Ask the ACS 
what it thinks Oracle's timezone is.

  @return  a timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
} {
    set pid [apm_package_id_from_key "acs-lang"]
    return [ad_parameter -package_id $pid SystemTimezone acs-lang 0]
}


ad_proc -public ad_locale_system_tz_offset { } {
    @return number of hours to subtract from local (Oracle) time to get UTC
} {
    set system_timezone [ad_locale_get_system_timezone]
    return [db_string system_offset {
	select ( (sysdate - timezone.local_to_utc (:system_timezone, sysdate)) * 24 )
	from dual
    }]
}



ad_proc -public ad_locale {context item} {

    Returns the value of a locale item in a particular context. For example, to 
    get the language, locale, and timezone preference for the current user:

    <pre>
    set user_lang [ad_locale user language] => en

    set user_locale [ad_locale user locale] => en_US

    set user_tz [ad_locale user timezone] => PST
    </pre>

    To get the preferred language of the current subsite:

    <pre>
    set user_lang [ad_locale subsite language] => ja
    </pre>

    Requires ad_locale_establish_vars to be run as a filter on each web page 
    before this procedure is called.
    @see           ad_locale_establish_vars
    @author        Henry Minsky (hqm@mit.edu)
    
    @param context Context in which a locale value can be obtained.
                   The only context that is currently implemented is user (for the current user).
                   Examples of other contexts that could be implemented are:
                   subsite (for the group that owns the current web page)
    @param item    Specific item of data. 
                   The only items that are implemented are locale, timezone and language.
                   You can change the implementation to add other items as required.
    @return        Value of the item in the specified context

} {
    switch $context {
	user {
	    set locale [ad_get_client_property -cache t "acs-lang" locale]
	    if {[empty_string_p $locale]} {
		set locale [ad_parameter DefaultLocale acs-lang "en_US"]
		ad_locale_set locale $locale
		ad_locale_set lang  [string range $locale 0 1]
		ad_locale_set timezone [ad_parameter DefaultTimezone acs-lang "PST"]
	    }
	    switch $item {
		locale {
		    return $locale
		}
		language {
		    return [string range $locale 0 1]
		}
		timezone {
		    return [ad_get_client_property -cache t "acs-lang" "timezone"]
		}
		default {
		    error "unsupported option to ad_locale: $item"
		}
	    }
	}
	subsite {
	    error "ad_locale: subsite context not yet implemented"
	}
	charset {
	    return [ad_locale_charset_for_locale $item]
	}
	fromabbrev {
	    return [ad_locale_locale_from_abbrev $item]
	}
	default {
	    error "ad_locale: unknown context $context"
	}
    }
}

ad_proc -public ad_locale_set  { item value } {
    Sets the user's preferred locale info as a session var
    <p>
    usage:
    <pre>
    ad_locale_set locale "en_US"
    ad_locale_set timezone "PST"
    </pre>
} {
    set user_id [ad_get_user_id]
    ad_set_client_property -persistent t "acs-lang" $item $value
}

ad_proc -public ad_locale_charset_for_locale { locale } {

    Returns the MIME charset name corresponding to a locale.

    @see           ad_locale
    @author        Henry Minsky (hqm@mit.edu)
    
    @param locale  Name of a locale, as language_COUNTRY using ISO 639 and ISO 3166

    @return        IANA MIME character set name
    

} {
    return [db_string charset_for_locale {
	select mime_charset
	  from ad_locales 
	 where locale = :locale
    }]
}

ad_proc -public ad_locale_locale_from_lang { language } {

    Returns the default locale for a language

    @see           ad_locale
    @author        Henry Minsky (hqm@mit.edu)
    
    @param language  Name of a country, using ISO-3166 two letter code

    @return        IANA MIME character set name
    


} {
    return [db_string default_locale {
	select locale 
	  from ad_locales 
	 where language = :language
               and default_p = 't'
    }]
}


ad_proc -public ad_locale_language_name { language } {

    Returns the default locale for a language

    @see           ad_locale
    @author        Henry Minsky (hqm@mit.edu)
    
    @param language  Name of a country, using ISO-3166 two letter code

    @return        IANA MIME character set name
    


} {
    return [db_string default_locale {
	select nls_language
	  from ad_locales 
	 where language = :language
    }]
}

