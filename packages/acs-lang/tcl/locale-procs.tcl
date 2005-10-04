#/packages/lang/tcl/ad-locale.tcl
ad_library {

    Localization procedures for OpenACS
    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    @creation-date 28 September 2000
    @author Henry Minsky (hqm@mit.edu)
    @author Lars Pind (lars@pinds.com)
    @cvs-id $Id$
}

namespace eval lang::system {}
namespace eval lang::user {}
namespace eval lang::conn {}



#####
#
# lang::system
#
#####

ad_proc -public lang::system::use_package_level_locales_p {} {
    Returns whether we're using package level locales.
} { 
    return [parameter::get -parameter UsePackageLevelLocalesP -package_id [apm_package_id_from_key "acs-lang"] -default 0]
}

ad_proc -public lang::system::site_wide_locale {
} {
    Get the site wide system locale setting.
} {
    set parameter_locale [parameter::get \
                -package_id [apm_package_id_from_key "acs-lang"] \
                -parameter "SiteWideLocale" \
                -default "en_US"]

    # Check validity of parameter setting
    set valid_locales [lang::system::get_locales]
    if { [lsearch -exact $valid_locales $parameter_locale] == -1 } {
        ns_log Error "The parameter setting acs-lang.SiteWideLocale=\"$parameter_locale\" is invalid. Valid locales are: \"$valid_locales\". Defaulting to en_US locale"
        return en_US
    }

    return $parameter_locale
}

ad_proc -private lang::system::package_level_locale_not_cached {
    package_id
} {
    return [db_string get_package_locale {} -default {}]
}

ad_proc -public lang::system::package_level_locale {
    package_id
} {
    @return empty string if not use_package_level_locales_p, or the package locale from apm_packages table.
} {
    if { ![use_package_level_locales_p] } {
        return {}
    }

    return [util_memoize [list lang::system::package_level_locale_not_cached $package_id]]
}

ad_proc -public lang::system::locale {
    {-package_id ""}
    {-site_wide:boolean}
} {
    Get system locale setting for a given package instance.
    
    @param package_id The package for which you want to get the locale setting.
    @param site_wide Set this if you want to get the site-wide locale setting.
} {
    if { $site_wide_p } {
        return [site_wide_locale]
    } 

    if { [empty_string_p $package_id] && [ad_conn isconnected] } {
        set package_id [ad_conn package_id]
    }

    # Get locale for package

    set locale [package_level_locale $package_id]

    # If there's no package setting, use the site-wide setting
    if { [empty_string_p $locale] } {
        set locale [site_wide_locale]
    } 
    return $locale
}

ad_proc -public lang::system::set_locale {
    {-package_id ""}
    locale
} {
    Set system locale setting for a given package instance, or the
    site-wide system locale.
    
    @param package_id The package for which you want to set the locale setting, if you want to set system setting for one package only. Leave blank for site-wide setting.
    @param locale The new locale that you want to use as your system locale.
} {
    if { [empty_string_p $package_id] } {

        parameter::set_value \
            -package_id [apm_package_id_from_key "acs-lang"] \
            -parameter SiteWideLocale \
            -value $locale

    } else {
        # Update the setting
        db_dml update_system_locale {}
        
        # Flush the cache
        util_memoize_flush [list lang::system::package_level_locale_not_cached $package_id]

        # TODO: We will need to have site-map inheritance for this, so packages under a subsite/dotlrn inherit the subsite's/dotlrn's setting
    }
}

ad_proc -public lang::system::language {
    {-package_id ""}
    {-site_wide:boolean}
} {
    Get system language setting for a given package instance.
    
    @param package_id The package for which you want to get the language setting.
    @param site_wide Set this if you want to get the site-wide language setting.
} {
    return [string range [locale -package_id $package_id -site_wide=$site_wide_p] 0 1]
}

ad_proc -public lang::system::timezone {} {
    Ask OpenACS what it thinks our timezone is.
    
    @return  a timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
} {
    if { ![lang::system::timezone_support_p] } {
        return ""
    }

    set package_id [apm_package_id_from_key "acs-lang"]
    return [parameter::get -package_id $package_id -parameter SystemTimezone -default "Etc/UTC"]
}

ad_proc -private lang::system::timezone_support_p {} {
    Return 1 if this installation of acs-lang offers 
    timezone services and 0 otherwise.

    For the acs-lang package to offer timezone support the
    ref-timezones and acs-reference packages need to be installed.
    Those packages are currently not part of the OpenACS kernel.
} {
    return [apm_package_installed_p ref-timezones]
}
    
