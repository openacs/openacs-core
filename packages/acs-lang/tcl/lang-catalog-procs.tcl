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
        ns_log Warning "lang::catalog::default_charset_if_unsupported: charset $charset not supported by tcl, assuming $default_charset"
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

    if { [empty_string_p $value] } {
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
    db_multirow -local -upvar_level 2 all_messages get_messages {}
}
    
ad_proc -private lang::catalog::package_catalog_dir { package_key } {
    Return the catalog directory of the given package.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 18 October 2002
} {
    return "[acs_package_root_dir $package_key]/catalog"
}

ad_proc -public lang::catalog::is_upgrade_backup_file { file_path } {
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
            ns_log Warning "lang::catalog::is_upgrade_backup_file: The file $file_path has unknown prefix $prefix"
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

    if { ![empty_string_p $charset] } {
        set file_charset $charset
    } else {
        # We had problems storing digits in ISO-8859-6 so we decided
        # to use UTF-8 for all files except for locales that use ISO-8859-1. The reason we are making
        # ISO-8859-1 an exception is that some developers may make the shortcut of editing
        # the en_US catalog files directly to add keys and they might mess up the
        # utf-8 encoding of the files when doing so.
        set system_charset [ad_locale charset $locale]
        set file_charset [ad_decode $system_charset "ISO-8859-1" $system_charset utf-8]
    }

    set message_backup_prefix ""
    if { ![empty_string_p $backup_from_version] } {
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

ad_proc -public lang::catalog::reset_upgrade_status_message_keys { package_key } {
    Before a package upgrade the upgrade status of message keys is cleared
    so that upgrade status always reflects the last upgrade.

    @author Peter Marklund
} {
    db_dml reset_status {}
}

ad_proc -private lang::catalog::system_package_version_name { package_key } {
    Returns the version name of the highest version of the given
    package_key in the system.
} {
    return [db_string get_version_name {}]
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
        ns_log Notice "lang::catalog::export_to_file: Creating new catalog directory $catalog_dir"
        file mkdir $catalog_dir
    }

    # Create a backup file first if there isn't one already
    set backup_path "${file_path}.orig"
    if { [file exists $file_path] && ![file exists $backup_path] } {
        ns_log Notice "Backing up catalog file $file_path"
        file copy -- $file_path $backup_path
    } else {
        ns_log Notice "lang::catalog::export_to_file: Not backing up $file_path as backup file already exists"
    }

    # Since the output charset, and thus the filename, may have changed since
    # last time that we wrote the catalog file we remove old files with the same locale
    foreach old_catalog_file [get_catalog_files $filename_info(package_key)] {
        # Parse locale from filename
        array set old_filename_info [apm_parse_catalog_path $old_catalog_file]

        if { [string equal $old_filename_info(locale) $filename_info(locale)] } {
            file delete $old_catalog_file
        }
    }

    # Open the catalog file for writing, truncate if it exists
    set file_encoding [ns_encodingforcharset [default_charset_if_unsupported $filename_info(charset)]]

    set catalog_file_id [open $file_path w]
    fconfigure $catalog_file_id -encoding $file_encoding

    # Open the root node of the document
    set package_version [system_package_version_name $filename_info(package_key)]
    puts $catalog_file_id "<?xml version=\"1.0\" encoding=\"$filename_info(charset)\"?>
<message_catalog package_key=\"$filename_info(package_key)\" package_version=\"$package_version\" locale=\"$filename_info(locale)\" charset=\"$filename_info(charset)\">
"

   # Loop over and write the messages to the file
   set message_count "0"
   foreach message_key $message_key_list {
       puts $catalog_file_id "  <msg key=\"[ad_quotehtml $message_key]\">[ad_quotehtml $messages_array($message_key)]</msg>"
       if { [exists_and_not_null descriptions_array($message_key)] && $filename_info(locale) == "en_US" } {
           puts $catalog_file_id "  <description key=\"[ad_quotehtml $message_key]\">[ad_quotehtml $descriptions_array($message_key)]</description>\n"
       }
       incr message_count
   }

   # Close the root node and close the file
   puts $catalog_file_id "</message_catalog>"
   close $catalog_file_id       

   ns_log Notice "lang::catalog::export_to_file: Wrote $message_count messages to file $file_path with encoding $file_encoding"
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
    if { ![empty_string_p $package_key] } {
        set package_key_list $package_key
    } else {
        set package_key_list [apm_enabled_packages]
    }

    foreach package_key $package_key_list {
        # Loop over all locales that the package has messages in
        # and write a catalog file for each such locale
        db_foreach get_locales_for_package {} {
            # If we are only exporting certain locales and this is not one of them - continue
            if { [llength $locales] > 0 && [lsearch -exact $locales $locale] == -1 } {
                continue
            }

            # Get messages and descriptions for the locale
            set messages_list [list]
            set descriptions_list [list]
            all_messages_for_package_and_locale $package_key $locale
            template::util::multirow_foreach all_messages {
                lappend messages_list @all_messages.message_key@ @all_messages.message@
                lappend descriptions_list @all_messages.message_key@ @all_messages.description@
            }

            set catalog_file_path [get_catalog_file_path \
                                       -package_key $package_key \
                                       -locale $locale]

            export_to_file -descriptions_list $descriptions_list $catalog_file_path $messages_list
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
        ns_log Warning "lang::catalog::read_file: Charset info missing in filename assuming $catalog_filename is iso-8859-1" 
        set msg_encoding iso-8859-1
    }
    
    set msg_encoding [default_charset_if_unsupported $msg_encoding]

    ns_log Notice "lang::catalog::read_file: reading $catalog_filename in $msg_encoding"
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
      package_version
      locale
      charset
      messages    - An array with message keys as keys and the message texts as values.
      descriptions - An array with message keys as keys and the descriptions as values.
    </pre>

    @author Peter Marklund (peter@collaboraid.biz)
    @author Simon Carstensen (simon@collaboraid.biz)
} {      

    # Check arguments
    if { [empty_string_p $catalog_file_contents] } {
        error "lang::catalog::parse the catalog_file_contents arguments is the empty string"
    }

    # The names of xml tags and attributes
    set MESSAGE_CATALOG_TAG "message_catalog"
    set PACKAGE_KEY_ATTR "package_key"
    set PACKAGE_VERSION_ATTR "package_version"
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
    if { ![string equal [xml_node_get_name $root_node] ${MESSAGE_CATALOG_TAG}] } {
        error "lang::catalog_parse: Could not find root node ${MESSAGE_CATALOG_TAG}"
    }

    # Set the message catalog root level attributes
    set msg_catalog_array(package_key) [get_required_xml_attribute $root_node ${PACKAGE_KEY_ATTR}]
    set msg_catalog_array(package_version) [get_required_xml_attribute $root_node ${PACKAGE_VERSION_ATTR}]
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
    To determine if the import is a message catalog upgrade the package
    version of the catalog file will be compared with the highest package version
    currently in the system (in the database). If the package version in the
    catalog file deviates from what is in the system then the import is considered an upgrade.
    </p>

    <p>
    For upgrades, changed messages will have their old values (the ones in the
    database that are overwritten) backed up to a file with a name on a format along the lines of
    overwritten_messages_upgrade.<old-version>-<new-version>.<package_key>.<locale>.<charset>.xml
    The upgrade status of message keys and messages will be updated during an upgrade.
    Also during package upgrades, before invoking this procedure for the catalog files of a package the upgrade 
    status of message keys should be cleared with the proc 
    lang::catalog::reset_upgrade_status_message_keys
    </p>

    @param file_path The absolute path of the XML file to import messages from.
                     The path must be on valid format, see apm_is_catalog_file

    @see             lang::catalog::parse
    @see             lang::message::register
    
    @author          Peter Marklund
} {
    # Check arguments
    assert_catalog_file $file_path

    # Parse the catalog file and put the information in an array
    array set catalog_array [parse [read_file $file_path]]

    # Extract package_key, locale, and charset from the file path
    array set filename_info [apm_parse_catalog_path $file_path]
    # Setting these variables to improve readability of code in this proc
    set package_key $filename_info(package_key)
    set locale $filename_info(locale)
    set charset $filename_info(charset)

    # Compare xml package_key with file path package_key - abort if there is a mismatch
    if { ![string equal $package_key $catalog_array(package_key)] } {
        error "the package_key $catalog_array(package_key) in the file $file_path does not match the package_key $package_key in the filesystem"
    }

    # Figure out if we are upgrading
    if { ![apm_package_installed_p $package_key] } {
        # The package is not installed so we are not upgrading
        set upgrade_p 0
    } else {
        # The package is installed so this is probably an upgrade 
        set higher_version_p [apm_higher_version_installed_p $package_key $catalog_array(package_version)]
        # higher_version_p value < 0 means downgrade, value 0 means versions are same, 1 is an upgrade
        # A package downgrade could be considered a form of upgrade. However, in practice versions
        # of the catalog files are sometimes not keeping up with the version in the info file and we don't
        # want that to trigger an upgrade.
        set upgrade_p [ad_decode $higher_version_p 1 1 0]
    }
    ns_log Notice "lang::catalog::import_from_file: Loading messages in file $file_path [ad_decode $upgrade_p 0 "" ", upgrading"]"

    # Get the messages array, and the list of message keys to iterate over
    array set messages_array [lindex [array get catalog_array messages] 1]
    set messages_array_names [array names messages_array]

    # Get the descriptions array
    array set descriptions_array [lindex [array get catalog_array descriptions] 1]

    if { $upgrade_p } {
        # clear out any old upgrade status of messages
        db_dml reset_upgrade_status_messages {}

        # Mark any messages that are in the system but not in the
        # catalog file as deleted
        all_messages_for_package_and_locale $package_key $locale           
        template::util::multirow_foreach all_messages {
            set message_key @all_messages.message_key@
            if { [lsearch -exact $messages_array_names $message_key] < 0 } {
                ns_log Notice "lang::catalog::import_from_file: Marking message $message_key in locale $locale as deleted"
                db_dml mark_message_as_deleted {}

                # One approach to deleted message keys after upgrade is to consider those
                # keys deleted whose messages in all locales have an upgrade status
                # of deleted in the lang_messages table.
                # However in the somewhat unusual case where the package we are upgrading
                # to doesn't have all locales that the old package version does, upgrade
                # status won't be set to deleted for all locales. 
                # The workable solution seems to be to consider a key as deleted if its
                # en_US message has the deleted upgrade status.
                if { [string equal $locale "en_US"] } {
                    db_dml mark_message_key_as_deleted {}
                }
            }
        }
    }       

    # Loop over and register the messages
    array set overwritten_db_messages {}
    foreach message_key $messages_array_names {
        set qualified_key "$package_key.$message_key"
        set new_message $messages_array($message_key)

        # Failing to register one message should not cause the whole file import to fail
        with_catch errmsg {
            # If this is an upgrade - save old message if it will be overwritten
            if { $upgrade_p } {
                # Check if the message existed previously
                if { [lang::message::message_exists_p $locale $qualified_key] } {
                    # Check if message is updated, avoid variable substitution during lookup by setting upvar_level to 0
                    set old_message [lang::message::lookup $locale $qualified_key {} {} 0]
                    if { ![string equal $old_message $new_message] } {
                        set overwritten_db_messages($message_key) $old_message
                    }
                }
            }    

            # Register the new message with the system
            lang::message::register \
                    -upgrade=$upgrade_p \
                    $catalog_array(locale) \
                    $catalog_array(package_key) \
                    $message_key \
                    $new_message

            if { [info exists descriptions_array($message_key)] } {
                lang::message::update_description \
                    -package_key $catalog_array(package_key) \
                    -message_key $message_key \
                    -description $descriptions_array($message_key)
            }    
        } {
            global errorInfo
            ns_log Error "Registering message for key $qualified_key in locale $locale failed with error message \"$errmsg\"\n\n$errorInfo"
        }
    }       

    # Save any messages overwritten in database
    if { $upgrade_p && [array size overwritten_db_messages] > 0 } {
        set system_package_version [system_package_version_name $package_key]
        # Note that export_messages_to_file demands a certain filename format

        ns_log Notice "lang::catalog::import_from_file: Saving overwritten messages during upgrade for package $package_key and locale $locale in file $filename"
        set file_path [get_catalog_file_path \
                -backup_from_version ${system_package_version} \
                -backup_to_version $catalog_array(package_version) \
                -package_key $package_key \
                -locale $locale]
        export_messages_to_file $file_path [array get overwritten_db_messages]
    }
}

ad_proc -public lang::catalog::import {
    {-package_key {}}
    {-locales {}}
    {-initialize:boolean}
    {-cache:boolean}
} {
    Import messages from catalog files to the database. By default all messages
    for enabled packages and enabled locales will be imported. Optionally, the import
    can be restricted to a certain package and/or a list of locales.

    @param package_key Restrict the import to the package with this key
    @param locales     A list of locales to restrict the import to
    @param initialize  Only load messages from packages that have never before had any message imported
    @param cache       Provide this switch if you want the proc to cache all the imported messages

    @author Peter Marklund
} {
    if { ![empty_string_p $package_key] } {
        set package_key_list $package_key
    } else {
        set package_key_list [apm_enabled_packages]
    }

    if { $initialize_p } {
        set uninitialized_packages [db_list select_uninitialized {}]
    }

    foreach package_key $package_key_list {
        if {$initialize_p && [lsearch -exact $uninitialized_packages $package_key] == -1} {
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
        if { [empty_string_p $catalog_files] } {
            ns_log Warning "lang::catalog::import: No catalog files found for package $package_key"
            continue
        }

        foreach file_path $catalog_files {
            # Use a catch so that parse failure of one file doesn't cause the import of all files to fail
            if { [catch {import_from_file $file_path} errMsg] } {
                global errorInfo
                
                ns_log Error "lang::catalog::import: The import of file $file_path failed, error message is:\n\n${errMsg}\n\nstack trace:\n\n$errorInfo\n\n"
            }
        }        
    }

    if { $cache_p } {
        lang::message::cache
    }
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
        if { [llength $locales] > 0 && [lsearch -exact $locales $locale] == -1 } {
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
            ns_log Error "lang::catalog::get_catalog_paths_for_import: Catalog file $file_path not found. Failed to import messages for package $package_key and locale $locale"
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
            if [catch {
                set translated_message [lang_babel_translate $message en_$lang]
            } errmsg] {
                ns_log Notice "lang::catalog::translate: Error translating $message into $lang: $errmsg"
            } else {
                lang::message::register $lang $package_key $message_key $translated_message
            }
        }
    }                 
}
