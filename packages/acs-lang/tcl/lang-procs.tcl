#/packages/acs-i18n/tcl/lang-procs.tcl
ad_library {

    Routines for displaying web pages in multiple languages
    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    @creation-date 10 September 2000
    @author Jeff Davis (davis@arsdigita.com)
    @cvs-id $Id$
}


ad_proc -public _mr { lang key message } {

    Registers a message in a given language.
    Inserts the message into the table lang_messages
    if it does not exist and updates if it does.

    @author Jeff Davis (davis@arsdigita.com)
    
    @param lang    Abbreviation for language of the message. Taken from ad_locales table.
    @param key     Unique identifier for this message. Will be the same identifier
                   for each language
    @param message Text of the message

} {
    return [lang_message_register $lang $key $message]
}


ad_proc -private lang_message_register { lang key message } { 

    Normally accessed through the _mr procedure.
    Registers a message in a given language.
    Inserts the message into the table lang_messages
    if it does not exist and updates if it does.

    @author Jeff Davis (davis@arsdigita.com)
    @see _mr
    
    @param lang    Locale or language of the message. If a language is supplied,
                   the default locale for the language is looked up. 
                   Taken from ad_locales table.
    @param key     Unique identifier for this message. Will be the same identifier
                   for each language
    @param message Text of the message

} { 

    # First we check if the given key already exists
    # or if this is different than what we have saved.
    
    # If we are loading a message file at init time, the variable
    # __lang_catalog_load_package_key will be bound in the caller.
    # If it exists, use it as the package prefix.
    global __lang_catalog_load_package_key 
    if {[info exists __lang_catalog_load_package_key]} {
	set key "$__lang_catalog_load_package_key.$key"
    }

    # Check the cache
    if {[nsv_exists lang_message_$lang $key]} { 
        set old_message [nsv_get lang_message_$lang $key]
        if {[string compare $message $old_message] != 0} {
            # changed message ... update.
	    db_dml lang_message_update " 
		    update lang_messages set 
		    registered_p = 't' 
                    ,message = empty_clob() 
		    where lang = :lang and key = :key
            returning message into :1" -clobs [list $message]
            nsv_set lang_message_$lang $key $message
        }
    } else { 
        ns_log Notice "Message: $lang $key not found" 
        # no message so insert 
	db_dml lang_message_insert " 
		insert into lang_messages (key, lang, message, registered_p) 
		values (:key, :lang, empty_clob(),'t') 
                returning message into :1" -clobs [list $message]
        nsv_set lang_message_$lang $key $message
    }
}

ad_proc -public _ {locale key {default "TRANSLATION MISSING"}} {

    Returns a translated string for the given language and message key.
    If the user is a translator, inserts tags to link to the translator
    interface. This allows a translator to work from the context of a web page.

    @author Jeff Davis (davis@arsdigita.com)
    
    @param locale    Abbreviation for language of the message. Taken from ad_locales table.
    @param key     Unique identifier for this message. Will be the same identifier
                   for each language
    @return        The translated string for the message specified by the key in the language specified.
} {
    return [lang_message_lookup $locale $key $default]
}
    
