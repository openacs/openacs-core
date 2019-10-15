ad_include_contract {
    Change user preferred locale

    @author Peter Marklund (peter@collaboraid.biz)
    @author Christian Hvid
    @author Guenter Ernst (guenter.ernst@wu.ac.at)
} {
    {return_url:localurl "[get_referrer -relative]"}
    {package_id:naturalnum "[ad_conn package_id]"}
}

# check for package level locale support
set package_level_locales_p [expr {[lang::system::use_package_level_locales_p] && $package_id ne "" && [ad_conn user_id] != 0}]
# check for timezone setting support
set use_timezone_p [expr {[lang::system::timezone_support_p] && [ad_conn user_id]}]

# Create a list of lists containing the possible locale choiches
set list_of_locales [list]

db_foreach locale_loop {
   select label, locale from enabled_locales
} {
   if { [lang::message::message_exists_p $locale acs-lang.this-language] } {
       set label "[lang::message::lookup $locale  acs-lang.this-language]"
   }
   lappend list_of_locales [list ${label} $locale]
}

set list_of_locales [lsort -dictionary -index 0 $list_of_locales]
set list_of_package_locales [linsert $list_of_locales 0 [list (default) ""]]

# setup form
ad_form \
    -name locale \
    -mode edit \
    -form {
        {package_id:naturalnum(hidden)
            {value $package_id}
        }
        {return_url:text(hidden)
            {value $return_url}
        }
        {site_wide_locale:oneof(select),multiple,optional
            {label "[_ acs-lang.Your_Preferred_Locale]"}
            {options $list_of_locales}
            {values "[ad_conn locale]"}
            {help_text "[_ acs-lang.Your_locale_site_wide]"}
        }
    }


# add form element for package level locale selection (if needed)
if { $package_level_locales_p } {
    set package_name [apm_instance_name_from_id $package_id]
    ad_form \
        -extend \
        -name locale \
        -form {
            {package_level_locale:oneof(select),optional
                {label "[_ acs-lang.Locale_for]"}
                {options $list_of_package_locales}
                {help_text "[_ acs-lang.Your_locale_for_package]"}
            }
        }
}

# add form element for timezone selection (if needed)
if { $use_timezone_p } {
   set timezone_options [db_list_of_lists dbqd...all_timezones {
      select tz || ' ' || gmt_offset as tz, tz from timezones
   }]

   ad_form \
       -extend \
       -name locale \
       -form {
           {timezone:oneof(select),optional
               {label "[_ acs-lang.Your_timezone]"}
               {options $timezone_options}
           }
       }
}

# Setup of form elements done, now add the action blocks
ad_form \
   -extend \
   -name locale \
   -on_request {
       if { $package_level_locales_p } {
          set package_level_locale [lang::user::package_level_locale $package_id]
       }

       set site_wide_locale [lang::user::site_wide_locale]
       if { $site_wide_locale eq "" } {
          set site_wide_locale [lang::system::site_wide_locale]
       }

       if { $use_timezone_p } {
           set timezone [lang::user::timezone]
           if { $timezone eq "" } {
              set timezone [lang::system::timezone]
           }
       }
   } \
   -on_submit {
       lang::user::set_locale $site_wide_locale

       if { $package_level_locales_p } {
           lang::user::set_locale -package_id $package_id $package_level_locale
       }

       if { $use_timezone_p } {
           lang::user::set_timezone $timezone
       }

       ad_returnredirect $return_url
       ad_script_abort
   }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
