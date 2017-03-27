#/packages/acs-lang/tcl/lang-catalog-procs.tcl
ad_library {

    <p>
    Routines for importing/exporting messages from/to XML message
    catalog files. Every OpenACS package has one message catalog file for
    each locale (language and region) that its UI supports. Importing of messages means reading the messages
    from XML catalog files and storing them in the database. Exporting of messages refers to the opposite process. 
    The key procedures in this library are:
    </p>

    <p>
      <ul>
        <li>lang::catalog::import - Import all catalog files on the system into the database. 
            Can be restricted to only import from one package and only certain locales.</li>
        <li>lang::catalog::import_from_file - Import from a single catalog file</li>
        <li>lang::catalog::export - Export all messages in the database to catalog files. 
            Can be restricted to only export from one package and only certain locales.</li>
        <li>lang::catalog::export_to_file - Export messages to a single file</li>
      </ul>
    </p>

    @creation-date 10 September 2000
    @author Jeff Davis
    @author Peter Marklund (peter@collaboraid.biz)
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval lang::catalog {}

##################
#
# Helper procs
#
##################

ad_proc -private lang::catalog::default_charset_if_unsupported { charset } {
    Will return the system default charset and issue a warning in the log
    file if the given charset is not supported by tcl. Otherwise
    the given charset is simply returned.        

    @author Jeff Davis
    @author Peter Marklund (peter@collaboraid.biz)
} {
    set ns_charsets [concat [ns_charsets] [encoding names]]
    # Do case insensitive matching
    if {[lsearch -regexp $ns_charsets "(?i)^${charset}\$"] < 0} { 
        #set default_charset [encoding system] 
        # LARS: Default to utf-8
        set default_charset utf-8
        ns_log Warning "charset $charset not supported by tcl, assuming $default_charset"
        set charset_to_use $default_charset
    } else {
        set charset_to_use $charset
    }

    return $charset_to_use
}

ad_proc -private lang::catalog::get_required_xml_attribute { element attribute } {
    Return the value of the given attribute and raise an error if the
    value is missing or empty.

    @author Peter Marklund (peter@collaboraid.biz)
} {
    set value [xml_node_get_attribute $element $attribute]

    if { $value eq "" } {
        error "Required attribute \"$attribute\" missing from <[xml_node_get_name $element]>"
    }

    return $value
}

ad_proc -private lang::catalog::all_messages_for_package_and_locale { package_key locale } {
    Set a multirow with name all_messages locally in the callers scope with
    the columns message_key and message for all message keys that do
    not have an upgrade status of deleted.

    @author Peter Marklund
} {
    return [db_list_of_lists get_messages {}]
}
    
ad_proc -private lang::catalog::package_catalog_dir { package_key } {
    Return the catalog directory of the given package.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 18 October 2002
} {
    return "[acs_package_root_dir $package_key]/catalog"
}

ad_proc -private lang::catalog::is_upgrade_backup_file { file_path } {
    Given a file path return 1 if the path represents a 
    file with messages backed up from message catalog upgrade.

    @author Peter Marklund
} {
    array set filename_info [apm_parse_catalog_path $file_path]

    if { [array size filename_info] == 0 } {
        # Parsing failed
        set return_value 0
    } else {
        # Parsing succeeded
        set prefix $filename_info(prefix)
        if { [regexp "^[message_backup_file_prefix]" $prefix match] } {
            # The prefix looks right
            set return_value 1
        } else {
            # Catalog file with unknown prefix
            ns_log Warning "The file $file_path has unknown prefix $prefix"
            set return_value 0
        }
    }

    return $return_value
}

ad_proc -private lang::catalog::message_backup_file_prefix {} {
    The prefix used for files where we store old messages that were
    overwritten during message catalog upgrade.
} {
    return "overwritten_messages_upgrade_"
}

ad_proc -private lang::catalog::assert_catalog_file { catalog_file_path } {
    Throws an error if the given path is not valid for a catalog file.

    @see apm_is_catalog_file

    @author Peter Marklund
} {
    if { ![apm_is_catalog_file $catalog_file_path] } {
        error "lang::catalog::assert_filename_format - Invalid message catalog path, cannot extract package_key, locale, and charset from file path $catalog_file_path"
    }
}

ad_proc -private lang::catalog::package_has_files_in_locale_p {package_key locale} {
    Return 1 if the given package has any catalog files for the given locale
    and 0 otherwise.

    @author Peter Marklund
} {
    if { [catch {glob [package_catalog_dir $package_key]/$package_key.${locale}.*}] } {
        set has_file_in_locale_p 0
    } else {
        set has_file_in_locale_p 1
    }
    
    return $has_file_in_locale_p
}

ad_proc -private lang::catalog::get_catalog_file_path { 
    {-backup_from_version ""}
    {-backup_to_version ""}
    {-package_key:required} 
    {-locale:required}
    {-charset ""}
} {
    Get the full path of the catalog file for a given package, and locale.

    @param charset Should normally not be provided. Will force the charset to a certain value.
                   If not provided an appropriate charset to write the locale in will be used.

    @see apm_parse_catalog_path
    @see lang::catalog::package_has_files_in_locale_p

    @author Peter Marklund
} {
    set catalog_dir [package_catalog_dir $package_key]

    if { $charset ne "" } {
        set file_charset $charset
    } else {
        # We had problems storing digits in ISO-8859-6 so we decided
        # to use UTF-8 for all files except for locales that use ISO-8859-1. The reason we are making
        # ISO-8859-1 an exception is that some developers may make the shortcut of editing
        # the en_US catalog files directly to add keys and they might mess up the
        # utf-8 encoding of the files when doing so.
        set system_charset [lang::util::charset_for_locale $locale]
        set file_charset [ad_decode $system_charset "ISO-8859-1" $system_charset utf-8]
    }

    set message_backup_prefix ""
    if { $backup_from_version ne "" } {
        set message_backup_prefix "[message_backup_file_prefix]${backup_from_version}-${backup_to_version}_"
    }

    set filename "${message_backup_prefix}${package_key}.${locale}.${file_charset}.xml"

    set file_path "[package_catalog_dir $package_key]/$filename"
    
    return $file_path
}

ad_proc -private lang::catalog::get_catalog_files { package_key } {
    Return the full paths of all message catalog files of the given package.

    @param package_key The key of the package to return catalog file paths for

    @return A list of catalog file paths

    @author Peter Marklund
} {
    set catalog_paths [list]

    set catalog_dir [lang::catalog::package_catalog_dir $package_key]
    foreach file_path [glob -nocomplain "$catalog_dir/*"] {
        if { [apm_is_catalog_file $file_path] } {
            lappend catalog_paths $file_path
        }
    }

    return $catalog_paths
}

ad_proc -private lang::catalog::messages_in_db {
    {-package_key:required}
    {-locale:required}
} {
    Return a list of all messages for a certain package and locale.

    @return An array list with message keys as keys and messages as
            values.

    @see lang::catalog::all_messages_for_package_and_locale

    @author Peter Marklund
} {
    set message_list [list]

    foreach message_tuple [all_messages_for_package_and_locale $package_key $locale] {
        lassign $message_tuple message_key message description
        lappend message_list $message_key $message
    }
    return $message_list
}


ad_proc -private lang::catalog::last_sync_messages {
    {-package_key:required}
    {-locale:required}
} {
    For a certain package, and locale, return the messages in 
    the database the last time catalog files and db were in sync.
    This is the message that we use as merge base during message catalog 
    upgrades.

    @return An array list with message keys as keys and messages as
            values.

    @author Peter Marklund
} {
    set message_list [list]
    db_foreach last_sync_messages {} {
        if { ![template::util::is_true $deleted_p] } {
            lappend message_list $message_key $message
        }
    }

    return $message_list
}

ad_proc -private lang::catalog::uninitialized_packages {} {
    Return a list of keys for installed and enabled packages 
    that do not have any message keys associated with them.
    This would suggest that either the package is not internationalized,
    or we have not yet imported the message keys for the package.

    @author Peter Marklund
} {
    return [db_list select_uninitialized {}]
}

##################
#
# Exporting procs
#
##################

ad_proc -private lang::catalog::export_to_file { 
    {-descriptions_list ""}
    file_path 
    messages_list 
} {

    Export messages for a certain locale and package from the database 
    to a given XML catalog file.
    If the catalog file already exists it will be backed up to a file with the
    same name but the extension .orig added to it. If there is an old backup
    file no new backup is done.
    
    @param file_path The path of the catalog file to write messages to. The filename
                     needs to be parseable by apm_parse_catalog_path.
                     The file and the catalog directory will be created if they don't exist.

    @param message_list A list with message keys on even indices followed by
                        corresponding messages on odd indices.

    @author Peter Marklund (peter@collaboraid.biz)
} {
    # Extract package_key, locale, and charset from the file path
    array set filename_info [apm_parse_catalog_path $file_path]
    
    # Check that the filename is parsable. We are not requiring any particular directory though
    if { [array size filename_info] == 0 } {
        error "Could not parse package_key, locale, and charset from filename of file $file_path"
    }

    # Put the messages and descriptions in an array so it's easier to access them
    array set messages_array $messages_list
    array set descriptions_array $descriptions_list

    # Sort the keys so that it's easier to manually read and edit the catalog files
    set message_key_list [lsort -dictionary [array names messages_array]]

    # Create the catalog directory if it doesn't exist
    set catalog_dir [package_catalog_dir $filename_info(package_key)]
    if { ![file isdirectory $catalog_dir] } {
        ns_log Notice "Creating new catalog directory $catalog_dir"
        file mkdir $catalog_dir
    }

    # Create a backup file first if a file already exists
    set backup_path "${file_path}.orig"
    if { [file exists $file_path] } {
        ns_log Notice "Creating backup catalog file $backup_path"
        file copy -force -- $file_path $backup_path
    } 

    # Since the output charset, and thus the filename, may have changed since
    # last time that we wrote the catalog file we remove old files with the same locale
    foreach old_catalog_file [get_catalog_files $filename_info(package_key)] {
        # Parse locale from filename
        array set old_filename_info [apm_parse_catalog_path $old_catalog_file]

        if {$old_filename_info(locale) eq $filename_info(locale)} {
            file delete -- $old_catalog_file
        }
    }

    # Open the catalog file for writing, truncate if it exists
    set file_encoding [ns_encodingforcharset [default_charset_if_unsupported $filename_info(charset)]]

    set catalog_file_id [open $file_path w]
    fconfigure $catalog_file_id -encoding $file_encoding

    # Open the root node of the document
    puts $catalog_file_id "<?xml version=\"1.0\" encoding=\"$filename_info(charset)\"?>
<message_catalog package_key=\"$filename_info(package_key)\" locale=\"$filename_info(locale)\" charset=\"$filename_info(charset)\">
"

   # Loop over and write the messages to the file
   set message_count "0"
   foreach message_key $message_key_list {
       puts $catalog_file_id "  <msg key=\"[ns_quotehtml $message_key]\">[ns_quotehtml $messages_array($message_key)]</msg>"
       if { ([info exists descriptions_array($message_key)] && $descriptions_array($message_key) ne "") && $filename_info(locale) eq "en_US" } {
           puts $catalog_file_id "  <description key=\"[ns_quotehtml $message_key]\">[ns_quotehtml $descriptions_array($message_key)]</description>\n"
       }
       incr message_count
   }

   # Close the root node and close the file
   puts $catalog_file_id "</message_catalog>"
   close $catalog_file_id       

   ns_log Notice "Wrote $message_count messages to file $file_path with encoding $file_encoding"
}

ad_proc -public lang::catalog::export {
    {-package_key {}}
    {-locales {}}
} {
    Exports I18N messages from the database to XML catalog files. By default exports messages
    for all enabled packages and all enabled locales on the system. Can be restricted to export
    only for a certain package and/or a list of locales.

    @param package_key A key of a package to restrict the export to
    @param locales     A list of locales to restrict the export to

    @author Peter Marklund
} {
    if { $package_key ne "" } {
        set package_key_list $package_key
    } else {
        set package_key_list [apm_enabled_packages]
    }

    foreach package_key $package_key_list {
	# We do not want to export acs-translations. This usually is a very bad idea as the object_ids are different from site to site.
	if {$package_key ne "acs-translations" } {
	    # Loop over all locales that the package has messages in
	    # and write a catalog file for each such locale
	    db_foreach get_locales_for_package {} {
		# If we are only exporting certain locales and this is not one of them - continue
		if { [llength $locales] > 0 && $locale ni $locales } {
		    continue
		}
		
		# Get messages and descriptions for the locale
		set messages_list [list]
		set descriptions_list [list]
		foreach message_tuple [all_messages_for_package_and_locale $package_key $locale] {
                    lassign $message_tuple message_key message description
 		    lappend messages_list $message_key $message
 		    lappend descriptions_list $message_key $description
		}

		set catalog_file_path [get_catalog_file_path \
					   -package_key $package_key \
					   -locale $locale]
		
		export_to_file -descriptions_list $descriptions_list $catalog_file_path $messages_list
		
		# Messages exported to file are in sync with file
		db_dml update_sync_time {}
	    }
	}
    }
}

##################
#
# Importing procs
#
##################

ad_proc -private lang::catalog::read_file { catalog_filename } {
    Returns the contents of the given catalog file as a string
    reading the file with the charset given in the filename.
    
    @param catalog_file_name The full path of the catalog file to read.
                             The basename of the file should be on the form 
                             package_key.locale.charset.ending where ending
                             is either cat or xml (i.e. dotlrn.en_US.iso-8859-1.xml
                             or dotlrn.en_US.iso-8859-1.cat). The cat ending
                             is for the deprecated tcl-based catalog files.

    @author Jeff Davis
    @author Peter Marklund (peter@collaboraid.biz)
} {
    if {![regexp {/([^/]*)\.([^/]*)\.(?:xml|cat)$} $catalog_filename match base msg_encoding]} { 
        ns_log Warning "Charset info missing in filename assuming $catalog_filename is iso-8859-1" 
        set msg_encoding iso-8859-1
    }
    
    set msg_encoding [default_charset_if_unsupported $msg_encoding]

    ns_log Notice "reading $catalog_filename in $msg_encoding"
    set in [open $catalog_filename]
    fconfigure $in -encoding [ns_encodingforcharset $msg_encoding]
    set catalog_file_contents [read $in]        
    close $in                         

    return $catalog_file_contents
}

ad_proc -private lang::catalog::parse { catalog_file_contents } {
    Parse the given catalog file xml contents and return the data as
    an array. The array will contain the following keys:

    <pre>
      package_key
      locale
      charset
      messages    - An array-list with message keys as keys and the message texts as values.
      descriptions - An array-list with message keys as keys and the descriptions as values.
    </pre>

    @author Peter Marklund (peter@collaboraid.biz)
    @author Simon Carstensen (simon@collaboraid.biz)
} {      

    # Check arguments
    if { $catalog_file_contents eq "" } {
        error "lang::catalog::parse the catalog_file_contents arguments is the empty string"
    }

    # The names of xml tags and attributes
    set MESSAGE_CATALOG_TAG "message_catalog"
    set PACKAGE_KEY_ATTR "package_key"
    set LOCALE_ATTR "locale"
    set CHARSET_ATTR "charset"
    set MESSAGE_TAG "msg"
    set DESCRIPTION_TAG "description"
    set KEY_ATTR "key"

    # Initialize the array to return
    array set msg_catalog_array {}

    # Parse the xml document
    set tree [xml_parse -persist $catalog_file_contents]

    # Get the message catalog root node
    set root_node [xml_doc_get_first_node $tree]
    if { [xml_node_get_name $root_node] ne $MESSAGE_CATALOG_TAG } {
        error "lang::catalog_parse: Could not find root node $MESSAGE_CATALOG_TAG"
    }

    # Set the message catalog root level attributes
    set msg_catalog_array(package_key) [get_required_xml_attribute $root_node ${PACKAGE_KEY_ATTR}]
    set msg_catalog_array(locale) [get_required_xml_attribute $root_node ${LOCALE_ATTR}]
    set msg_catalog_array(charset) [get_required_xml_attribute $root_node ${CHARSET_ATTR}]

    # Loop over the keys and message texts
    set message_node_list [xml_node_get_children_by_name $root_node ${MESSAGE_TAG}]
    array set key_text_array {}
    foreach message_node $message_node_list {
        set key [get_required_xml_attribute $message_node ${KEY_ATTR}]
        set text [xml_node_get_content $message_node ]
        set key_text_array($key) $text
    }

    # Add the keys and the texts to the messages array
    set msg_catalog_array(messages) [array get key_text_array]

    # Loop over the keys and descriptions
    set description_node_list [xml_node_get_children_by_name $root_node ${DESCRIPTION_TAG}]
    array set key_description_array {}

    foreach description_node $description_node_list {
        set key [get_required_xml_attribute $description_node ${KEY_ATTR}]
        set description [xml_node_get_content $description_node ]
        set key_description_array($key) $description
    }

    # Add the keys and the texts to the descriptions array
    set msg_catalog_array(descriptions) [array get key_description_array]

    return [array get msg_catalog_array]
}

ad_proc -private lang::catalog::import_from_file { 
    file_path
} {
    <p>
    Import messages for a certain locale and package from a given XML 
    catalog file to the database. This procedure invokes lang::catalog::parse
    to read the catalog file and lang::message::register
    to register the messages with the system (updates database and cache).
    </p>

    <p>
    The import should be considered an upgrade if the package has had messages
    imported before. In this case the proc lang::catalog::import_messages will be used
    to register the new messages with the system and handle the upgrade logic (a merge
    with what's in the database).
    </p>

    @param file_path The absolute path of the XML file to import messages from.
                     The path must be on valid format, see apm_is_catalog_file

    @return An array list containing the number of messages processed, number of messages added, 
            number of messages updated, and the number of messages deleted by the import. The keys of the
            array list are processed, added, updated, and deleted.

    @see             lang::catalog::parse
    @see             lang::message::register
    @see             lang::catalog::import_messages
    
    @author          Peter Marklund
} {
    # Check arguments
    assert_catalog_file $file_path

    # Parse the catalog file and put the information in an array
    # LARS NOTE: Change parse to take three array-names, catalog, messages, descriptions, and use upvar
    array set catalog_array [parse [read_file $file_path]]

    # Extract package_key, locale, and charset from the file path
    array set filename_info [apm_parse_catalog_path $file_path]
    # Setting these variables to improve readability of code in this proc
    set package_key $filename_info(package_key)
    set locale $filename_info(locale)
    set charset $filename_info(charset)

    # Compare xml package_key with file path package_key - abort if there is a mismatch
    if { $package_key ne $catalog_array(package_key) } {
        error "the package_key $catalog_array(package_key) in the file $file_path does not match the package_key $package_key in the filesystem"
    }

    # Get the messages array, and the list of message keys to iterate over
    array set messages_array $catalog_array(messages)
    set messages_array_names [array names messages_array]

    # Get the descriptions array
    array set descriptions_array $catalog_array(descriptions)

    ns_log Notice "Loading messages in file $file_path"

    # Register messages
    array set message_count [lang::catalog::import_messages \
                                 -file_messages_list [array get messages_array] \
                                 -package_key $package_key \
                                 -locale $locale]

    # Register descriptions
    foreach message_key $messages_array_names {
        if { [info exists descriptions_array($message_key)] } {
            with_catch errmsg {
                lang::message::update_description \
                    -package_key $catalog_array(package_key) \
                    -message_key $message_key \
                    -description $descriptions_array($message_key)
            } {
                ns_log Error "Registering description for key ${package_key}.${message_key} in locale $locale failed with error message \"$errmsg\"\n\n$::errorInfo"
            }
        }    
    }

    return [array get message_count]
}

ad_proc -private lang::catalog::import_messages {
    {-file_messages_list:required}
    {-package_key:required}
    {-locale:required}
} {
    <p>
      Import a given set of messages from a catalog file to the database
      for a certain package and locale. If we already have messages in the db
      for the given package and locale then a merge
      between the database messages and the file messages will be performed. 
    </p>

    <p>
      Foreach message to import, the base
      messages for the merge is the messages in the db from the last time
      db and catalog file were in sync for the corresponding message key. The first such sync point
      is the initial import of a message. After that, any export of messages to
      the file system will be a sync point. Also, after an upgrade, a large number
      of the resulting messages in the db will be identical to those in the file (the
      file messages take precedence on conflict) and those messages will also be sync points.
      A message being in sync between db and file is indicated by the lang_message.sync_time
      column being set to a not null value.
    </p>

    <p>
      This proc is idempotent which means that it can be executed multiple times and after the first
      time it's been executed it won't have any effect on the db. <b>See the corresponding
      acs-automated-testing test case called upgrade.</b>
    </p>

    <p>
      What follows below is a description of the logic of the proc in terms of its input, the cases considered,
      and the logical actions taken for each case.
    </p>    

    <p>
    There are three sets of keys, file, db, and base keys. For each key in 
    the union of these keys there are three messages that can exist: the file message, the db message, and the base message. The
    base message serves as the base for the merge. We will distinguish all the different permutations
    of each of the three messages existing or not, and all permutations of the messages being different from eachother. 
    We don't distinguish how two messages are different, only whether they are different or not.
    In total that gives us 14 cases (permutations) to consider.
    </p>

    <pre>
    *** Exactly one of messages exists (3 cases):

    1. base message (deleted in file and db). upgrade_action=none, conflict_p=f

    2. db message (added in db). upgrade_action=none, conflict_p=f

    3. file message (added in file). upgrade_action=add, conflict_p=f

    *** Exactly two of the messages exist (6 cases):

    - Base and file message (db message deleted):
      4. Differ (conflicting change). upgrade_action=resurrect, conflict_p=t
      5. No difference (no conflicting change). upgrade_action=none, conflict_p=f

    - Base and db message (file message deleted):
      6. Differ (conflicting change): upgrade_action=delete, conflict_p=t
      7. No difference (no conflicting change): upgrade_action=delete, conflict_p=f

    - File and db message (message added in both db and file):
      8. Differ (conflicting change). upgrade_action=update, conflict_p=t
      9. No difference (identical changes). upgrade_action=none, conflict_p=f

    *** All three messages exist (5 cases):

    10. All the same. upgrade_action=none, conflict_p=f

    11. File and base the same. upgrade_action=none, conflict_p=f

    12. DB and base the same. upgrade_action=update, conflict_p=f

    13. File and DB the same. upgrade_action=none, conflict_p=f

    14. All different. upgrade_action=update, conflict_p=t
    </pre>

    @param file_messages_list An array list with message keys as keys and 
                              the message of those keys as values, 
                              i.e. (key, value, key, value, ...)

    @param package_key        The package_key for the messages.

    @param locale             The locale of the messages.

    @return An array list containing the number of messages processed, number of messages added, 
            number of messages updated, number of messages deleted by the import, and a list of errors produced. The keys of the
            array list are processed, added, updated, and deleted, and errors.

    @author Peter Marklund
    @author Lars Pind
} {
    set message_count(processed) 0
    set message_count(added) 0
    set message_count(updated) 0
    set message_count(deleted) 0
    set message_count(errors) [list]

    # Form arrays for all three sets of messages
    array set file_messages $file_messages_list
    array set db_messages [lang::catalog::messages_in_db \
                               -package_key $package_key \
                               -locale $locale]
    array set base_messages [lang::catalog::last_sync_messages \
                               -package_key $package_key \
                               -locale $locale]

    foreach arrname { base_messages file_messages db_messages } {
        set dummy [list]
        foreach elm [lsort [array names $arrname]] {
            lappend dummy "$elm=[set ${arrname}($elm)]"
        }
        ns_log Debug "lang::catalog::import_messages - $arrname: $dummy"
    }

    # Remember each time we've processed a key, so we don't process it twice
    array set message_key_processed_p [list]

    # Loop over the union of import and db keys. 
    foreach message_key [lsort [concat [array names db_messages] [array names file_messages] [array names base_messages]]] {
        if { [info exists message_key_processed_p($message_key)] } {
            continue
        }
        set message_key_processed_p($message_key) 1
        
        ###########################################
        #
        # Figure out how db and file messages have changed with regards to the base message
        #
        ###########################################

        # The variables indicate how the db and file messages have changed
        # from the base message. Valid values are: none, add, update, delete
        set db_change "none"
        set file_change "none"

        if { [info exists base_messages($message_key)] } {
            # The base message exists

            if { [info exists db_messages($message_key)] } {
                # db message exists
                if { $db_messages($message_key) ne $base_messages($message_key) } {
                    # db message and base message differ
                    set db_change "update"
                }
            } else {
                # db message does not exist
                set db_change "delete"
            }

            if { [info exists file_messages($message_key)] } {
                # file message exists
                if { $file_messages($message_key) ne $base_messages($message_key) } {
                    # file message and base message differ
                    set file_change "update"
                }
            } else {
                # file message does not exist
                set file_change "delete"
            }
        } else {
            # The base message does not exist

            if { [info exists db_messages($message_key)] } {
                # db message exists
                set db_change "add"
            }
            if { [info exists file_messages($message_key)] } {
                # file message exists
                set file_change "add"
            }
        }

        ###########################################
        #
        # Based on the change in file and db messages, 
        # and based on whether file and db messages differ, decide 
        # which upgrade actions to take
        #
        ###########################################

        # Default values cover the cases 2, 5, 9, 10, 11, 13
        set import_case "in 2, 5, 9, 10, 11, 13"
        set upgrade_status "no_upgrade"
        set conflict_p "f"

        switch $db_change {
            none {
                switch $file_change {
                    none {}
                    add {
                        # case 3
                        set import_case 3
                        # add message from file to db
                        set upgrade_status "added"
                    }
                    update {
                        # case 12
                        set import_case 12
                        # update db with file message
                        set upgrade_status "updated"
                    }
                    delete {
                        # case 7
                        set import_case 7
                        # mark message in db deleted
                        set upgrade_status "deleted"
                    }
                }
            }
            add {
                switch $file_change {
                    none {} 
                    add {
                        if { $db_messages($message_key) ne $file_messages($message_key) } {
                            # case 8
                            set import_case 8
                            # differing additions in db and file
                            set upgrade_status "updated"
                            set conflict_p "t"
                        }
                    }
                }            
            }
            update {
                switch $file_change {
                    none {}
                    update {
                        if { $db_messages($message_key) ne $file_messages($message_key) } {
                            # case 14
                            set import_case 14
                            # differing updates in file and db
                            set upgrade_status "updated"
                            set conflict_p "t"
                        }
                    }
                    delete {
                        # case 6
                        set import_case 6
                        # deletion in file but update in db
                        set upgrade_status "deleted"
                        set conflict_p "t"
                    }
                }           
            }
            delete {
                switch $file_change {
                    none {}
                    update {
                        # case 4
                        set import_case 4
                        # deletion in db but update in file
                        set upgrade_status "added" ;# resurrect
                        set conflict_p "t"
                    }
                    delete {
                        # case 1
                        set import_case 1
                        # deletion in both db and file                        
                        # no status change, no conflict
                        # sync time should be updated below
                    }
                }
            }
        }

        ###########################################
        #
        # Execute upgrade actions
        #
        ###########################################        

        # For certain messages we need to move the sync point so that we have a current base for the next upgrade. 
        if { $db_change eq "none" || $file_change ne "none" } {
            # If there is no db change then any change in the file will be reflected in 
            # db (file takes precedence) and file and db are identical. 
            # Also, regardless of what's happened in db, if
            # there has been a change in the file then that change will take effect in
            # the db and file and db are again identical (in sync).
            set update_sync_p 1
        } else {
            set update_sync_p 0
        }

        # Store a new message in the database if we are adding or updating
        set error_p 0
        if { $upgrade_status eq "added" || $upgrade_status eq "updated" } {

            ns_log Debug "lang::catalog::import_messages - invoking lang::message::register with import_case=\"$import_case\" -update_sync=$update_sync_p $message_key $upgrade_status $conflict_p"
            if { [catch {lang::message::register \
                -update_sync \
                -upgrade_status $upgrade_status \
                -conflict=$conflict_p \
                $locale \
                $package_key \
                $message_key \
                $file_messages($message_key)} errmsg] } {
                
                lappend message_count(errors) $errmsg
                set error_p 1
            }
        } elseif { $update_sync_p || $upgrade_status eq "deleted" } {
            # Set the upgrade_status, deleted_p, conflict_p, and sync_time properties of the message

            # If we are doing nothing, the only property of the message we might want to update in the db
            # is the sync_time as we might have discovered that db and file are in sync
            array unset edit_array
            if { $upgrade_status ne "no_upgrade" } {
                set edit_array(upgrade_status) $upgrade_status
                set edit_array(deleted_p) [string equal $upgrade_status "deleted"]
                set edit_array(conflict_p) $conflict_p
            }
            
            ns_log Debug "lang::catalog::import_messages - invoking lang::message::edit with import_case=\"$import_case\" -update_sync=$update_sync_p $message_key [array get edit_array]"
            if { [catch {lang::message::edit \
                -update_sync=$update_sync_p \
                $package_key \
                $message_key \
                $locale \
                [array get edit_array]} errmsg] } {

                lappend message_count(errors) $errmsg
                set error_p 1
            }
        } else {
            ns_log Debug "lang::catalog::import_messages - not doing anything: import_case=\"$import_case\" $message_key $upgrade_status $conflict_p"
        }

        if { $upgrade_status in {added updated deleted} } {
            if { ! $error_p } {
                incr message_count($upgrade_status)
            }
        } 
        incr message_count(processed)

    } ;# End of message key loop

    return [array get message_count]
}

ad_proc -public lang::catalog::import {
    {-package_key {}}
    {-locales {}}
    {-initialize:boolean}
    {-cache:boolean}
} {
    Import messages from catalog files to the database. By default all messages
    for enabled packages and enabled locales will be imported. Optionally, the import
    can be restricted to a certain package and/or a list of locales. Invokes the proc
    lang::catalog::import_messages that deals with multiple imports (upgrades).

    @param package_key Restrict the import to the package with this key
    @param locales     A list of locales to restrict the import to
    @param initialize  Only load messages from packages that have never before had any message imported
    @param cache       Provide this switch if you want the proc to cache all the imported messages

    @return An array list containing the number of messages processed, number of messages added, 
            number of messages updated, number of messages deleted by the import, and a list of errors produced. The keys of the
            array list are processed, added, updated, and deleted, and errors.

    @see lang::catalog::import_messages

    @author Peter Marklund
} {
    set message_count(processed) 0
    set message_count(added) 0
    set message_count(updated) 0
    set message_count(deleted) 0
    set message_count(errors) [list]

    if { $package_key ne "" } {
        set package_key_list $package_key
    } else {
        set package_key_list [apm_enabled_packages]
    }

    if { $initialize_p } {
        set uninitialized_packages [uninitialized_packages]
    }

    foreach package_key $package_key_list {
        if {$initialize_p && $package_key ni $uninitialized_packages} {
            # The package is already initialized
            continue
        }

        # Skip the package if it has no catalog files at all
        if { ![file exists [package_catalog_dir $package_key]] } {
            continue
        }

        set catalog_files [get_catalog_paths_for_import \
                               -package_key $package_key \
                               -locales $locales]

        # Issue a warning and exit if there are no catalog files
        if { $catalog_files eq "" } {
            ns_log Warning "No catalog files found for package $package_key in locales: $locales"
            continue
        }

        foreach file_path $catalog_files {
            # Use a catch so that parse failure of one file doesn't cause the import of all files to fail
            array unset loop_message_count
            if { [catch { array set loop_message_count [lang::catalog::import_from_file $file_path] } errMsg] } {
                
                ns_log Error "The import of file $file_path failed, error message is:\n\n${errMsg}\n\nstack trace:\n\n$::errorInfo\n\n"
            } else {
                foreach action [array names loop_message_count] {
                    if { $action ne "errors" } {
                        set message_count($action) [expr {$message_count($action) + $loop_message_count($action)}]
                    }
                }
                set message_count(errors) [concat $message_count(errors) $loop_message_count(errors)]
            }
        }
    }

    if { $cache_p } {
        lang::message::cache
    }

    return [array get message_count]
}

ad_proc -private lang::catalog::get_catalog_paths_for_import {
    {-package_key:required}
    {-locales {}}
} {
    Return a list of file paths for the catalog files of the given package. Can
    be restricted to only return files for certain locales. The list will
    be sorted in an order appropriate for import to the database.

    @param package_key The key of the package to get catalog file paths for
    @param locales     A list of locales to restrict the catalog files to

    @author Peter Marklund
} {
    # We always need to register en_US messages first as they create the keys
    set en_us_locale_list [list en_US]
    set other_locales_list [db_list locales {
        select locale
        from ad_locales
        where enabled_p = 't'
        and locale <> 'en_US'
    }]
    set locales_list [concat $en_us_locale_list $other_locales_list]

    # Get all catalog files for enabled locales
    set catalog_files [list]
    foreach locale $locales_list {        

        # If we are only processing certain locales and this is not one of them - continue
        if { [llength $locales] > 0 && $locale ni $locales } {
            continue
        }

        # If the package has no files in this locale - continue
        if { ![package_has_files_in_locale_p $package_key $locale] } {
            continue
        }

        set file_path [get_catalog_file_path \
                           -package_key $package_key \
                           -locale $locale]

        if { [file exists $file_path] } {
            lappend catalog_files $file_path
        } else {
            ns_log Error "Catalog file $file_path not found. Failed to import messages for package $package_key and locale $locale"
        }
    }

    return $catalog_files
}

##################
#
# Mischellaneous procs
#
##################

ad_proc -public lang::catalog::package_delete {
    {-package_key:required}
} {
    Unregister the I18N messages for the package.

    @author Peter Marklund
} {
    set message_key_list [db_list all_message_keys_for_package {
        select message_key
        from lang_message_keys
        where package_key = :package_key
    }]

    db_dml delete_package_keys {
        delete from lang_message_keys
        where package_key = :package_key
    }

    foreach message_key $message_key_list {
        lang::message::remove_from_cache $package_key $message_key
    }
}

##################
#
# Inactive and unmaintained procs
#
##################

ad_proc -private lang::catalog::translate {} {    
    Translates all untranslated strings in a message catalog
    from English into Spanish, French and German
    using Babelfish. NOTE: this proc is unmaintained. 
    Quick way to get a multilingual site up and
    running if you can live with the quality of the translations.
    <p>
    Not a good idea to run this procedure if you have
    a large message catalog. Use for testing purposes only.

    @author            John Lowry (lowry@arsdigita.com)

} {
    set default_locale [parameter::get -package_id [apm_package_id_from_key acs-lang] -parameter SiteWideLocale]
    db_foreach get_untranslated_messages {} {    
        foreach lang [list es_ES fr_FR de_DE] {
            if {[catch {
                set translated_message [lang_babel_translate $message en_$lang]
            } errmsg]} {
                ns_log Notice "Error translating $message into $lang: $errmsg"
            } else {
                lang::message::register $lang $package_key $message_key $translated_message
            }
        }
    }                 
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