ad_proc -private lang_message_lookup {locale key {default "TRANSLATION MISSING"}} {

    Normally accessed through the _ procedure.

    Returns a translated string for the given language and message key.
    If the user is a translator, inserts tags to link to the translator
    interface. This allows a translator to work from the context of a web page.

    The lookup is tried in this order:

    1. Lookup is first tried with the full locale (if present) and package.key

    2. Lookup is tried with just the language portion of the locale and 
    package.key

    3. Lookup is tried with the full locale and key without package prefix.

    4. Lookup is tried with language and key without package prefix.

    @author Jeff Davis (davis@arsdigita.com), Henry Minsky (hqm@arsdigita.com)
    @see _
    
    @param locale  Locale (e.g., "en_US") or language (e.g., "en") string.
    @param key     Unique identifier for this message. Will be the same identifier
                   for each language
    @return        The translated string for the message specified by the key in the language specified.
} { 

    # Hook for providing translator interface.
    if [ns_conn isconnected] {
	set translate_p [ad_get_client_property  -default 0 lang translate]
	set package_key [ad_conn package_key]
	set full_key "$package_key.$key"
    } else {
	set translate_p 0
	set full_key $key
    }
    
    set lang [string range $locale 0 1]

    if {[nsv_exists lang_message_$locale $full_key]} { 
        if {$translate_p} { 
            return "[nsv_get lang_message_$locale $full_key] <b><a href=\"/lang/translate-edit.adp?locale=$locale&key=$full_key\">E</a></b>|<b><a href=\"/lang/translate-add.adp?key=$full_key\">T</a></b>"
        } else { 
            return [nsv_get lang_message_$locale $full_key]
        }
    } elseif {[nsv_exists lang_message_$lang $full_key]} {
        if {$translate_p} { 
            return "[nsv_get lang_message_$lang $full_key] <b><a href=\"/lang/translate-edit.adp?locale=$lang&key=$full_key\">E</a></b>|<b><a href=\"/lang/translate-add.adp?key=$full_key\">T</a></b>"
        } else { 
            return [nsv_get lang_message_$lang $full_key]
        }
	
    } else { 
        # TODO We should catch these and flag for translation (JCD)
        if {[string match $locale en]} { 
            if {$translate_p} { 
                return "$full_key <b><a href=\"/lang/translate-add.adp?key=$full_key\">T</a></b>"
            } else { 
		if {![empty_string_p $default]} {
		    return $default
		} else {
		    return "$key"
		}
            }
        } else { 
            return "[lang_message_lookup en $key $default] (?$locale)"
        }
    }
}




ad_proc -public lang_catalog_load {{package_key "acs-lang"} } { 
    Load the message catalogs from a package, defaults to /packages/lang/catalog/ directory.
    Catalogs specify the MIME charset name of their encoding in their pathname.



    @author Jeff Davis (davis@arsdigita.com)
    @return        Number of files loaded

} { 
    ns_log Notice "Starting load of the message catalogs [acs_root_dir]/packages/$package_key/catalog/*.cat" 
    
    global __lang_catalog_load_package_key
    set __lang_catalog_load_package_key $package_key
    set files [glob -nocomplain "[acs_root_dir]/packages/$package_key/catalog/*.cat"]
    
    set charsets [ns_charsets]

    if {[empty_string_p $files]} { 
        ns_log Warning "no files found in message catalog directory"
    } else { 
        foreach msg_file $files { 
            if {![regexp {/([^/]*)\.([^/]*)\.cat$} $msg_file match base msg_encoding]} { 
                ns_log Warning "assuming $msg_file is iso-8859-1" 
                set msg_encoding iso-8859-1
            }
             
            if {[lsearch -exact $charsets $msg_encoding] < 0} { 
                ns_log Warning "$msg_file in $msg_encoding not supported by tcl, assuming [encoding system]"
                set msg_encoding [encoding system]
            }
            
            ns_log Notice "Loading $msg_file in $msg_encoding"
            set in [open $msg_file]
            fconfigure $in -encoding [ns_encodingforcharset $msg_encoding]
            set src [read $in]
            close $in 
            
            if {[catch {eval $src} errMsg]} { 
                ns_log Warning "Failed loading message catalog $msg_file:\n$errMsg"
            }
        }
    }

    ns_log Notice "Finished load of the message catalog" 
    
    unset __lang_catalog_load_package_key 

    return $files
}
    
ad_proc -public lang_sort {field {locale {}}} { 

    Each locale can have a different alphabetical sort order. You can test
    this proc with the following data:
    <pre>
    insert into lang_testsort values ('lama');
    insert into lang_testsort values ('lhasa');
    insert into lang_testsort values ('llama');
    insert into lang_testsort values ('lzim');  
    </pre>

    @author Jeff Davis (davis@arsdigita.com)

    @param field       Name of Oracle column
    @param locale      Locale for sorting. 
                       If locale is unspecified just return the column name
    @return Language aware version of field for Oracle <em>ORDER BY</em> clause.

} {
    # Use west european for english since I think that will fold 
    # cedilla etc into reasonable values...
    set lang(en) "XWest_european"
    set lang(de) "XGerman_din"
    set lang(fr) "XFrench" 
    set lang(es) "XSpanish" 
    
    if {[empty_string_p $locale]
        || ![info exists lang($locale)]} {
        return $field
    } else { 
        return "NLSSORT($field,'NLS_SORT = $lang($locale)')"
    }
}

