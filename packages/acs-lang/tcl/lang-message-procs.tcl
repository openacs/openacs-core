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

namespace eval lang::message {}

ad_proc -public lang::message::register { 
    -upgrade:boolean
    {-comment ""}
    locale
    package_key
    message_key
    message
} { 
    <p>
    Registers a message for a given locale and package.
    Inserts the message key into the database if it
    doesn't already exists. Inserts the message itself
    in the given locale into the database if it doesn't
    exist and updates it if it does. Also updates the
    cache with the message.
    </p>

    <p>
    If we are registering a message as part of an upgrade, appropriate
    upgrade status for the message key (added) and the message (updated or
    added) will be set.
    </p>

    @author Jeff Davis
    @author Peter Marklund
    @author Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
    @author Christian Hvid

    @see _mr
    
    @param locale        Locale or language of the message. If a language is supplied,
                         the default locale for the language is looked up. 

    @param package_key   The package key of the package that the message belongs to.
    @param message_key   The key that identifies the message within the package.
    @param message       The message text
    @param upgrade       A boolean switch indicating if this message is registered
                         as part of a message catalog upgrade or not. The default
                         (switch not provided) is that we are not upgrading.

    @see lang::message::lookup
    @see _
} { 
    # Qualify the locale variable value with a country code if it is
    # just a language
    if { [string length $locale] == 2 } {
        # It seems to be a language (iso codes are 2 characters)
        # We don't do a more throughout check since this is not
        # invoked by users.
        # let's get the default locale for that language
        set locale [util_memoize [list ad_locale_locale_from_lang $locale]]
    } 

    # Create a globally unique key for the cache
    set key "${package_key}.${message_key}"

    # Insert the message key into the database if it doesn't
    # already exist
    set key_exists_p [db_string message_key_exists_p {}]

    if { ! $key_exists_p } {
        if { [string equal $locale "en_US"] } {
            set key_upgrade_status [ad_decode $upgrade_p 1 "added" "no_upgrade"]
            if { $upgrade_p } {
                ns_log Notice "lang::message::register - Giving message key $message_key an upgrade status of $key_upgrade_status"
            }
            db_dml insert_message_key {}
        } else {
            # Non-default locale
            # The system will not function correctly if there are keys registered in other locales
            # than en_US that are not present for en_US. This introduces the inconvenience of having to
            # register the en_US messages first, but that is manageable
            ns_log Error "lang::message::register - refusing to register message for non-en_US locale ${locale}. The message key ${package_key}.${message_key} bust be registered in en_US first"
            return -1
        }
    }

    # Check that non-en_US messages don't have invalid embedded variables
    if { ![string equal $locale "en_US"] } {
        set embedded_vars [get_embedded_vars $message]
        set embedded_vars_en_us [get_embedded_vars [lang::message::lookup en_US $key {} {} 0]]
        set missing_vars [util_get_subset_missing $embedded_vars $embedded_vars_en_us]

        if { [llength $missing_vars] > 0 } {
            error "Message key '$key' in locale '$locale' has these embedded variables not present in the en_US locale: [join $missing_vars ","]. Message has not been imported."
        }
    }

    # Different logic for update and insert
    if { [nsv_exists lang_message_$locale $key] } { 
        # Update existing message if the message has changed

        set old_message [nsv_get lang_message_$locale $key]

        lang::audit::changed_message $old_message $package_key $message_key $locale $comment

        set message_upgrade_status [ad_decode $upgrade_p 1 "updated" "no_upgrade"]
        if { $upgrade_p } {
            ns_log Notice "lang::message::register - Giving message for key $message_key in locale $locale an upgrade status of $message_upgrade_status"
        }

        # Trying to avoid hitting Oracle bug#2011927    
        if { [empty_string_p [string trim $message]] } {
            db_dml lang_message_null_update {}
        } else { 
            db_dml lang_message_update {} -clobs [list $message]
        }
        nsv_set lang_message_$locale $key $message

    } else { 
        # Insert new message

        db_transaction {
            set message_upgrade_status [ad_decode $upgrade_p 1 "added" "no_upgrade"]
            if { $upgrade_p } {
                ns_log Notice "lang::message::register - Giving message for key $message_key in locale $locale an upgrade status of $message_upgrade_status"
            }

            if { [catch {set creation_user [ad_conn user_id]}] } {
                set creation_user [db_null]
            }

             # avoiding bug#2011927 from Oracle.
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

ad_proc -public lang::message::unregister { 
    package_key
    message_key
} {
    Unregisters a message key, i.e. deletes it along with all its messages
    from the database and deleted entries in the cache.

    @author Peter Marklund
} {
    # Deletes messages as well
    db_dml delete_key {
        delete from lang_message_keys
        where message_key = :message_key
          and package_key = :package_key
    }

    # Delete from the cache for all enabled locales
    foreach locale [lang::system::get_locales] {
        set nsv_array lang_message_$locale
        set nsv_key "${package_key}.${message_key}"
        if { [nsv_exists $nsv_array $nsv_key] } {
            nsv_unset $nsv_array $nsv_key
        }
    }
}

ad_proc -private lang::message::get_embedded_vars {
    message
} {
    Returns a list of embedded substitution variables on the form %varname% in a message.
    This is useful if you want to check that the variables used in a translated message also 
    appear in the en_US message. If not, there's likely to be a typo.

    @param message  A message with embedded %varname% notation

    @return         The list of variables in the message

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 12 November 2002
} {
    set variables_list [list]
    set remaining_message $message
    while { [regexp [embedded_vars_regexp] $remaining_message \
            match before_percent percent_match remaining_message] } {

        if { [string equal $percent_match "%%"] } {
            # A quoted percentage sign - ignore
            continue
        } else {
            lappend variables_list [string range $percent_match 1 end-1]
        }
    }

    return $variables_list
}

ad_proc -private lang::message::format {
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

    set localized_message "The %animal% jumped across the %barrier%. About 50% of the time, he stumbled, or maybe it was %%20 %times%."
    set value_list { animal "frog" barrier "fence" }

    puts "[format $localized_message $value_list]"
    
    The output from the example is:

    The frog jumped across the fence. About 50% of the time, he stumbled, or maybe it was %20 %times%.
} {        
    array set value_array $value_array_list
    set value_array_keys [array names value_array]
    set remaining_message $localized_message
    set formated_message ""
    while { [regexp [embedded_vars_regexp] $remaining_message match before_percent percent_match remaining_message] } {

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

                if { [info exists variable_value] } {
                    append formated_message $variable_value
                } else {
                    error "Message contains a variable named '$variable_key' which doesn't exist in the caller's environment"
                }
            }
        }
    }

    # Append text after the last match
    append formated_message $remaining_message

    return $formated_message
}

ad_proc -private lang::message::embedded_vars_regexp {} {
    The regexp pattern used to loop over variables embedded in 
    message catalog texts.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 12 November 2002
} {
    return {^(.*?)(%%|%[-a-zA-Z0-9_:\.]+%)(.*)$}
}

ad_proc -public lang::message::message_exists_p { locale key } {
    Return 1 if message exists in given locale, 0 otherwise.

    @author Peter Marklund
} {
    # Make sure messages are in the cache
    cache

    return [nsv_exists lang_message_$locale $key]        
}

ad_proc -public lang::message::lookup {
    locale
    key
    {default "TRANSLATION MISSING"}
    {substitution_list {}}
    {upvar_level 2}
    {translator_mode_p 1}
} {
    This proc is normally accessed through the _ procedure.

    Returns a translated string for the given locale and message key.
    If the user is a translator, inserts tags to link to the translator
    interface. This allows a translator to work from the context of a web page.
    
    Messages will have %name% replaced with variables either from substitution_list, 
    if present, or from the caller's namespace (or upvar_level's namespace).
    Set upvar_level to 0 and substitution_list empty to prevent substitution from happening

    Note that this proc does not use named parameters, because named parameters are 
    relatively slow, and this is going to get called a whole lot on each request.

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
    
    @param translator_mode_p  Set to 0 if you do not want this call to honor translator mode. 
                              Useful if you're not using this message in the page itself, but e.g.
                              for localization data or for the list of messages on the page.

    @author Jeff Davis (davis@arsdigita.com)
    @author Henry Minsky (hqm@arsdigita.com)
    @author Peter Marklund (peter@collaboraid.biz)

    @see _
    @see lang::message::register
    
    @return A localized piece of text.
} { 
    # Make sure messages are in the cache
    cache

    if { [empty_string_p $locale] } {
        # No locale provided

        if { [ad_conn isconnected] } {
            # We are in an HTTP connection (request) so use that locale
            set locale [ad_conn locale]
        } else {
            # There is no HTTP connection - resort to system locale
            set locale [lang::system::locale]
        }
    } elseif { [string length $locale] == 2 } {
        # Only language provided, let's get the default locale for this language
        set default_locale [lang::util::default_locale_from_lang $locale]
        if { [empty_string_p $default_locale] } {
            error "Could not look up locale for language $locale"
        } else {
            set locale $default_locale
        }
    } 

    # We remember the passed-in locale, because we want the translator mode to show which 
    # messages have been translated, and which have not.
    set org_locale $locale

    # Trying locale directly
    if { [message_exists_p $locale $key] } {
        set message [nsv_get lang_message_$locale $key]
    } else {
        # Trying default locale for language
        set language [lindex [split $locale "_"] 0]
        set locale [lang::util::default_locale_from_lang $language]
        if { [message_exists_p $locale $key] } {
            set message [nsv_get lang_message_$locale $key]
        } else {
            # Trying system locale for package (or site-wide)
            set locale [lang::system::locale]
            if { [message_exists_p $locale $key] } {
                set message [nsv_get lang_message_$locale $key]
            } else {
                # Trying site-wide system locale
                set locale [lang::system::locale -site_wide]
                if { [message_exists_p $locale $key] } {
                    set message [nsv_get lang_message_$locale $key]
                } else {
                    # Resorting to en_US
                    set locale "en_US"
                    if { [message_exists_p $locale $key] } {
                        set message [nsv_get lang_message_$locale $key]
                    } else {
                        ns_log Error "lang::message::lookup: Key '$key' does not exist in en_US"
                        set message "MESSAGE KEY MISSING: '$key'"
                    }
                }
            }
        }
    }
    
    # Do any variable substitutions (interpolation of variables)
    # Set upvar_level to 0 and substitution_list empty to prevent substitution from happening
    if { [llength $substitution_list] > 0 || ($upvar_level >= 1 && [string first "%" $message] != -1) } {
        set message [lang::message::format $message $substitution_list [expr $upvar_level + 1]]
    }

    if { [lang::util::translator_mode_p] } {
        # Translator mode - record the message lookup
        lang::util::record_message_lookup $key
        
        if { $translator_mode_p } {
            global message_key_num
            if { ![info exists message_key_num] } {
                set message_key_num 1
            } else {
                incr message_key_num
            }
            
            # encode the key in the page
            set message "$message\x002(\x001$key\x001)\x002"
        }
    }

    return $message
}

