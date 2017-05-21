#/packages/acs-lang/tcl/lang-util-procs.tcl
ad_library {

    Utility routines for translating pages. Many of these procs deal with
    message keys embedded in strings with the #key# or the <#key text#> syntax.
    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    @creation-date 10 September 2000
    @author Jeff Davis (davis@xarg.net)
    @author Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
    @author Peter Marklund (peter@collaboraid.biz)
    @author Lars Pind (lars@collaboraid.biz)
    @author Christian Hvid
    @cvs-id $Id$
}

namespace eval lang::util {}

ad_proc -public lang::util::lang_sort {
    field 
    {locale {}}
} { 
    Each locale can have a different alphabetical sort order. You can test
    this proc with the following data:
    <pre>
    insert into lang_testsort values ('lama');
    insert into lang_testsort values ('lhasa');
    insert into lang_testsort values ('llama');
    insert into lang_testsort values ('lzim');  
    </pre>

    @author Jeff Davis (davis@xarg.net)

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
    
    if { $locale eq "" || ![info exists lang($locale)] } {
        return $field
    } else { 
        return "NLSSORT($field,'NLS_SORT = $lang($locale)')"
    }
}

ad_proc -private lang::util::get_hash_indices { multilingual_string } {
    Returns a list of two element lists containing 
    the start and end indices of a #message_key# match in the multilingual string.
    This proc is used by the localize proc.

    @author Peter marklund (peter@collaboraid.biz)
} {
    return [regexp -inline -indices -all {\#[a-zA-Z0-9_:-]+\.[a-zA-Z0-9_:-]+\#} $multilingual_string]
}

ad_proc lang::util::message_tag_regexp {} {
    The regexp expression used by proc get_temporary_tags_indices and elsewhere
    to extract temporary message catalog tags (<#...#>) from ADP and Tcl files.
    The first sub match of the expression is the whole tag, the second sub match
    is the message key, and the third sub match is the message text in en_US locale.

    @author Peter marklund (peter@collaboraid.biz)
    @see lang::util::message_key_regexp
} {
    return {(<#\s*?([-a-zA-Z0-9_:\.]+)\s+(.+?)\s*?#>)}
}

ad_proc lang::util::message_key_regexp {} {
    Regular expression for recognizing message keys in the form <span>#</span>package_name.key#.
    @see lang::util::message_tag_regexp
} {
    return {\#([-a-zA-Z0-9_]+[.][-a-zA-Z0-9_]+)\#}
}


ad_proc lang::util::get_temporary_tags_indices { adp_file_string } {
    Given the contents of an adp file return the indices of the
    start and end chars of embedded message keys on the syntax:

    <#package_key.message_key Some en_US text#>    

    @author Peter marklund (peter@collaboraid.biz)    
} {
    return [lang::util::get_regexp_indices $adp_file_string [message_tag_regexp]]
}
    
ad_proc -private lang::util::get_regexp_indices { multilingual_string regexp_pattern } {
    Returns a list of two element lists containing 
    the start and end indices of what is captured by the first parenthesis in the
    given regexp pattern in the multilingual string. The
    regexp pattern must follow the syntax of the expression argument to the Tcl regexp command.
    It must also contain exactly one capturing parenthesis for the pieces of text that indices
    are to be returned for.

    @see get_hash_indices

    @author Peter marklund (peter@collaboraid.biz)
} {

    set multilingual_string_offset "0"
    set offset_string $multilingual_string
    set indices_list [list]

    while { [regexp -indices $regexp_pattern $offset_string full_match_idx key_match_idx] } { 
        
        set start_idx [lindex $key_match_idx 0]
        set end_idx [lindex $key_match_idx 1]

        lappend indices_list [list [expr {$multilingual_string_offset + $start_idx}] \
                [expr {$multilingual_string_offset + $end_idx}]]
        
        set new_offset [expr {$end_idx + 1}]
        set multilingual_string_offset [expr {$multilingual_string_offset + $new_offset}]
        set offset_string [string range $offset_string $new_offset end]
    }
    
    return $indices_list
}    

ad_proc lang::util::replace_temporary_tags_with_lookups { 
    file_list 
} {
    Modify the given ADP or Tcl files by replacing occurencies of message keys
    with message lookups (i.e. <span>#</span>package_key.message_key# for ADP files
    and [_ "package_key.message_key"] for Tcl files) and create entries in the
    catalog file for each of these keys. If the short hand form <#_ Some en_US text#>
    is used then the key will be autogenerated based on the text.
    Returns the number of replacements done. This procedure only
    reads from and writes to the catalog file specified (the en_US catalog 
    file per default) of the package that the files belong to, the database 
    is not accessed in any way.

    @param file_list         A list of paths to adp or Tcl files to do replacements in. The
                             paths should be relative to $::acs::rootdir. All files must
                             belong to the same package.

    @author Peter marklund (peter@collaboraid.biz)
} {
    # Return if there are no files to process
    if { [llength $file_list] == 0 } {
        ns_log Warning "lang::util::replace_temporary_tags_with_lookups: Invoked with no files to process, returning"
        return
    }

    # Get package_key
    set first_file [lindex $file_list 0]    
    if { ![regexp {/?packages/([^/]+)/} $first_file match package_key] } {
        error "lang::util::replace_temporary_tags_with_lookups: Could not extract package_key from file $first_file"
    }

    # Always create new keys in en_US
    set locale "en_US"
    
    # Read messages from any existing catalog file
    set catalog_file_path [lang::catalog::get_catalog_file_path \
            -package_key $package_key \
            -locale $locale]
    if { [file exists $catalog_file_path] } {
        set catalog_file_contents [lang::catalog::read_file $catalog_file_path]
        array set catalog_array [lang::catalog::parse $catalog_file_contents]            
        array set messages_array $catalog_array(messages)
    } else {
        array set messages_array {}
    }

    # Keep track of how many message tags we have replaced (will be returned by this proc)
    set number_of_replacements "0"

    # Loop over and process each file
    foreach file $file_list {                
        ns_log debug "lang::util::replace_temporary_tags_with_lookups: processing file $file"

        set full_file_path "$::acs::rootdir/$file"
        regexp {\.([^.]+)$} $file match file_ending

        # Attempt a backup of the file first. Do not overwrite an old backup file.
        if { [catch "file -- copy $full_file_path \"${full_file_path}.orig\"" errmsg] } {
            ns_log Warning "The file $full_file_path could not be backed up before message key extraction since backup file ${full_file_path}.orig already exists"
        }

        # Read the contents of the file
        set file_contents [template::util::read_file $full_file_path]

        set modified_file_contents $file_contents

        # Loop over each message tag in the file
        # Get the indices of the first and last char of the <#...#> text snippets
        set message_key_indices [lang::util::get_temporary_tags_indices $file_contents]
        foreach index_pair $message_key_indices {

            incr number_of_replacements

            set tag_start_idx [lindex $index_pair 0]
            set tag_end_idx [lindex $index_pair 1]
            set message_tag "[string range $file_contents $tag_start_idx $tag_end_idx]"
            
            # Extract the message key and the text from the message tag
            # The regexp on the message tag string should never fail as the message tag
            # was extracted with a known regexp
            if { ![regexp [message_tag_regexp] $message_tag full_match \
                          message_tag message_key new_text] } {

                ns_log Error [list lang::util::replace_temporary_tags_with_lookups - could not extract message key \
                              and text from the message tag $message_tag in file $file. This means there is a \
                              mismatch with the regexp that extracted the message key.]
                continue
            }

            # if the message key is the _ symbol (an underscore) then automatically generate a key
            # based on the message text
            if {$message_key eq "_"} {
                set message_key [suggest_key $new_text]
            }

            # If this is an adp file - replace adp variable syntax with percentage variables
            if {$file_ending eq "adp"} {
                set new_text [convert_adp_variables_to_percentage_signs $new_text]
            }

            # Check if the key already exists, if it does and texts differ - make key unique
            set key_comp_counter "0"
            set unique_key $message_key
            while { 1 } {

                if { [info exists messages_array($unique_key)] } {
                    # The key already exists
                    
                    if {$messages_array($unique_key) eq $new_text} {
                        # New and old texts are identical - don't add the key
                        ns_log Notice [list lang::util::replace_temporary_tags_with_lookups - \
                                       message key $unique_key already exists in catalog \
                                       file with same value, will not add]

                        # We are done
                        break
                    } else {
                        # New and old texts differ, try to make the key unique and check again
                        set unique_key "${message_key}_[expr {${key_comp_counter} + 1}]"
                    }
                } else {
                    # The key is new - save it in the array for addition

                    if { $message_key ne $unique_key } {
                        # The message key had to be changed to be made unique
                        ns_log Warning [list lang::util::replace_temporary_tags_with_lookups - \
                                            The message key $message_key was changed to $unique_key \
                                        to be made unique. If the value was mistyped and should have been \
                                        the same as previously then you must manually remove the entry for \
                                        $unique_key from the catalog file and change the key in \
                                        the file $file fom $unique_key to $message_key]
                    } else {
                        ns_log Notice [list lang::util::replace_temporary_tags_with_lookups - Will be adding \
                                       new key $unique_key to catalog file for package $package_key]
                    }   

                    set messages_array($unique_key) $new_text

                    # We are done
                    break
                }
                
                incr key_comp_counter
            }

            # Replace the message tag with a message key lookup in the file
            switch -regexp -- $file_ending {
                {^(adp|sql)$} {
                    regsub [message_tag_regexp] \
                           $modified_file_contents \
                           "#${package_key}.${unique_key}#" \
                           modified_file_contents
                } 
                {^tcl$} {
                    regsub [message_tag_regexp] \
                            $modified_file_contents \
                            "\[_ ${package_key}.${unique_key}\]" \
                            modified_file_contents
                }
                {.*} {
                    error "Unknown ending $file_ending of file $file, aborting"
                }
            }
        }

        # Update the file with the replaced message keys
        set file_id [open "${full_file_path}" w]
        puts -nonewline $file_id $modified_file_contents
        close $file_id
    }

    if { $number_of_replacements > 0 } {
        # Register the messages in the database so that the new messages are immediately reflected
        # in the system
        foreach {message_key message_text} [array get messages_array] {
            lang::message::register en_US $package_key $message_key $message_text
        }

        # Generate a new catalog file
        lang::catalog::export -locales [list $locale] -package_key $package_key
    }

    return $number_of_replacements
}   

ad_proc -public lang::util::localize {
    string_with_hashes
    {locale ""}
} {
    Takes a string with embedded message keys on the format #message_key_name#
    and returns the same string but with the message keys (and their surrounding hash
    marks) replaced with the corresponding value in the message catalog. Message lookup
    is done with the locale of the request. If message lookup fails for a certain key
    then a translation missing message will be used instead.

    @author Peter marklund (peter@collaboraid.biz)
} {
    # Return quickly for the fairly frequent case where there are no embedded message keys
    if { ![string match "*#*" $string_with_hashes] } {
        return $string_with_hashes
    }

    if {$locale eq ""} {   
         set locale [ad_conn locale]   
    } 

    set indices_list [get_hash_indices $string_with_hashes]
    
    set subst_string ""
    set start_idx 0
    foreach item_idx $indices_list {
        # The replacement string starts and ends with a hash mark
        set replacement_string [string range $string_with_hashes [lindex $item_idx 0] \
                [lindex $item_idx 1]]
        set message_key [string range $replacement_string 1 [string length $replacement_string]-2]

        # Attempt a message lookup
        set message_value [lang::message::lookup $locale $message_key "" "" 2]
        
        # Replace the string
        # LARS: We don't use regsub here, because regsub interprets certain characters
        # in the replacement string specially.
        append subst_string [string range $string_with_hashes $start_idx [lindex $item_idx 0]-1]
        append subst_string $message_value

        set start_idx [expr {[lindex $item_idx 1] + 1}]
    }        

    append subst_string [string range $string_with_hashes $start_idx end]
    
    return $subst_string
}

ad_proc -public lang::util::charset_for_locale { 
    locale 
} {
    Returns the MIME charset name corresponding to a locale.

    @author        Henry Minsky (hqm@mit.edu)
    @param locale  Name of a locale, as language_COUNTRY using ISO 639 and ISO 3166
    @return        IANA MIME character set name
} {
    # DRB: cache this now that ad_conn tracks it
    set key ::lang::util::charset_for_locale($locale)
    if {[info exists $key]} {return [set $key]}
    set $key [db_string -cache_key ad_lang_mime_charset_$locale charset_for_locale {}]
}

ad_proc -private lang::util::default_locale_from_lang_not_cached { 
    language
} {
    Returns the default locale for a language. Not cached.
    
    @author          Henry Minsky (hqm@mit.edu)
    @param language  Name of a language, using a two or three letter ISO code
    @return          Default locale
    
    @see lang::util::default_locale_from_lang
} {
    # LARS:
    # Note that this query does not use bind variables, because these cause the query to not
    # match any rows in Oracle when the language key is less than 3 characters, 
    # because the column is a char(3), not a varchar2(3).
    return [db_string default_locale_from_lang {} -default ""]
}

ad_proc -public lang::util::default_locale_from_lang { 
    language
} {
    Returns an enabled default locale for a language. If a language
    only has one locale then that locale is returned. If no locale
    could be found the empty string is returned.

    @author          Henry Minsky (hqm@mit.edu)
    @param language  Name of a country, using ISO-3166 two letter code
    @return          Default locale
} {
    return [util_memoize [list lang::util::default_locale_from_lang_not_cached $language]]
}

ad_proc -public lang::util::nls_language_from_language { 
    language 
} {
    Returns the nls_language name for a language

    @author          Henry Minsky (hqm@mit.edu)
    @param language  Name of a country, using ISO-3166 two letter code
    @return          The nls_language name of the language.
} {
    return [db_string nls_language_from_language {}]
}


ad_proc -private lang::util::remove_gt_lt {
    s
} {
    Removes < > and replaces them with &lt &gt;
} {
    regsub -all "<" $s {\&lt;} s
    regsub -all ">" $s {\&gt;} s
    return $s
}

ad_proc -private lang::util::suggest_key {
    text
} {
    Suggest a key for given text.
} {
    regsub -all " " $text "_" key
    
    # Do not allow . in the key as dot is used as a separator to qualify a key
    # with the package key. The prepending with package key is done at a later
    # stage
    regsub -all {[^-a-zA-Z0-9_]} $key "" key
                    
    # is this key too long?
                    
    if { [string length $key] > 20 } {
        set key "lt_[string range $key 0 20]"
    }
    return $key
}

ad_proc -private lang::util::convert_adp_variables_to_percentage_signs { text } {
    Convert ADP variables to percentage_signs - the notation used to
    interpolate variable values into acs-lang messages.

    @author Peter Marklund
} {
    # substitute array variable references
    # loop to handle the case of adjacent variable references, like @a@@b@
    while {[regsub -all [template::adp_array_variable_regexp] $text {\1%\2.\3%} text]} {}
    while {[regsub -all [template::adp_array_variable_regexp_noquote] $text {\1%\2.\3;noquote%} text]} {}

    # substitute simple variable references
    while {[regsub -all [template::adp_variable_regexp] $text {\1%\2%} text]} {}
    while {[regsub -all [template::adp_variable_regexp_noquote] $text {\1%\2;noquote%} text]} {}

    return $text 
}

ad_proc -private lang::util::convert_percentage_signs_to_adp_variables { text } {
    Convert percentage_signs message vars to adp var syntax.

    @see lang::util::convert_adp_variables_to_percentage_signs

    @author Peter Marklund
} {
    # substitute array variable references
    # loop to handle the case of adjacent variable references, like @a@@b@
    regsub -all {@} [template::adp_array_variable_regexp] {%} pattern
    while {[regsub -all $pattern $text {\1@\2.\3@} text]} {}
    regsub -all {@} [template::adp_array_variable_regexp_noquote] {%} pattern
    while {[regsub -all $pattern $text {\1@\2.\3;noquote@} text]} {}

    # substitute simple variable references
    regsub -all {@} [template::adp_variable_regexp] {%} pattern
    while {[regsub -all $pattern $text {\1@\2@} text]} {}
    regsub -all {@} [template::adp_variable_regexp_noquote] {%} pattern
    while {[regsub -all $pattern $text {\1@\2;noquote@} text]} {}

    return $text
}

ad_proc -public lang::util::replace_adp_text_with_message_tags { 
    file_name
    mode
    {keys {}}
    
} {
    Prepares an .adp-file for localization by inserting temporary hash-tags
    around text strings that looks like unlocalized plain text. Needless to say
    this is a little shaky so not all plain text is caught and the script may insert
    hash-tags around stuff that should not be localized. It is conservative though.

    There are two modes the script can be run in:

    - report : do *not* write changes to the file but return a report with suggested changes.

    - write : write changes in the file - it expects a list of keys and will insert them
      in the order implied by the report - a report is also returned.

    @param file_name The name of the adp file to do replacements in.
    @param mode      Either report or write.
    @param keys      A list of keys to use for the texts that may be provided in write mode. If
                     the keys are not provided then autogenerated keys will be used.
                     If a supplied key is the empty string this indicates that the corresponding
                     text should be left untouched.

    @return The report is list of two lists: The first being a list of pairs (key, text with context)
            and the second is a list of suspious looking garbage. In report mode the keys are suggested
            keys and in write mode the keys are the keys supplied in the keys parameter.

    @author Christian Hvid
    @author Peter Marklund
    @author Jeff Davis

} {
    set state text 
    set out {}

    set report [list]
    set garbage [list]

    set n 0

    # open file and read its content

    set fp [open $file_name "r"]
    set s [read $fp]
    close $fp

    #ns_write "input== s=[string range $s 0 600]\n"
    set x {}
    while {$s ne "" && $n < 1000} { 
        if { $state eq "text" } { 

            # clip non tag stuff
            if {![regexp {(^[^<]*?)(<.*)$} $s match text s x]} { 
                set text $s
                set s {}
            }  

            # Remove parts from the text that we know are not translatable
            # such as adp variables, message key lookups, and &nbsp;
            set translatable_remainder $text
            set adp_var_patterns [list [template::adp_array_variable_regexp] \
                                       [template::adp_array_variable_regexp_noquote] \
                                       [template::adp_variable_regexp] \
                                       [template::adp_variable_regexp_noquote]]
            foreach adp_var_pattern $adp_var_patterns {
                regsub -all $adp_var_pattern $translatable_remainder "" translatable_remainder
            }
            regsub -all {#[a-zA-Z0-9\._-]+#} $translatable_remainder "" translatable_remainder
            regsub -all {&nbsp;} $translatable_remainder "" translatable_remainder

            # Only consider the text translatable if the remainder contains
            # at least one letter
            if { [string match -nocase {*[A-Z]*} $translatable_remainder] } {

                regexp {^(\s*)(.*?)(\s*)$} $text match lead text lag

                if { $mode eq "report" } {
                    # create a key for the text
                    
                    set key [suggest_key $text]

                    lappend report [list $key "<code>[string range [remove_gt_lt $out$lead] end-20 end]<b><span style=\"background:yellow\">$text</span></b>[string range [remove_gt_lt $lag$s] 0 20]</code>" ]
                } else {    
                    # Write mode
                    if { [llength $keys] != 0} {
                        # Use keys supplied                            
                        if { [lindex $keys $n] ne "" } {
                            # Use supplied key
                            set write_key [lindex $keys $n]
                        } else {
                            # The supplied key for this index is empty so leave the text untouched
                            set write_key ""
                        }
                    } else {
                        # No keys supplied - autogenerate a key
                        set write_key [suggest_key $text]                            
                    }

                    if { $write_key ne "" } {
                        # Write tag to file
                        lappend report [list ${write_key} "<code>[string range [remove_gt_lt $out$lead] end-20 end]<b><span style=\"background:yellow\">$text</span></b>[string range [remove_gt_lt $lag$s] 0 20]</code>" ]

                        append out "$lead<\#${write_key} $text\#>$lag"
                    } else {
                        # Leave the text untouched
                        lappend garbage "<code>[string range [remove_gt_lt $out$lead] end-20 end]<b><span style=\"background:yellow\">$text </span></b>[string range [remove_gt_lt $lag$s] 0 20]</code>"
                        append out "$lead$text$lag"
                    }                        
                }

                incr n

            } else { 
                # this was not something we should localize

                append out $text

                # but this maybe something that should be localized by hand

                if { ![string match {*\#*} $text] && ![string is space $text] && [string match -nocase {*[A-Z]*} $text] && ![regexp {^\s*@[^@]+@\s*$} $text] } {

                    # log a comment on it and make a short version of the text that is easier to read

                    regsub -all "\n" $text "" short_text

                    set short_text [string range $short_text 0 40]
                    
                    lappend garbage "<code>$short_text</code>"

                }

            }
            set state tag            

        } elseif { $state eq "tag"} { 
            if {![regexp {(^<[^>]*?>)(.*)$} $s match tag s]} { 
                set s {}
            } 
            append out $tag
            set state text

        }
    }

    if { $mode eq "write" } {
        if { $n > 0 } {
            # backup original file - fail silently if backup already exists

            if { [catch {file copy -- $file_name $file_name.orig}] } { }
        
            set fp [open $file_name "w"]
            puts $fp $out
            close $fp
        }
    }

    return [list $report $garbage]
}

ad_proc -public lang::util::translator_mode_p {} {
    Whether translator mode is enabled for this session or
    not. Translator mode will cause all non-translated messages to appear as a 
    link to a page where the message can be translated, instead of the default
    "not translated" message.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date October 24, 2002

    @return 1 if translator mode is enabled, 0 otherwise. Returns 0 if there is
            no HTTP connection.

    @see lang::util::translator_mode_set
} {
    if {[info exists ::acs_translator_mode_p]} {
        return $::acs_translator_mode_p
    }
    if { [ad_conn isconnected] } {
        # There is an HTTP connection - return the client property
        set ::acs_translator_mode_p [ad_get_client_property -default 0 acs-lang translator_mode_p]
        if {$::acs_translator_mode_p eq ""} {
            set ::acs_translator_mode_p 0
        }
    } else {
        # No HTTP connection
        set ::acs_translator_mode_p 0
    }
    return $::acs_translator_mode_p
}

ad_proc -public lang::util::translator_mode_set {
    translator_mode_p
} {
    Sets whether translator mode is enabled for this session or
    not.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date October 24, 2002

    @param translator_mode_p 1 if you want translator mode to be enabled, 0 otherwise.

    @see lang::util::translator_mode_p
} {
    ad_set_client_property acs-lang translator_mode_p $translator_mode_p
}

ad_proc -private lang::util::record_message_lookup {
    message_key
} {
    Record a message lookup in translator mode. In translator mode
    we collect all message lookups at the bottom of the page for translation.

    @author Peter Marklund
} {
    global __lang_message_lookups

    # Only makes sense to offer translation list if we're not in en_US locale
    if { [ad_conn locale] ne "en_US" } {
        if { ![info exists __lang_message_lookups] } {
            lappend __lang_message_lookups $message_key
        } elseif {$message_key ni $__lang_message_lookups} {
            lappend __lang_message_lookups $message_key
        }
    }
}

ad_proc -private lang::util::get_message_lookups {} {
    Get the list of all message keys looked up so far during the current
    request.

    @author Peter Marklund
} {
    global __lang_message_lookups

    if { [info exists __lang_message_lookups] } {
        return $__lang_message_lookups
    } else {
        return {}
    }
}


ad_proc -public lang::util::get_label { locale } {

    Returns the label (name) of locale

    @author	Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)

    @param locale	Code for the locale, eg "en_US"

    @return	String containing the label for the locale

} {
    return [db_string select {}]
}


ad_proc -private lang::util::escape_vars_if_not_null {
    list
} {
    Processes a list of variables before they are passed into
    a regexp command.

    @param list   List of variable names
} {
    foreach lm $list {
	upvar $lm foreign_var
	if { ([info exists foreign_var] && $foreign_var ne "") } {
	    set foreign_var "\[$foreign_var\]"
	}
    }
}

ad_proc -public lang::util::convert_to_i18n {
    {-locale}
    {-package_key "acs-translations"}
    {-message_key ""}
    {-prefix ""}
    {-text:required}
} {
    Internationalising of Attributes. This is done by storing the attribute with it's acs-lang key
} {

    # If the package acs-translations is installed do the conversion
    # magic, otherwise just return the text again.

    if {[apm_package_id_from_key acs-translations]} {
	if {$message_key eq ""} {
	    if {$prefix eq ""} {
		# Having no prefix or message_key is discouraged as it
		# might have interesting side effects due to double
		# meanings of the same english string in multiple contexts
		# but for the time being we should still allow this.
		set message_key [lang::util::suggest_key $text]
	    } else {
		set message_key "${prefix}_[lang::util::suggest_key $text]"
	    }
	} 
	
	# Register the language keys
	lang::message::register en_US $package_key $message_key $text
	if {([info exists locale] && $locale ne "")} {
	    lang::message::register $locale $package_key $message_key $text
	}
	
	return "#${package_key}.${message_key}#"
    } else {
	return "$text"
    }
}

ad_proc -public lang::util::localize_list_of_lists {
    {-list}
} {
    localize the elements of a list_of_lists
} {
    set list_output [list]
    foreach item $list {
	set item_output [list]
	foreach part $item {
	    lappend item_output [lang::util::localize $part]
	}
	lappend list_output $item_output
    }
    return $list_output
}

ad_proc -public lang::util::get_locale_options {
} {
    Return a list of locales know to the system
} {
    return [util_memoize lang::util::get_locale_options_not_cached]
}

ad_proc -private lang::util::get_locale_options_not_cached {} {
    Return all enabled locales in the system in a format suitable for the options argument of a form.

    @author Lars Pind
} {
    return [db_list_of_lists select_locales {}]
}

ad_proc -public lang::util::edit_lang_key_url {
    -message:required
    {-package_key "acs-translations"}
} {
} {
    if { [regsub "^${package_key}." [string trim $message "\#"] {} message_key] } {
        set edit_url [export_vars -base "[apm_package_url_from_key "acs-lang"]admin/edit-localized-message" {
            { locale {[ad_conn locale]} } package_key message_key { return_url [ad_return_url] }
        }]
     } else {
	 set edit_url ""
     }
     return $edit_url
 }

ad_proc -public lang::util::iso6392_from_language { 
    -language:required
} {

    Returns the ISO-639-2 code for a language.

    @param language  Language, using ISO-639 code (2 or 3 chars)
    @return          The ISO-639-2 terminology code for the language

} {

    set iso6392_code ""
    set lang_len [string length $language]
    if { $lang_len eq 2 } {
        # input is iso-639-1 language code

        set iso6392_code [db_string get_iso2_code_from_iso1 {} -default ""]

    } elseif { $lang_len eq 3 } {
        # input is iso-639-2 language code
        # we check in the table in case the language code is wrong
        
        set iso6392_code [db_string get_iso2_code_from_iso2 {} -default ""]
    }

    return $iso6392_code
}

ad_proc -public lang::util::iso6392_from_locale { 
    -locale:required
} {

    Returns the ISO-639-2 code for a locale.

    @param locale    Locale to get the language ISO-639-2 code for
    @return          The ISO-639-2 language code for the locale

} {

    # Don't use string range since 3 digits languages may be used
    set language [lindex [split $locale "_"] 0]
    return [lang::util::iso6392_from_language -language $language]
}

ad_proc -public lang::util::language_label { 
    -language:required
} {

    Returns the ISO-639 label for a language code.

    @param language  Language, using ISO-639 code (2 or 3 chars)
    @return          The ISO-639 label for the language

} {

    set lang_label ""
    set lang_len [string length $language]
    if { $lang_len eq 2 } {
        # input is iso-639-1 language code

        set lang_label [db_string get_label_from_iso1 {} -default ""]

    } elseif { $lang_len eq 3 } {
        # input is iso-639-2 language code
        # we check in the table in case the language code is wrong
        
        set lang_label [db_string get_label_from_iso2 {} -default ""]
    }

    return $lang_label
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
