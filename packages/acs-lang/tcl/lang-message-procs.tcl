#/packages/acs-lang/tcl/lang-message-procs.tcl
ad_library {

    Routines for displaying web pages in multiple languages
    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    @creation-date 10 September 2000
    @author Jeff Davis (davis@arsdigita.com)
    @author Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
    @author Peter Marklund (peter@collaboraid.biz)
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval lang::message {

    ad_proc -public register { 
        locale
        package_key
        message_key
        message
    } { 
        Registers a message in a given locale or language.
        Inserts the message key into the database if it
        doesn't already exists. Inserts the message itself
        in the given locale into the database if it doesn't
        exist and updates it if it does.
    
        @author Jeff Davis (davis@arsdigita.com)
        @author Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
        @author Christian Hvid

        @see _mr
        
        @param locale        Locale or language of the message. If a language is supplied,
                             the default locale for the language is looked up. 

        @param package_key   The package key of the package that the message belongs to.
        @param message_key   The key that identifies the message within the package.
        @param message       The message text
    } { 
        # Create a globally unique key for the cache
        set key "${package_key}.${message_key}"

        # Insert the message key into the database if it doesn't
        # already exist
        set key_exists_p [db_string message_key_exists_p {}]

        if { ! $key_exists_p } {
            db_dml insert_message_key {}
        }

        # First we check if the given key already exists
        # or if this is different than what we have saved.
        
        # Check if the $lang parameter is a language or a locale
        if { [string length $locale] == 2 } {
            # It seems to be a language (iso codes are 2 characters)
            # We don't do a more throughout check since this is not
            # invoked by users.
            # let's get the default locale for that language
            set locale [util_memoize [list ad_locale_locale_from_lang $locale]]
        } 
    
        # Check the cache
        if { [nsv_exists lang_message_$locale $key] } { 

            set old_message [nsv_get lang_message_$locale $key]

            if { ![string equal $message $old_message] } {

                # changed message ... update.

                # Trying to avoid hitting Oracle bug#2011927
    
                if { [empty_string_p [string trim $message]] } {
                    db_dml lang_message_null_update {}
                } else { 
                    db_dml lang_message_update {} -clobs [list $message]
                }
                nsv_set lang_message_$locale $key $message
            }
        } else { 
            ns_log Notice "lang::message::register - Inserting into database message: $locale $key" 
            db_transaction {
                # As above, avoiding the bug#2011927 from Oracle.
    
                if { [empty_string_p [string trim $message]] } {
                    db_dml lang_message_insert_null_msg {}
                } else {
                    # LARS:
                    # We may need to have two different lines here, one for
                    # Oracle w/clobs, one for PG w/o clobs.
                    db_dml lang_message_insert {} -clobs [list $message]
                }
                nsv_set lang_message_$locale $key $message
            }
        }
    }

    ad_proc -private format {
        localized_message
        {value_array_list {}}
        {upvar_level 3}
    } {
        Substitute all occurencies of %array_key%
        in the given localized message with the value from a lookup in the value_array_list
        with array_key (what's between the percentage sings). If value_array_list is not
        provided then attempt to fetch variable values the number of levels up given by
        upvar_level (defaults to 3 because this proc is typically invoked from the underscore
        lookup proc). 

        Here is an example:

        set localized_message "The %frog% jumped across the %fence%. About 50% of the time, he stumbled, or maybe it was %%20 %times%."
        set value_list {frog frog fence fence}

        puts "[format $localized_message $value_list]"
        
        The output from the example is:

        The frog jumped across the fence. About 50% of the time, he stumbled, or maybe it was %20 %times%.
    } {        

        array set value_array $value_array_list
        set value_array_keys [array names value_array]
        set remaining_message $localized_message
        set formated_message ""
        while { [regexp {^(.*?)(%%|%[a-zA-Z_]+%)(.*)$} $remaining_message match before_percent percent_match remaining_message] } {
    
            append formated_message $before_percent
    
            if { [string equal $percent_match "%%"] } {
                # A quoted percent sign
                append formated_message "%"
            } else {
                set variable_key [string range $percent_match 1 end-1]

                if { [llength $value_array_list] > 0 } {
                    # A substitution list is provided, the key should be in there
                    
                    if { [lsearch -exact $value_array_keys $variable_key] == -1 } {
                        ns_log Warning "lang::message::format: The value_array_list \"$value_array_list\" does not contain the variable name $variable_key found in the message: $localized_message"
                    
                        # There is no value available to do the substitution with
                        # so don't substitute at all
                        append formated_message $percent_match
                    } else {
                        # Do the substitution
                    
                        append formated_message [lindex [array get value_array $variable_key] 1]
                    }
                } else {
                    # No substitution list provided - attempt to fetch variable value
                    # from scope calling lang::message::lookup
                    upvar $upvar_level $variable_key variable_value

                    append formated_message $variable_value
                }
            }
        }

        # Append text after the last match
        append formated_message $remaining_message
    
        return $formated_message
    }
    
    ad_proc -public lookup {
        locale
        key
        {default "TRANSLATION MISSING"}
        {substitution_list {}}
        {upvar_level 2}
    } {
        This proc is normally accessed through the _ procedure.
    
        Returns a translated string for the given locale and message key.
        If the user is a translator, inserts tags to link to the translator
        interface. This allows a translator to work from the context of a web page.

        @param locale             Locale (e.g., "en_US") or language (e.g., "en") string.
                                  If locale is the empty string ad_conn locale will be used
                                  if we are in an HTTP connection, otherwise the system locale
                                  (SiteWideLocale) will be used.
        @param key                Unique identifier for this message. Will be the same 
                                  identifier for each locale. All keys belong to a certain 
                                  package and should be prefixed with the package key of that package 
                                  on the format package_key.message_key (the dot is reserved for separating 
                                  the package key, the rest of the key should contain only alpha-numeric
                                  characters and underscores). If the key does not belong to 
                                  any particular package it should not contain a dot. A lookup
                                  is always attempted with the exact key given to this proc.
        @param default            Text to return if there is no message in the message catalog for
                                  the given locale. This argument is optional. If this argument is
                                  not provided or is the empty string then the text returned will
                                  be TRANSLATION MISSING - $key.
        @param substitution_list  A list of values to substitute into the message. This argument should
                                  only be given for certain messages that contain place holders (on the syntax
                                  %var_name%) for embedding variable values, see lang::message::format.
                                  If this list is not provided and the message has embedded variables,
                                  then the variable values can be fetched with upvar from the scope
                                  calling this proc (see upvar_level).

        @param upvar_level        If there are embedded variables and no substitution list provided, this
                                  parameter specifies how many levels up to fetch the values of the variables
                                  in the message. The reason the default is 2 is that the lookup proc is
                                  usually invoked by the underscore proc (_). Set upvar level to less than
                                  1 if you don't want variable interpolation to be done.
    
        @author Jeff Davis (davis@arsdigita.com), Henry Minsky (hqm@arsdigita.com)
        @author Peter Marklund (peter@collaboraid.biz)
        @see _
        
        @return A localized piece of text.
    } { 
        # If the cache hasn't been loaded - do so now
        # Peter: should we go to the database on first hit and cache the messages as they are used
        # instead of loading the whole cache up-front?
        global message_cache_loaded_p
        if { ![info exists message_cache_loaded_p] } {
            lang::message::cache
        }
        
        if { [empty_string_p $locale] } {
            # No locale provided

            global ad_conn
            if { [info exists ad_conn] } {
                # We are in an HTTP connection (request) so use that locale
                set locale [ad_conn locale]
            } else {
                # There is no HTTP connection - resort to system locale
                set system_locale [parameter::get -package_id [apm_package_id_from_key acs-lang] -parameter SiteWideLocale]
                set locale $system_locale
            }
        } elseif { [string length $locale] == 2 } {
            # Only language provided

            # let's get the default locale for this language
            # The cache is flushed if the default locale for this language is
            # changed.
            set locale [util_memoize [list ad_locale_locale_from_lang $locale]]    
        } 
    
        if { [nsv_exists lang_message_$locale $key] } {
            # Message exists in the given locale

            set return_value [nsv_get lang_message_$locale $key]
            # Do any variable substitutions (interpolation of variables)
            if { [llength $substitution_list] > 0 || ($upvar_level >= 1 && [string first "%" $return_value] != -1) } {
                set return_value [lang::message::format $return_value $substitution_list [expr $upvar_level + 1]]
            }

        } else {
            # There is no entry in the message catalog for the given locale

            if { [nsv_exists lang_message_en_US $key] != 0 } {
                # The key exists but there is no translation in the current locale

                if { ![lang::util::translator_mode_p] } {
                    # We are not in translator mode

                    if { [string equal $default "TRANSLATION MISSING"] } {
                        set return_value "$default: $key"
                    } else {
                        set return_value $default
                    }
                } else {
                    # Translator mode - return a translation link

                    set key_split [split $key "."]
                    set package_key_part [lindex $key_split 0]
                    set message_key_part [lindex $key_split 1]
                    
                    set return_url [ad_conn url]
                    if { [ns_getform] != "" } {
                        append return_url "?[export_entire_form_as_url_vars]"
                    }
                    
                    set return_value "&nbsp;<a href=\"/acs-lang/admin/edit-localized-message?[export_vars { { message_key $message_key_part } { locales $locale } { package_key $package_key_part } return_url }]\"><span style=\"background-color: yellow\"><font size=\"-2\">$message_key_part - TRANSLATE</font></span></a>&nbsp;"
                }

            } {
                # The key doesn't exist - this is a programming error

                set return_value "NO KEY: $key"
                ns_log Error "lang::message::lookup key doesn't exist: $key"
            }
        }

        return $return_value
    }

    ad_proc -private translate { 
        msg
        locale
    } {
        Translates an English string into a different language
        using Babelfish.

        Warning - october 2002: This is broken.
        
        @author            Henry Minsky (hqm@mit.edu)
        
        @param msg         String to translate
        @param lang        Abbreviation for lang in which to translate string
        @return            Translated string
    } {
        set lang [string range $locale 0 2]
        set marker "XXYYZZXX. "
        set qmsg "$marker $msg"
        set url "http://babel.altavista.com/translate.dyn?doit=done&BabelFishFrontPage=yes&bblType=urltext&url="
        set babel_result [ns_httpget "$url&lp=$lang&urltext=[ns_urlencode $qmsg]"]
        set result_pattern "$marker (\[^<\]*)"
        if [regexp -nocase $result_pattern $babel_result ignore msg_tr] {
            regsub "$marker." $msg_tr "" msg_tr
            return [string trim $msg_tr]
        } else {
            error "Babelfish translation error"
        }
    }     


    ad_proc -private cache {} {
        Loads the entire message catalog from the database into the cache.
    } {
        # We segregate messages by language. It might reduce contention
        # if we segregage instead by package. Check for problems with ns_info locks.
        global message_cache_loaded_p
        set message_cache_loaded_p 1
        
        set i 0 
        db_foreach select_locale_keys {} {
            nsv_set lang_message_$locale "${package_key}.${message_key}" $message
            incr i
        }
        
        db_release_unused_handles
        
        ns_log Notice "lang::message::cache - Initialized message cache with $i rows from database"
    }

}

#####
#
# Shorthand notation procs _ and _mr
#
#####

ad_proc -public _mr { locale key message } {

    Registers a message in a given locale or language.
    Inserts the message into the table lang_messages
    if it does not exist and updates if it does.

    For backward compability - it assumes that the key 
    is the concatenation of message and package key
    like this:

    package_key.message_key

    @author Jeff Davis (davis@arsdigita.com)
    
    @param locale  Abbreviation for language of the message or the locale.
    @param key     Unique identifier for this message. Will be the same identifier
                   for each language
    @param message Text of the message

    @see lang::message::register
} {
    regexp {^([^\.]+)\.([^\.]+)$} $key match package_key message_key
    return [lang::message::register $locale $package_key $message_key $message]
}

ad_proc -public _ {
    args
} {
    Short hand proc with flexible argument handling that invokes the lang::util::lookup proc. 
    Returns a localized text from the 
    message catalog for a certain locale.
    This proc takes the following arguments in the given order (for further
    details see the lang::util::lookup proc):

    <pre>
    locale            Locale to use for the message lookup. This argument is optional
                      and if it's not provided ad_conn locale will be used.

    key               Unique identifier for this message. Will be the same identifier
                      for each locale.

    default_text      Text to return if there is no message in the message catalog for
                      the given locale. This argument is optional. 

    substitution_list A list of values to substitute into the message. This argument should
                      only be given for certain messages that contain place holders (on the syntax
                      %1:pretty_name%, %2:another_pretty_name% etc) for embedding variable values. If you provide this 
                      argument you must also all provide the other arguments (locale, key, and default_text).
    </pre>

    @return                  A localized piece of text.
    
    @author Jeff Davis (davis@arsdigita.com)
    @author Peter Marklund (peter@collaboraid.biz)
    @author Christian Hvid (chvid@collaboraid.biz)

    @see lang::message::lookup
} {
    switch [llength $args] {
        1 { return [lang::message::lookup ""               [lindex $args 0] "TRANSLATION MISSING"] }
        2 { return [lang::message::lookup [lindex $args 0] [lindex $args 1] "TRANSLATION MISSING"] }
        3 { return [lang::message::lookup [lindex $args 0] [lindex $args 1] [lindex $args 2]] }
        4 { return [lang::message::lookup [lindex $args 0] [lindex $args 1] [lindex $args 2] [lindex $args 3]] }
    }
}

#####
#
# Backwards compatibility procs
#
#####

ad_proc -private -deprecated -warn lang_message_register { locale key message } { 

    Normally accessed through the _mr procedure.
    Registers a message in a given locale or language.
    Inserts the message into the table lang_messages
    if it does not exist and updates if it does.

    @author Jeff Davis (davis@arsdigita.com)
    @author Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
    @see _mr
    
    @param locale  Locale or language of the message. If a language is supplied,
                   the default locale for the language is looked up. 
                   Taken from ad_locales table.
    @param key     Unique identifier for this message. Will be the same identifier
                   for each language
    @param message Text of the message
    
    @see lang::message::register
} { 
    return [lang::message::register $locale $key $message]
}

ad_proc -private -deprecated -warn lang_message_lookup {
    locale
    key
    {default "TRANSLATION MISSING"}
} {    
    @see lang::message::lookup
} { 
    return [lang::message::lookup $locale $key $default]
}

ad_proc -deprecated -warn lang_babel_translate { 
    msg
    lang
} {
    Translates an English string into a different language
    using Babelfish.

    @author            Henry Minsky (hqm@mit.edu)

    @param msg         String to translate
    @param lang        Abbreviation for lang in which to translate string
    @return            Translated string

    @see lang::message::translate
} {
    return [lang::message::translate $msg $lang]
}     
