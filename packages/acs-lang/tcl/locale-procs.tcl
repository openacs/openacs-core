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

namespace eval lang::system {

    ad_proc -public locale {
        {-package_id ""}
        {-site_wide:boolean}
    } {
        Get system locale setting for a given package instance.
        
        @param package_id The package for which you want to get the locale setting.
        @param site_wide Set this if you want to get the site-wide locale setting.
    } {
        if { $site_wide_p } {
            set package_id [apm_package_id_from_key "acs-lang"]
            return [parameter::get -package_id $package_id -parameter SiteWideLocale]
        } 

        if { [empty_string_p $package_id] } {
            set package_id [ad_conn package_id]
        }

        # Pssst! We don't actually use this package thing, 
        # but we'll probably do so later.
        set locale {}

        # If there's no package setting, use the site-wide setting
        if { [empty_string_p $locale] } {
            set locale [locale -site_wide]
        } 
        return $locale
    }

    ad_proc -public set_locale {
        {-package_id ""}
        {-site_wide:boolean}
        locale
    } {
        Set system locale setting for a given package instance, or the
        site-wide system locale.
        
        @param package_id The package for which you want to set the locale setting.
        @param site_wide Set this if you want to set the site-wide locale setting.
        @param locale The new locale that you want to use as your system locale.
    } {
        if { $site_wide_p } {
            set package_id [apm_package_id_from_key "acs-lang"]
            parameter::set_value -package_id $package_id -parameter SiteWideLocale -value $locale
        } else {
            if { [empty_string_p $package_id] } {
                set package_id [ad_conn package_id]
            }
            # Pssst! We don't actually use this package thing, 
            # but we'll probably do so later.
            set_locale -site_wide $locale
        }
    }

    ad_proc -public language {
        {-package_id ""}
        {-site_wide:boolean}
    } {
        Get system language setting for a given package instance.
        
        @param package_id The package for which you want to get the language setting.
        @param site_wide Set this if you want to get the site-wide language setting.
    } {
        return [string range [locale -package_id $package_id -site_wide=$site_wide_p] 0 1]
    }

    ad_proc -public timezone {} {
        Ask OpenACS what it thinks our timezone is.
        
        @return  a timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
    } {
        set package_id [apm_package_id_from_key "acs-lang"]
        return [parameter::get -package_id $package_id -parameter SystemTimezone -default 0]
    }
        
    ad_proc -public set_timezone { 
        timezone
    }  { 
        Tell OpenACS what timezone we think it's running in.
        
        @param timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
    } {
        set package_id [apm_package_id_from_key "acs-lang"]
        parameter::set_value -package_id $package_id -parameter SystemTimezone -value $timezone
    }

    ad_proc -public timezone_utc_offset { } {
        @return number of hours to subtract from local (database) time to get UTC
    } {
        set system_timezone [timezone]
        return [db_string system_utc_offset {}]
    }

}

namespace eval lang::user {

    ad_proc -public locale {
        {-package_id ""}
        {-site_wide:boolean}
    } {
        Get user locale preference for a given package instance.
        This preliminary implementation only has one site-wide setting, though.
        
        @param package_id The package for which you want to get the locale preference.
        @param site_wide Set this if you want to get the site-wide locale preference.
    } {
        set user_id [ad_conn user_id]
        if { $user_id == 0 } {
            # Not logged in, use a session-based client property
            return [ad_get_client_property -cache t "acs-lang" "user_locale"]
        }
    
        # Pssst! We don't actually use this package thing, 
        # but we'll probably do so later.
        if { $site_wide_p } {

            set package_id [apm_package_id_from_key "acs-lang"]
            return [db_string get_user_locale {} -default ""]

        } elseif { [empty_string_p $package_id] } {
            set package_id [ad_conn package_id]
        }
        set locale [db_string get_user_locale {} -default ""]

        # If there's no package setting, use the site-wide setting
        if { [empty_string_p $locale] } {
            set locale [locale -site_wide]
        } 
        return $locale
    }

    ad_proc -public set_locale {
        {-package_id ""}
        {-site_wide:boolean}
        locale
    } {
        Set system locale setting for a given package instance. 
        This preliminary implementation only has one site-wide setting, though.
        
        @param package_id The package for which you want to set the locale setting.
        @param site_wide Set this if you want to set the site-wide locale setting.
        @param locale The new locale that you want to use as your system locale.
    } {
        set user_id [ad_conn user_id]
        if { $user_id == 0 } {
            # Not logged in, use a session-based client property
            ad_set_client_property -persistent t "acs-lang" "user_locale" $locale
            return
        }
    
        # Pssst! We don't actually use this package thing, 
        # but we'll probably do so later.
        if { $site_wide_p } {
            set package_id [apm_package_id_from_key "acs-lang"]
        } elseif { [empty_string_p $package_id] } {
            set package_id [ad_conn package_id]
        }

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
    }