ad_proc -private lang::message::translate { 
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


ad_proc -private lang::message::cache {
    {-package_key {}}
} {
    Loads the entire message catalog from the database into the cache.
} {
    # We segregate messages by language. It might reduce contention
    # if we segregage instead by package. Check for problems with ns_info locks.

    # LARS TODO: Use a mutex
    if { ![nsv_exists lang_message_cache executed_p] } {            
        nsv_set lang_message_cache executed_p 1

        if { [empty_string_p $package_key] } {
            set package_where_clause ""
        } else {
            set package_where_clause "where package_key = :package_key"
        }
        
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
    key
    {substitution_list {}}
} {
    Short hand proc that invokes the lang::message::lookup proc. 
    Returns a localized text from the message catalog with the locale ad_conn locale
    if invoked within a request, or the system locale otherwise.

    <p>

    Example: 
<pre>
    set the_url [export_vars -base "[ad_conn package_url]view" { item_id }]
    set body [_ my-package.lt_To_view_this_item [list item_url $the_url]]
</pre>

    If the message value is "To view this item, please click here: %item_url%", then the URL will be insert into the message.

    @param key        Unique identifier for this message. Will be the same identifier
                      for each locale. The key is on the format package_key.message_key

    @param substitution_list 
                      A list of values to substitute into the message on the form { name value name value ... }. 
                      This argument should only be given for certain messages that contain place holders (on the syntax
                      %1:pretty_name%, %2:another_pretty_name% etc) for embedding variable values.
                      If the message contains variables that should be interpolated and this argument
                      is not provided then upvar will be used to fetch the variable values.

    @return           A localized message
    
    @author Jeff Davis (davis@arsdigita.com)
    @author Peter Marklund (peter@collaboraid.biz)
    @author Christian Hvid (chvid@collaboraid.biz)

    @see lang::message::lookup
    @see lang::message::format
} {
    return [lang::message::lookup "" $key "TRANSLATION MISSING" $substitution_list]
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


ad_proc -public lang::message::update_description {
    {-package_key:required}
    {-message_key:required}
    {-description:required}
} {
    @author Simon Carstensen
    @creation_date 2003-08-12
} {
    if { [empty_string_p [string trim $description]] } {
        db_dml update_description_insert_null {}
    } else {
        db_dml update_description {} -clobs [list $description]
    }
}