ad_proc -public lang::system::set_timezone { 
    timezone
}  { 
    Tell OpenACS what timezone we think it's running in.
    
    @param timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
} {
    if { ![lang::system::timezone_support_p] } {
        return ""
    }

    set package_id [apm_package_id_from_key "acs-lang"]
    parameter::set_value -package_id $package_id -parameter SystemTimezone -value $timezone
}

ad_proc -public lang::system::timezone_utc_offset { } {
    @return number of hours to subtract from local (database) time to get UTC
} {
    if { ![lang::system::timezone_support_p] } {
        return ""
    }

    set system_timezone [timezone]
    return [db_string system_utc_offset {}]
}

ad_proc -public lang::system::get_locales {} {
    Return all enabled locales in the system. Cached

    @author Peter Marklund
} {
    return [util_memoize lang::system::get_locales_not_cached]
}

ad_proc -public lang::system::get_locale_options {} {
    Return all enabled locales in the system in a format suitable for the options argument of a form.

    @author Lars Pind
} {
    return [util_memoize lang::system::get_locale_options_not_cached]
}

ad_proc -public lang::system::locale_set_enabled { 
    {-locale:required}
    {-enabled_p:required}
} {
    Enables or disables a locale.

    @param enabled_p Should be t or f

    @author Peter Marklund
} {
    db_dml set_enabled_p { update ad_locales set enabled_p = :enabled_p where locale = :locale }

    # Flush caches
    util_memoize_flush_regexp {^lang::util::default_locale_from_lang_not_cached}
    util_memoize_flush_regexp {^lang::system::get_locales}
    util_memoize_flush_regexp {^lang::system::get_locale_options}
}

ad_proc -private lang::system::get_locales_not_cached {} {
    Return all enabled locales in the system.

    @author Peter Marklund
} {
    return [db_list select_system_locales {
        select locale
        from   ad_locales
        where  enabled_p = 't'
    }]
}

ad_proc -private lang::system::get_locale_options_not_cached {} {
    Return all enabled locales in the system in a format suitable for the options argument of a form.

    @author Lars Pind
} {
    return [db_list_of_lists select_locales {}]
}


#####
#
# lang::user
#
#####

ad_proc -private lang::user::package_level_locale_not_cached {
    user_id
    package_id
} {
    Get the user's preferred package level locale for a package
    given by its package id. Will return the empty string if the
    user has not preference for the package.
} {
    return [db_string get_user_locale {} -default ""]
}
    
ad_proc -public lang::user::package_level_locale {
    {-user_id ""}
    package_id
} {
    Get the user's preferred package level locale for a package
    given by its package id.
} {
    # default to current user
    if { [empty_string_p $user_id] } {
        set user_id [ad_conn untrusted_user_id]
    }

    # If package-level locales are turned off, or the user isn't logged in, return the empty string
    if { ![lang::system::use_package_level_locales_p] || $user_id == 0 } {
        return {}
    }

    # Cache for the lifetime of sessions (7 days)
    return [util_memoize [list lang::user::package_level_locale_not_cached $user_id $package_id] [sec_session_timeout]]
}

ad_proc -public lang::user::site_wide_locale {
    {-user_id ""}
} {
    Get the user's preferred site wide locale.
} {
    # default to current user
    if { [empty_string_p $user_id] } {
        set user_id [ad_conn untrusted_user_id]
    }

    # For all the users with a user_id of 0 don't cache.
    # MS: WHY ON EARTH ?
    #    if { $user_id == 0} {
    #	return [lang::user::site_wide_locale_not_cached $user_id]
    #    }

    # Cache for the lifetime of sessions (7 days)
    return [util_memoize [list lang::user::site_wide_locale_not_cached $user_id] [sec_session_timeout]]
}

ad_proc -private lang::user::site_wide_locale_not_cached {
    user_id
} {
    Get the user's preferred site wide locale.
} {
    set system_locale [lang::system::site_wide_locale]
    if { $user_id == 0 } {
	set locale [ad_get_cookie "ad_locale"]
	if { [empty_string_p $locale] } {
	    set locale $system_locale
	}
	return $locale
    } else {
	# MS: This is a bug, as the returned value is different whether
	# you give it a user_id or not. WHY EVER this was done.
	
        return [db_string get_user_site_wide_locale {} -default "$system_locale"]
    }
}