    ad_proc -public language {
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

    ad_proc -public timezone {} {
        Get the user's timezone. Defaults to system timezone if the user has no setting.
        
        @return  a timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
    } {
        # We probably don't want to keep this in client properties, since these are
        # no longer permanent. We'll move this into a DB table at some point.
        set timezone [ad_get_client_property -cache t "acs-lang" "timezone"]
        if { [empty_string_p $timezone] } {
            # No user timezone, return the system timezone
            set timezone [parameter::get -parameter DefaultTimezone -package_id [apm_package_id_from_key acs-lang] -default "PST"]
        }
        return $timezone
    }
        
    ad_proc -public set_timezone { 
        timezone
    }  { 
        Set the user's timezone setting.
        
        @param timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
    } {
        ad_set_client_property -persistent t "acs-lang" timezone $timezone
    }

}

namespace eval lang::conn {

    ad_proc -public locale {
        {-package_id ""}
        {-site_wide:boolean}
    } {
        Get the locale for this request, perhaps for a given package instance.
        This procedure will never return an error. Everything that could fail is 
        wrapped in a catch.
        
        @param package_id The package for which you want to get the locale.
        @param site_wide Set this if you want to get the site-wide locale.
    } {
        set locale {}
        catch {
            set locale [lang::user::locale -package_id $package_id -site_wide=$site_wide_p]
        }
        if { [empty_string_p $locale] } {
            catch {
                set locale [lang::system::locale -package_id $package_id -site_wide=$site_wide_p]
            }
        }
	
	# Check browser Accept-Language header
	# Hm. Site-wide will always be set. Hm.
	# Check Yon's ACS Java g15n doc
	
        return $locale
    }

    ad_proc -public language {
        {-package_id ""}
        {-site_wide:boolean}
    } {
        Get the language for this request, perhaps for a given package instance.
        
        @param package_id The package for which you want to get the language.
        @param site_wide Set this if you want to get the site-wide language.
    } {
        return [string range [locale -package_id $package_id -site_wide=$site_wide_p] 0 1]
    }
    
}


#####
#
# Backwards compatibility procs
#
#####

ad_proc -deprecated -warn ad_locale {
    context 
    item
} {
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

    @see lang::conn::locale
    @see lang::user::locale
    @see lang::user::language
    @see lang::user::timezone
    @see lang::util::charset_for_locale
} {
    switch $context {
        request {
            return [lang::conn::locale -site_wide]
        }
	user {
	    switch $item {
		locale {
		    return [lang::user::locale -site_wide]
		}
		language {
		    return [lang::user::language -site_wide]
		}
		timezone {
		    return [lang::user::timezone]
		}
		default {
		    error "unsupported option to ad_locale: $item"
		}
	    }
	}
	charset {
	    return [lang::util::charset_for_locale $item]
	}
	default {
	    error "ad_locale: unknown context $context"
	}
    }
}

ad_proc -deprecated -warn ad_locale_set  { 
    item 
    value 
} {
    Sets the user's preferred locale info as a session var
    <p>
    usage:
    <pre>
    ad_locale_set locale "en_US"
    ad_locale_set timezone "PST"
    </pre>
    @see lang::user::set_locale
    @see lang::user::set_timezone
} {
    switch $item {
        locale {
            lang::user::set_locale -site_wide $value
        }
        timezone {
            lang::user::set_timezone $value
        }
        default {
            error "Unknown item, $item"
        }
    }
}

ad_proc -deprecated -warn ad_locale_set_system_timezone { 
    timezone
}  { 
    Tell OpenACS what timezone we think it's running in.
    
    @param timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
    @see lang::system::set_timezone
} {
    lang::system::set_timezone $timezone
}


ad_proc -deprecated -warn ad_locale_get_system_timezone { }  { 
    Ask OpenACS what it thinks our timezone is.

    @return  a timezone name from acs-reference package (e.g., Asia/Tokyo, America/New_York)
    @see lang::system::timezone
} {
    return [lang::system::timezone]
}


ad_proc -deprecated -warn ad_locale_system_tz_offset { } {
    @return number of hours to subtract from local (Oracle) time to get UTC
    @see lang::system::timezone_utc_offset
} {
    return [lang::system::timezone_utc_offset]
}

ad_proc -deprecated -public ad_locale_get_label { locale } {

    Returns the label (name) of locale

    @author	Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)

    @param locale	Code for the locale, eg "en_US"

    @return	String containing the label for the locale

} {
    return [db_string select_locale_label {
        select label 
          from ad_locales
         where locale = :locale
    }]
}
