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

    ad_proc -private format {
        localized_message
        value_list
    } {
        Substitute occurencies of %1, %2, %3 etc in the given localized message
        with the values given in value_list. The place holder %n, where n is
        an integer, will be replaced (if possible) with the value at index n-1 in
        the value_list.
    } {        

        set remaining_message $localized_message
        set formated_message ""
        set value_count "0"
        while { [regexp {^(.*?)(%%|%[0-9]+)(.*)$} $remaining_message match before_percent percent_match remaining_message] } {

            append formated_message $before_percent

            if { [string equal $percent_match "%%"] } {
                # A quoted percent sign
                append formated_message "%"
            } else {
                set value_index [expr [string range $percent_match 1 end] - 1]
                if { [llength $value_list] <= $value_index } {
                    ns_log Error "lang::message::format: Too few items provided in value list. Trying to access item at index $value_index to substibute for $percent_match but there is no such item in the value list"
                    
                    # There is no value available to do the substitution with
                    # so don't substitute at all
                    append formated_message $percent_match
                } else {
                    # Do the substitution
                    append formated_message [lindex $value_list $value_index]
                }

                incr value_count
            }
        }

        if { [llength $value_list] > $value_count } {
            ns_log Error "lang::message::format: More items (there were [llength $value_list] items) provided in value list than there were percent substitutions in the localized message: \"$localized_message\""
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
    } {
        This proc is normally accessed through the _ procedure.
    
        Returns a translated string for the given locale and message key.
        If the user is a translator, inserts tags to link to the translator
        interface. This allows a translator to work from the context of a web page.

        @param locale             Locale (e.g., "en_US") or language (e.g., "en") string.
        @param key                Unique identifier for this message. Will be the same identifier
                                  for each locale. Most keys belong to a certain package and should
                                  be prefixed with the package key of that package on the format
                                  package_key.message_key (the dot is reserved for separating the
                                  package key, the rest of the key should contain only alpha-numeric
                                  characters and under scores). If the key does not belong to 
                                  any particular package it should not contain a dot. A lookup
                                  is always attempted with the exact key given to this proc.
        @param default            Text to return if there is no message in the message catalog for
                                  the given locale. This argument is optional. If this argument is
                                  not provided or is the empty string then the text returned will
                                  be TRANSLATION MISSING - $key.
        @param substitution_list  A list of values to substitute into the message. This argument should
                                  only be given for certain messages that contain place holders (on the syntax
                                  %1, %2 etc) for embedding variable values.
    
        @author Jeff Davis (davis@arsdigita.com), Henry Minsky (hqm@arsdigita.com)
        @author Peter Marklund (peter@collaboraid.biz)
        @see _
        
        @return A localized piece of text.
    } { 
        # Peter TODO: add translation links
        # Peter TODO/FIXME: Should we prefix with ad_conn package_key if the lookup fails?
    
        set default_locale [parameter::get -package_id [apm_package_id_from_key acs-lang] -parameter SiteWideLocale]
        
        if { [string length $locale] == 2 } {
    
            # it's a language and not a locale
            # let's get the default locale for this language
            # The cache is flushed if the default locale for this language is
            # is changed.
            set locale [util_memoize [list ad_locale_locale_from_lang $locale]]    
        } 
    
        if { [nsv_exists lang_message_$locale $key] } {
            # Message catalog lookup succeeded
            set return_value [nsv_get lang_message_$locale $key]

            ns_log Notice "lang::message::lookup: the key $key exists in the mc"
    
        } else {
            # There is no entry in the message catalog for the given locale

            set return_value $default

            if { [string equal $default "TRANSLATION MISSING"] } {
                append return_value " - " $key                    
            }

            ns_log Notice "lang::message::lookup: the key $key does not exists in the mc"
        }

        # Do any variable substituions (interpolation of variables)
        if { [llength $substitution_list] > 0 } {
            set return_value [lang::message::format $return_value $substitution_list]
        }

        ns_log Notice "lang::message::lookup returning $return_value"

        return $return_value
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
                      %1, %2 etc) for embedding variable values. If you provide this 
                      argument you must also provide the default_text argument as well as the
                      locale argument.
    </pre>

    @return                  A localized piece of text.
    
    @author Jeff Davis (davis@arsdigita.com)
    @author Peter Marklund (peter@collaboraid.biz)
    @author Christian Hvid (chvid@collaboraid.biz)

    @see lang::message::lookup
} {
    switch [llength $args] {
        1 { return [lang::message::lookup [ad_conn locale] [lindex $args 0] "TRANSLATION MISSING"] }
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