ad_proc -public lang::user::locale {
    {-package_id ""}
    {-site_wide:boolean}
    {-user_id ""}
} {
    Get user locale preference for a given package instance.
    
    @param package_id The package for which you want to get the locale preference.
    @param site_wide Set this if you want to get the site-wide locale preference.
    @param user_id Set this to the user you want to get the locale of, defaults to current user.
} {
    # default to current user
    if { [empty_string_p $user_id] } {
        set user_id [ad_conn untrusted_user_id]
    }

    # default to current connection package
    if { [empty_string_p $package_id] } {
        set package_id [ad_conn package_id]
    }

    # Try package level locale first
    set locale [package_level_locale -user_id $user_id $package_id]

    # If there's no package setting, then use the site-wide setting
    if { [empty_string_p $locale] } {
        set locale [site_wide_locale -user_id $user_id]
    } 

    return $locale
}

ad_proc -public lang::user::set_locale {
    {-package_id ""}
    {-user_id ""}
    locale
} {
    Set user locale setting for a given package instance.
    
    @param package_id The package for which you want to set the locale setting, if you want to set it for a specific package, as opposed to a site-wide setting.
    @param locale The new locale that you want to use as your system locale.
} {
    if { [empty_string_p $user_id] } {
	set user_id [ad_conn user_id]
    }

    if { $user_id == 0 } {
        # Not logged in, use a cookie-based client locale
	ad_set_cookie -replace t -max_age inf "ad_locale" $locale

        # Flush the site-wide user preference cache
        util_memoize_flush [list lang::user::site_wide_locale_not_cached $user_id]
        return
    }

    if { [empty_string_p $package_id] } {
        # Set site-wide locale in user_preferences table
        db_dml set_user_site_wide_locale {}

        # Flush the site-wide user preference cache
        util_memoize_flush [list lang::user::site_wide_locale_not_cached $user_id]
        return
    } 

    # The rest is for package level locale settings only
    # Even if package level locales are disabled, we'll still do this

    set user_locale_exists_p [db_string user_locale_exists_p {}]
    if { $user_locale_exists_p } {
        if { ![empty_string_p $locale] } {
            db_dml update_user_locale {}
        } else {
            db_dml delete_user_locale {}
        }
    } else {
        if { ![empty_string_p $locale] } {
            db_dml insert_user_locale {}
        }
    }

    # Flush the user locale preference cache
    util_memoize_flush [list lang::user::package_level_locale_not_cached $user_id $package_id]
}

ad_proc -public lang::user::language {
    {-package_id ""}
    {-site_wide:boolean}
} {
    Get user language preference for a given package instance.
    This preliminary implementation only has one site-wide setting, though.
    
    @param package_id The package for which you want to get the language setting.
    @param site_wide Set this if you want to get the site-wide language setting.
} {
    return [string range [locale -package_id $package_id -site_wide=$site_wide_p] 0 1]
}


ad_proc -private lang::user::timezone_no_cache {user_id} {
    return [db_string select_user_timezone {} -default ""]
}
    
ad_proc -public lang::user::timezone {} {
    Get the user's timezone. Returns the empty string if the user
    has no timezone set.
    
    @return  a timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
} {
    set user_id [ad_conn user_id]
    if { ![lang::system::timezone_support_p] || $user_id == 0 } {
        return ""
    }

    return [util_memoize [list lang::user::timezone_no_cache $user_id]]
}
    
ad_proc -public lang::user::set_timezone { 
    timezone
}  { 
    Set the user's timezone setting.
    
    @param timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
} {
    if { ![lang::system::timezone_support_p] } {
        return ""
    }

    set user_id [ad_conn user_id]

    if { $user_id == 0 } {
        error "User not logged in"
    } else {
        db_dml set_user_timezone {}
        util_memoize_flush [list lang::user::timezone_no_cache $user_id]
    }
}





#####
#
# lang::conn
#
#####

ad_proc -public lang::conn::locale {
    {-package_id ""}
    {-site_wide:boolean}
} {
    Get the locale for this request, perhaps for a given package instance.
    This procedure will never return an error. Everything that could fail is 
    wrapped in a catch.
    
    @param package_id The package for which you want to get the locale.
    @param site_wide Set this if you want to get the site-wide locale.
} {
    if { $site_wide_p } { 
        set locale [lang::user::site_wide_locale]
        if { [empty_string_p $locale] } {
            set locale [lang::system::site_wide_locale]
        }
        return $locale
    }

    # default value for package_id

    if { [empty_string_p $package_id] } {
        set package_id [ad_conn package_id]
    }

    # use user's package level locale

    set locale [lang::user::package_level_locale $package_id]

    # if that does not exist use system's package level locale

    if { [empty_string_p $locale] } {
        set locale [lang::system::package_level_locale $package_id]
    } 

    # if that does not exist use user's site wide locale

    if { [empty_string_p $locale] } {
        set locale [lang::user::site_wide_locale]
    } 

    # Use the accept-language browser heading

    if { [empty_string_p $locale] } {
        set locale [lang::conn::browser_locale]
    }    

    # if that does not exist use system's site wide locale

    if { [empty_string_p $locale] } {
        set locale [lang::system::site_wide_locale]
    } 

    # if that does not exist then we are back to just another language
    # let's pick uhmm... en_US

    if { [empty_string_p $locale] } {
        set locale en_US
    } 

    return $locale
}

