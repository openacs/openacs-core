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
        key
        message
    } { 
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
    
    } { 
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
            ns_log Notice "Inserting into database message: $locale $key" 
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
    
    ad_proc -public lookup {
        locale
        key
        {default "TRANSLATION MISSING"}
    } {
        Normally accessed through the _ procedure.
    
        Returns a translated string for the given language and message key.
    
        The key of the localized message is stored in the following format,
        string1.string2 where string1 is a string that contains only alpha
        characters and '-' concateneted with a '.' and string2 is the 
        identification of the message.
        
        The lookup is tried in this order:
    
        1 A check is done by prefixing the key with
            the package key of the request.
        2. If there is no match, a lookup is performed with the key
             prepended with 'generic.' since it doesn't contain a dot.
        3. If there is no match a check is done with the full key and
             a warning is issued if a match is found since this means the key is uncategorized.
             All keys should belong to a package or be generic/site-wide.
        4. If there is still no match the default message is issued.
    
        @author Jeff Davis (davis@arsdigita.com), Henry Minsky (hqm@arsdigita.com)
        @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
        @author Peter Marklund (peter@collaboraid.biz)
        @see _
        
        @param locale  Locale (e.g., "en_US") or language (e.g., "en") string.
        @param key     Unique identifier for this message. Will be the same identifier
                       for each language
        @return        The translated string for the message specified by the key in the language specified.
    } { 
        # Peter Marklund: I simplified this proc by removing the check for a dot
        # We could add that check back later for optimization but there was too much
        # duplication in the proc and it was too complex
        # TODO: add translation links
    
        set full_key $key
        set default_locale [parameter::get -package_id [apm_package_id_from_key acs-lang] -parameter SiteWideLocale]
        
        if { [string length $locale] == 2 } {
    
            # it's a language and not a locale
            # let's get the default locale for this language
            # The cache is flushed if the default locale for this language is
            # is changed.
            set locale [util_memoize [list ad_locale_locale_from_lang $locale]]
    
        } 
    
        # Since we have for sure the locale (one way or another)
        set lang [string range $locale 0 1]
    
        # Most keys should be prefixed with the package key so try that first
        if { [catch "set package_key \[ad_conn package_key\].${full_key}" errmsg] } {
            # This means we have no connection and no package_key to use
            set package_key $full_key
        }
    
        set generic_key "generic.${full_key}"
    
        if { [nsv_exists lang_message_$locale $package_key] } {    
            # Prefixing with package key
    
            return [nsv_get lang_message_$locale $package_key]
    
        } elseif { [nsv_exists lang_message_$locale $generic_key] } {                
            # Prefixing with generic
    
            # We found it.
            return [nsv_get lang_message_$locale $generic_key]
    
        } elseif { [nsv_exists lang_message_$locale $full_key] } {
    
            if {! [regexp {[\.]} $full_key match] } {
                ns_log Warning "Warning" "Localized message key \"$full_key\" found but is not categorized (contains no dot)."
            }
    
            return [nsv_get lang_message_$locale $full_key]
    
        } else {
    
            # Oops. No, not here ... Let's get the translation missing
            # message out! If we are being queried in the default locale
            # then we can give the answer right away, if not, requery
            # ourselves with the default locale (this is the default 
            # behaviour required).
    
            if {[string match $locale $default_locale]} {
    
                if {![empty_string_p $default]} {
    
                    if { [string equal $default "TRANSLATION MISSING"] } {
    
                        append default_answer $default " - " $full_key
    
                    } else {
    
                        set default_answer $default
    
                    }
    
                    return $default_answer
    
                } else {
    
                    return "$key"
    
                }
    
            } else {
    
                # Returning the default (in the default locale)
                #return "[lang_message_lookup $default_locale $key $default]"
    
                # Peter: Just return the default
                return $default
            }            
        }
    }

    ad_proc -private translate { 
        msg
        locale
    } {
        Translates an English string into a different language
        using Babelfish.
        
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
        
        set i 0 
        db_foreach select_locale_keys {} {
            nsv_set lang_message_$locale $key $message
            incr i
        }
        
        db_release_unused_handles
        
        ns_log Notice "Initialized message table; got $i rows"
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

    @author Jeff Davis (davis@arsdigita.com)
    
    @param locale  Abbreviation for language of the message or the locale.
    @param key     Unique identifier for this message. Will be the same identifier
                   for each language
    @param message Text of the message

    @see lang::message::register
} {
    return [lang::message::register $locale $key $message]
}


ad_proc -public _ {
    locale 
    key 
    {default "TRANSLATION MISSING"}
} {
    Returns a translated string for the given language and message key.
    If the user is a translator, inserts tags to link to the translator
    interface. This allows a translator to work from the context of a web page.

    @author Jeff Davis (davis@arsdigita.com)
    
    @param locale  Locale or language of the message. Locale is taken from ad_locales table,
                   language is taken from language_codes table.
    @param key     Unique identifier for this message. Will be the same identifier
                   for each locale
    @return        The translated string for the message specified by the key in the language specified.
    
    @see lang::message::lookup
} {
    return [lang::message::lookup $locale $key $default]
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
    Normally accessed through the _ procedure.

    Returns a translated string for the given language and message key.

    The key of the localized message is stored in the following format,
    string1.string2 where string1 is a string that contains only alpha
    characters and '-' concateneted with a '.' and string2 is the 
    identification of the message.
    
    The lookup is tried in this order:

    1 A check is done by prefixing the key with
        the package key of the request.
    2. If there is no match, a lookup is performed with the key
         prepended with 'generic.' since it doesn't contain a dot.
    3. If there is no match a check is done with the full key and
         a warning is issued if a match is found since this means the key is uncategorized.
         All keys should belong to a package or be generic/site-wide.
    4. If there is still no match the default message is issued.

    @author Jeff Davis (davis@arsdigita.com), Henry Minsky (hqm@arsdigita.com)
    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Peter Marklund (peter@collaboraid.biz)
    @see _
    
    @param locale  Locale (e.g., "en_US") or language (e.g., "en") string.
    @param key     Unique identifier for this message. Will be the same identifier
                   for each language
    @return        The translated string for the message specified by the key in the language specified.
    
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