ad_proc -private lang_babel_translate { msg lang } {

    Translates an English string into a different language
    using Babelfish.

    @author            Henry Minsky (hqm@mit.edu)

    @param msg         String to translate
    @param lang        Abbreviation for lang in which to translate string
    @return            Translated string

} {
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

ad_proc -private lang_translate_message_catalog { } {

    Translates all untranslated strings in a message catalog
    from English into Spanish, French and German
    using Babelfish. Quick way to get a multilingual site up and
    running if you can live with the quality of the translations.
    <p>
    Not a good idea to run this procedure if you have
    a large message catalog. Use for testing purposes only.

    @author            John Lowry (lowry@arsdigita.com)

} {
    set sql "SELECT key
                    ,message 
               FROM lang_messages lm1 
              WHERE locale_abbrev = 'en'
     AND NOT EXISTS (SELECT 1 FROM lang_messages lm2 
                      WHERE locale_abbrev != 'en' 
                        AND lm1.key = lm2.key)"
 
    db_foreach lang_get_untranslated_messages $sql {

	foreach lang [list es fr de] {
	    if [catch {
		set translated_message [lang_babel_translate $message en_$lang]
	    } errmsg] {
		ns_log Notice "Error translating $message into $lang: $errmsg"
	    } else {
		_mr $lang $key $translated_message
	    }
	}
    }                 
}




ad_proc -private lang_tag_translate { text params } {

   This function was used with the old adp parser, and is
   deprecated. The new templating system requires a definition using
   template_tag in the
   acs-templating package.

   <p>

    Procedure that gets called when the &lt;trn&gt; tag is encountered on an ADP page.
    The purpose of the procedure is to register the text string enclosed within a
    pair of &lt;trn&gt; tags as a message in the catalog, and to display the appropriate
    translated string.
    Takes three optional parameters: <code>lang</code>, <code>type</code> 
    and <code>key</code>.
    <ul>
    <li><code>key</code> specifies the key in the message catalog. If it is omitted
    this procedure returns simply the text enclosed by the tags.
    <li><code>lang</code> specifies the language of the text string enclosed within the 
    flags. If it is ommitted value defaults to English.
    <li><code>type</code> specifies the context in which the translation is made. If omitted,
    type is user which means that the translation is provided in the user's preferred language.
    </ul>
    Example 1: Display the text string <em>Hello</em> on an ADP page (i.e. do nothing special):
    <pre>
    &lt;trn&gt;Hello&lt;/trn&gt;
    </pre>
    Example 2: Assign the key key <em>hello</em> to the text string <em>Hello</em> and display
    the translated string in the user's preferred language:
    <pre>
    &lt;trn key=&quot;hello&quot;&gt;Hello&lt;/trn&gt;
    </pre>
    Example 3: Specify that <em>Bonjour</em> needs to be registered as the French translation
    for the key <em>hello</em> (in addition to displaying the translation in the user's
    preferred language):
    <pre>
    &lt;trn key=&quot;hello&quot; lang=&quot;fr&quot;&gt;Bonjour&lt;/trn&gt;
    </pre>
    Example 4: Register the string and display it in the preferred language of the 
    current user. Note that the possible values for the <code>type</code>
    paramater are determined by what has been implemented in the <code>ad_locale</code> procedure.
    By default, only the <code>user</code> type is implemented. An example of a type that
    could be implemented is <code>subsite</code>,
    for displaying strings in the language of the subsite that owns the current web page.
    <pre>
    &lt;trn key=&quot;hello&quot; type=&quot;user&quot;&gt;Hello&lt;/trn&gt;
    </pre>

    @author Jeff Davis (davis@arsdigita.com)
    @see lang_message_lookup
    @see lang_message_register
    @see ad_locale
    
    @param text    Text to be translated
    @param params  <code>ns_set</code> containing values for <code>type</code>, 
                   <code>key</code> and <code>lang</code> parameters
    @return        Translated text

} {
    set lang [ns_set iget $params lang]
    set type [ns_set iget $params type]
    if [empty_string_p $lang] {
        set lang en
    }
    if [empty_string_p $type] {
        set type user
    }
    set key [ns_set iget $params key]

    if { ![empty_string_p $key] 
        || [regexp "^(.+)\#\#(.*)" $text x key text]} {
            
        if {![empty_string_p $text]} { 
            lang_message_register $lang $key $text
        }
        return [lang_message_lookup [ad_locale $type language] $key]
    }

    return "$text"
}