ad_proc -private lang::conn::browser_locale {} {
    Get the users preferred locale from the accept-language
    HTTP header.

    @return A locale or an empty string if no locale can be found that
            is supported by the system

    @author Lars Pind
    @author Peter Marklund
} {
    set conn_locales [lang::conn::get_accept_language_header]

    set system_locales [lang::system::get_locales]

    foreach locale $conn_locales {       
        regexp {^([^_]+)(?:_([^_]+))?$} $locale locale language region 

        if { [exists_and_not_null region] } {
            # We have both language and region, e.g. en_US
            if { [lsearch -exact $system_locales $locale] != -1 } {
                # The locale was found in the system, a perfect match           
                set perfect_match $locale
                break
            } else {
                # We don't have the full locale in the system but check if
                # we have a different locale with matching language, 
                # i.e. a tentative match
                if { ![info exists tentative_match] } {
                    set default_locale [lang::util::default_locale_from_lang $language]
                    if { ![empty_string_p $default_locale] } {
                        set tentative_match $default_locale
                    }                    
                } else {
                    # We already have a tentative match with higher priority so
                    # continue searching for a perfect match
                    continue
                }
            }
        } else {
            # We have just a language, e.g. en
            set default_locale [lang::util::default_locale_from_lang $locale]
            if { ![empty_string_p $default_locale] } {
                set perfect_match $default_locale
                break
            }
        }
    }

    if { [exists_and_not_null perfect_match] } {
        return $perfect_match
    } elseif { [exists_and_not_null tentative_match] } {
        return $tentative_match
    } else {
        # We didn't find a match
        return ""
    }
}

ad_proc -private lang::conn::get_accept_language_header {} {

    set acclang [ns_set iget [ns_conn headers] "Accept-Language"]

    # Split by comma, and get rid of any ;q=0.5 parts
    # acclang is something like 'da,en-us;q=0.8,es-ni;q=0.5,de;q=0.3'
    set acclangv [list]
    foreach elm [split $acclang ","] {
        # Get rid of trailing ;q=0.5 part
        set elm [lindex [split $elm ";"] 0]

        # elm is now either like 'da' or 'en-us'
        # make it into something like 'da' or 'en_US'
        set elmv [split $elm "-"]
        set elm [lindex $elmv 0]
        if { [llength $elmv] > 1 } {
            append elm "_[string toupper [lindex $elmv 1]]"
        }

        lappend acclangv $elm
    }
    
    return $acclangv
}

ad_proc -public lang::conn::language {
    {-package_id ""}
    {-site_wide:boolean}
} {
    Get the language for this request, perhaps for a given package instance.
    
    @param package_id The package for which you want to get the language.
    @param site_wide Set this if you want to get the site-wide language.
} {
    return [string range [locale -package_id $package_id -site_wide=$site_wide_p] 0 1]
}

ad_proc -public lang::conn::charset { 
} {
    Returns the MIME charset name corresponding to the current connection's locale.

    @author        Lars Pind (lars@pinds.com)
    @param locale  Name of a locale, as language_COUNTRY using ISO 639 and ISO 3166
    @return        IANA MIME character set name
} {
    return [lang::util::charset_for_locale [lang::conn::locale]]
}

ad_proc -public lang::conn::timezone {} {
    Get this connection's timezone. This is the user timezone, if
    set, otherwise the system timezone.
    
    @return  a timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
} {
    if { ![lang::system::timezone_support_p] } {
        return ""
    }

    set timezone {}
    if { [ad_conn isconnected] } {
        set timezone [lang::user::timezone]
    }

    if { [empty_string_p $timezone] } {
        # No user timezone, return the system timezone
        set timezone [lang::system::timezone]
    }
    return $timezone
}


#####
#
# Backwards compatibility procs
#
#####
ad_proc -deprecated -warn -public ad_locale_get_label { locale } {

    Returns the label (name) of locale

    To be removed in 5.3

    @author	Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)

    @param locale	Code for the locale, eg "en_US"

    @return	String containing the label for the locale

    @see lang::util::get_label
} {
    return [db_string select_locale_label {
        select label 
          from ad_locales
         where lower(locale) = lower(:locale)
    }]
}
