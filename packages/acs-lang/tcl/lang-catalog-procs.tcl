#/packages/acs-lang/tcl/lang-catalog-procs.tcl
ad_library {

    <p>
    Routines for importing/exporting messages from/to XML message
    catalog files. The key procedures in this library are
    </p>

    <ul>
      <li><code>lang::catalog::export_messages_to_file - Export messages for a certain locale
          and package from the database to a given XML catalog file.</li>
      <li><code>lang::catalog::import_messages_from_file</code> - Import messages for a certain
          locale and package from a given XML catalog file to the database.</li>
    </ul>

    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html
    </p>

    @creation-date 10 September 2000
    @author Jeff Davis (davis@arsdigita.com)
    @author Peter Marklund (peter@collaboraid.biz)
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval lang::catalog {}



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

    ns_log Notice "lang::catalog::read_file reading $catalog_filename in $msg_encoding"
    set in [open $catalog_filename]
    fconfigure $in -encoding [ns_encodingforcharset $msg_encoding]
    set catalog_file_contents [read $in]        
    close $in                         

    return $catalog_file_contents
}

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
        ns_log Warning [list lang::catalog::default_charset_if_unsupported - charset $charset \
                        not supported by tcl, assuming $default_charset]
        set charset_to_use $default_charset
    } else {
        set charset_to_use $charset
    }

    return $charset_to_use
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

 ad_proc -public lang::catalog::export_to_files {
     {-locales ""}
 } {
     Export messages to catalog files for all enabled packages on the system.

     @param locales The locales to export. Defaults to all enabled locales that
                   a package has messages for in the database.

     @see lang::catalog::export_package_to_files
     
     @author Peter Marklund
 } {
     foreach package_key [apm_enabled_packages] {
             lang::catalog::export_package_to_files -locales $locales $package_key
     }     
 }

 ad_proc -public lang::catalog::export_package_to_files { 
     {-locales ""}
     package_key 
} {
     Export all messages of the given package from the database to xml
     catalog files. The messages for each locale are stored in its own file.
     The catalog files are stored in the
     directory /packages/package_key/catalog with a filename on the format
     package_key.locale.charset.xml (i.e. dotlrn.en_US.iso-8859-1.xml).

    @param locales The locales to export. Defaults to all enabled locales that
                   the package has messages for in the database.

     @author Peter Marklund (peter@collaboraid.biz)
 } {
     # Loop over all locales that the package has messages in
     # and write a catalog file for each such locale
     db_foreach get_locales_for_package {} {
         # If we are only exporting certain locales and this is not one of them - continue
         if { ![empty_string_p $locales] && [lsearch -exact $locales $locale] == -1 } {
             continue
         }

         set charset [ad_locale charset $locale]

         # Get all messages in the current locale and put them in an array list
         set messages_list [list]
         set descriptions_list [list]
         all_messages_for_package_and_locale $package_key $locale
         template::util::multirow_foreach all_messages {
             lappend messages_list @all_messages.message_key@ @all_messages.message@
             lappend descriptions_list @all_messages.message_key@ @all_messages.description@
         }

         # Write the messages and descriptions to the file
         set catalog_file_path [get_catalog_file_path \
                 -package_key $package_key \
                 -locale $locale]
         
         export_messages_to_file -descriptions_list $descriptions_list \
             $catalog_file_path $messages_list
     } 
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
            ns_log Warning "lang::catalog::is_upgrade_backup_file - The file $file_path has unknown prefix $prefix"
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

ad_proc -public lang::catalog::export_messages_to_file { 
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

    # Create a backup file first if there isn't one already
    set backup_path "${file_path}.orig"
    if { [file exists $file_path] && ![file exists $backup_path] } {
        ns_log Notice "Backing up catalog file $file_path"
        file copy -- $file_path $backup_path
    } else {
        ns_log Notice "Not backing up $file_path as backup file already exists"
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

   ns_log Notice "Wrote $message_count messages to file $file_path with encoding $file_encoding"
}

ad_proc -private lang::catalog::get_catalog_files { package_key } {
    Return the full paths of the message catalog files of the given package.

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

ad_proc -public lang::catalog::import_messages_from_file { 
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
        error "lang::catalog::import_messages_from_file - the package_key $catalog_array(package_key) in the file $file_path does not match the package_key $package_key in the filesystem"
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
    ns_log Notice "Loading messages in file $file_path [ad_decode $upgrade_p 0 "" ", upgrading"]"

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
                ns_log Notice "Marking message $message_key in locale $locale as deleted"
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

        if { [info exists descriptions_array($message_key)] } {
            lang::message::update_description \
                -package_key $catalog_array(package_key) \
                -message_key $message_key \
                -description $descriptions_array($message_key)
        }

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
    }       

    # Save any messages overwritten in database
    if { $upgrade_p && [array size overwritten_db_messages] > 0 } {
        set system_package_version [system_package_version_name $package_key]
        # Note that export_messages_to_file demands a certain filename format

        ns_log Notice "Saving overwritten messages during upgrade for package $package_key and locale $locale in file $filename"
        set file_path [get_catalog_file_path \
                -backup_from_version ${system_package_version} \
                -backup_to_version $catalog_array(package_version) \
                -package_key $package_key \
                -locale $locale]
        export_messages_to_file $file_path [array get overwritten_db_messages]
    }
}

ad_proc -private lang::catalog::system_package_version_name { package_key } {
    Returns the version name of the highest version of the given
    package_key in the system.
} {
    return [db_string get_version_name {}]
}

ad_proc -public lang::catalog::import_from_files_for_locale { locale } {
    Import messages for the given locale from catalog files in all enabled packages.

    @author Peter Marklund
} {
    if { [lsearch [lang::system::get_locales] $locale] == -1 } {
        error "lang::catalog::import_locale_from_files: Cannot import messages from files for locale $locale as it is not among the enabled locales ([lang::system::get_locales])"
    }

    foreach package_key [apm_enabled_packages] {
        # Skip the package if it has no catalog files at all
        if { ![file exists [package_catalog_dir $package_key]] } {
            continue
        }

        import_from_files -restrict_to_locale $locale $package_key
    }
}

ad_proc -public lang::catalog::import_from_files { 
    {-restrict_to_locale ""}
    package_key 
} {
    Import (load) all catalog files of a certain package. Catalog files
    should be stored in the /packages/package_key/catalog directory
    and have the ending .xml (i.e. /package/dotlrn/catalog/dotlrn.en_US.iso-8859-1.xml).
    This procedure invokes lang::catalog::import_messages_from_file.

    @param package_key The package key of the package to import catalog files for
    @param restrict_to_locale Restrict importing to catalog files of the given locale

    @author Peter Marklund (peter@collaboraid.biz)
} {
    # Check arguments
    if { [empty_string_p $package_key] } {
        error "lang::catalog::import_from_files - the package_key argument is the empty string"
    }

    # Skip the package if it has no catalog files at all
    if { ![file exists [package_catalog_dir $package_key]] } {
        ns_log Notice "importing nothing as package $package_key has no catalog files"
        return
    }

    # We always need to register en_US messages first as they create the keys
    set en_us_locale_list [list [list en_US [ad_locale charset en_US]]]
    set other_locales_list [db_list_of_lists locales_and_charsets {
        select locale,
               mime_charset
        from ad_locales
        where enabled_p = 't'
        and locale <> 'en_US'
    }]
    set all_locales_list [concat $en_us_locale_list $other_locales_list]

    # Get all catalog files for enabled locales
    set catalog_file_list [list]
    foreach locale_list $all_locales_list {        
        set locale [lindex $locale_list 0]
        set mime_charset [lindex $locale_list 1]

        # If we are only processing certain locales and this is not one of them - continue
        if { ![empty_string_p $restrict_to_locale] && ![string equal $restrict_to_locale $locale]} {
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
            lappend catalog_file_list $file_path
        } else {
            if { ![string equal $charset $mime_charset] } {
                # File doesn't exist, but charset was unsupported and defaulted to something else (probably utf-8)
                # For backward compatibility we check if the catalog has the mime charset in the filename even if it's
                # unsupported
                set alternate_file_path [get_catalog_file_path \
                        -package_key $package_key \
                        -locale $locale \
                        -charset $mime_charset]

                if { [file exists $alternate_file_path] } {
                    lappend catalog_file_list $alternate_file_path
                } else {
                    set error_text "lang::catalog::import_from_files - No catalog file found for locale $locale and charset ${mime_charset}. Attempted both path $file_path and $alternate_file_path"
                    if { ![string equal $charset $mime_charset] } {
                        append error_text " (defaulted to $charset as $mime_charset is unsupported)"
                    }               
                    ns_log Error $error_text
                }
            } else {
                # The file doesn't exist and we have no alternate charset to attempt - fail
                ns_log Error "lang::catalog::import_from_files - No catalog file found for locale $locale and charset ${mime_charset}. Attempted path $file_path"
            }
        }
    }

    # Issue a warning and exit if there are no catalog files
    if { [empty_string_p $catalog_file_list] } {
        ns_log Warning "lang::catalog::import_from_files - No catalog files found for package $package_key"
        return
    }

    # Loop over each catalog file
    foreach file_path $catalog_file_list {

        # First make sure this is really a message catalog file and not some other xml file in the catalog
        # directory like a file with saved messages from an upgrade
        if { ![apm_is_catalog_file $file_path] } {
            # If this doesn't seem to be a file with saved messages from a backup - issue a warning as
            # it might be a catalog file on invalid format (for example because of misspelling)
            if { ![is_upgrade_backup_file $file_path] } {
                ns_log Warning "lang::catalog::import_from_files File $file_path is not on valid message catalog format and is therefore ignored"
            }                

            continue
        }

        # Use a catch so that parse failure of one file doesn't cause the import of all files to fail
        if { [catch {import_messages_from_file $file_path} errMsg] } {
            global errorInfo
            
            ns_log Error "lang::catalog::import_from_files - The import of file $file_path failed, error message is:\n\n${errMsg}\n\nstack trace:\n\n$errorInfo\n\n"
        }
    }
}

ad_proc -public -deprecated -warn lang::catalog::import_from_tcl_files {
    {package_key "acs-lang"} 
} { 
    Import catalog files by evaluating tcl files containing 
    invocations of the _mr register procedure. Catalog files
    should be stored in the /packages/package_key/catalog directory
    and have the ending .cat (i.e. /package/dotlrn/catalog/dotlrn.en_US.iso-8859-1.cat).
    This procedure is depreceted and has been superseeded by the procedure
    lang::catalog::import_from_files that imports catalog files on xml syntax.

    @author Jeff Davis
    @author Peter Marklund (peter@collaboraid.biz)
    @return Number of files loaded

    @see lang::catalog::import_from_files

} { 
    set glob_pattern [file join [acs_package_root_dir $package_key] catalog *.cat]
    ns_log Notice "Starting load of the message catalogs $glob_pattern"
    
    global __lang_catalog_load_package_key
    set __lang_catalog_load_package_key $package_key

    set files [glob -nocomplain $glob_pattern]
    
    if {[empty_string_p $files]} { 
        ns_log Warning "no files found in message catalog directory"
    } else { 
        foreach msg_file $files { 

            set src [read_file $msg_file]

            if {[catch {eval $src} errMsg]} { 
                ns_log Warning "Failed loading message catalog $msg_file:\n$errMsg"
            }
        }
    }

    ns_log Notice "Finished load of the message catalog" 
    
    unset __lang_catalog_load_package_key 

    return $files
}
    
ad_proc -public lang::catalog::import_from_all_files_and_cache {} {
    Loops over all installed and enabled packages that don't already have messages in the database
    and imports messages from the catalog files of each such package. When this process is done
    the message cache is reloaded. The proc checks if it has been executed before and will
    only execute once.

    @author Peter Marklund (peter@collaboraid.biz)
} {
    # Only execute this proc once
    if { ![nsv_exists lang_catalog_import_from_all_files_and_cache executed_p] } {            
        nsv_set lang_catalog_import_from_all_files_and_cache executed_p 1

        db_foreach all_enabled_not_loaded_packages {} {
            if { [file isdirectory [file join [acs_package_root_dir $package_key] catalog]] } {
                lang::catalog::import_from_files $package_key
            }
        }

        lang::message::cache
    }
}

ad_proc -private lang::catalog::translate {} {
    Translates all untranslated strings in a message catalog
    from English into Spanish, French and German
    using Babelfish. Quick way to get a multilingual site up and
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
                ns_log Notice "Error translating $message into $lang: $errmsg"
            } else {
                lang::message::register $lang $package_key $message_key $translated_message
            }
        }
    }                 
}


#####
#
# Backwards compatibility procs
#
#####

ad_proc -deprecated -warn lang_catalog_load_all {} {
    @see lang::catalog::import_from_all_files
} {
    return [lang::catalog::import_from_all_files]
}
    
ad_proc -deprecated -warn lang_catalog_load {
    {package_key "acs-lang"} 
} {
    @see lang::catalog::import_from_files
} {
    return [lang::catalog::import_from_files $package_key]
}

ad_proc -deprecated -warn lang_translate_message_catalog {} {
    Translates all untranslated strings in a message catalog
    from English into Spanish, French and German
    using Babelfish. Quick way to get a multilingual site up and
    running if you can live with the quality of the translations.
    <p>
    Not a good idea to run this procedure if you have
    a large message catalog. Use for testing purposes only.

    @author            John Lowry (lowry@arsdigita.com)

    @see lang::catalog::translate
} {
    return [lang::catalog::translate]
}
