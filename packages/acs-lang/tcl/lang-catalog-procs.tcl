#/packages/acs-lang/tcl/lang-catalog-procs.tcl
ad_library {

    Routines for importing (loading) message catalog files 
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

namespace eval lang::catalog {

    ad_proc -private read_file { catalog_filename } {
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

    ad_proc -private default_charset_if_unsupported { charset } {
        Will return the system default charset and issue a warning in the log
        file if the given charset is not supported by tcl. Otherwise
        the given charset is simply returned.        

        @author Jeff Davis
        @author Peter Marklund (peter@collaboraid.biz)
    } {
        set ns_charsets [ns_charsets]
        # Do case insensitive matching
        if {[lsearch -regexp $ns_charsets "(?i)^${charset}\$"] < 0} { 
            set default_charset [encoding system] 
            ns_log Warning [list lang::catalog::default_charset_if_unsupported - charset $charset \
                            not supported by tcl, assuming $default_charset]
            set charset_to_use $default_charset
        } else {
            set charset_to_use $charset
        }

        return $charset_to_use
    }

    ad_proc -private parse { catalog_file_contents } {
        Parse the given catalog file xml contents and return the data as
        an array. The array will contain the following keys:

        <pre>
          package_key
          locale
          charset
          messages    - An array with message keys as keys and the message texts as values.
        </pre>

        @author Peter Marklund (peter@collaboraid.biz)
    } {      
        # Check arguments
        if { [empty_string_p $catalog_file_contents] } {
            error "lang::catalog::parse the catalog_file_contents arguments is the empty string"
        }

        # The names of xml tags and attributes
        set MESSAGE_CATALOG_TAG "message_catalog"
        set PACKAGE_KEY_ATTR "package_key"
        set LOCALE_ATTR "locale"
        set CHARSET_ATTR "charset"
        set MESSAGE_TAG "msg"
        set KEY_ATTR "key"

        # Initialize the array to return
        array set msg_catalog_array {}

        # An ns_xml bug workaround, may not be necessary still but won't do any harm
        set xml_data [xml_prepare_data $catalog_file_contents]

        # Parse the xml document with ns_xml
        set tree [xml_parse $xml_data]

        # Get the message catalog root node
        set root_node [xml_doc_get_first_node_by_name $tree ${MESSAGE_CATALOG_TAG}]
        if { [empty_string_p $root_node] } {
            error "lang::catalog_parse: Could not find root node ${MESSAGE_CATALOG_TAG}"
        }

        # Set the message catalog root level attributes
        set msg_catalog_array(package_key) [get_required_xml_attribute $root_node ${PACKAGE_KEY_ATTR}]
        set msg_catalog_array(locale) [get_required_xml_attribute $root_node ${LOCALE_ATTR}]
        set msg_catalog_array(charset) [get_required_xml_attribute $root_node ${CHARSET_ATTR}]

        # Loop over the keys and texts
        set message_node_list [xml_node_get_children_by_name $root_node ${MESSAGE_TAG}]
        array set key_text_array {}
        foreach message_node $message_node_list {
            set key [get_required_xml_attribute $message_node ${KEY_ATTR}]
            set text [get_required_xml_content $message_node]
            set key_text_array($key) $text
        }        

        # Add the keys and the texts to the array
        set msg_catalog_array(messages) [array get key_text_array]

        return [array get msg_catalog_array]
    }

    ad_proc -private get_required_xml_attribute { element attribute } {
        Return the value of the given attribute and raise an error if the
        value is missing or empty.

        @author Peter Marklund (peter@collaboraid.biz)
    } {
        set value [xml_node_get_attribute $element $attribute]

        if { [empty_string_p $value] } {
            error "Required attribute \"$attribute\" missing from <[dom::node cget $element -nodeName]>"
        }

        return $value
    }

    ad_proc -private get_required_xml_content { element } {
        Get the content of the given element and raise an error
        if the content is empty.

        @author Peter Marklund (peter@collaboraid.biz)
    } {
        set content [xml_node_get_content $element]

        if { [empty_string_p $content] } {
            error "Required content missing from element <[dom::node cget $element -nodeName]>"
        }

        return $content
    }

    ad_proc -public export_package_to_files { package_key } {
        Export all messages of the given package from the database to xml
        catalog files. The messages for each locale are stored in its own file.
        The catalog files are stored in the
        directory /packages/package_key/catalog with a filename on the format
        package_key.locale.charset.xml (i.e. dotlrn.en_US.iso-8859-1.xml).

        @author Peter Marklund (peter@collaboraid.biz)
    } {
        # Loop over all locales that the package has messages in
        # and write a catalog file for each such locale
        db_foreach get_locales_for_package {} {
            set charset [ad_locale charset $locale]

           # Get all messages in the current locale and put them in an array list
           set messages_list [list]
           db_foreach get_messages {} {
               lappend messages_list $message_key $message
           }

           # Write the messages to the file
           set catalog_file_name "[package_catalog_dir $package_key]/${package_key}.${locale}.${charset}.xml"
           export_messages_to_file $catalog_file_name $messages_list
       } 
   }

   ad_proc -private package_catalog_dir { package_key } {
       Return the catalog directory of the given package.

       @author Peter Marklund (peter@collaboraid.biz)
       @creation-date 18 October 2002
   } {
       return "[acs_package_root_dir $package_key]/catalog"
   }

   ad_proc -public export_messages_to_file { file_path messages_list } {

       Export messages in a certain locale to the given file in xml format. 
       If the catalog file already exists it will be backed up to a file with the
       same name but the extension .orig added to it. If there is an old backup
       file no new backup is done.
       
       @param file_path The path of the xml file to write the messages to.
                        Package key, locale, and charset must be encoded
                        in the name of the file on the format
                        package_key.locale.charset.xml. The
                        file and the catalog directory will be created if they don't exist.

       @param message_list A list with message keys on even indices followed by
                           corresponding messages on odd indices.

       @author Peter Marklund (peter@collaboraid.biz)
   } {
       # Put the messages in an array so it's easier to access them
       array set messages_array $messages_list
       set message_key_list [array names messages_array]

       # Extract package_key, locale, and charset from the file path
       if { ![regexp {(?i)([^/]+)\.([a-z]{2}_[a-z]{2})\.(.*)\.xml$} $file_path match package_key locale charset] } {
           error "lang::catalog::export_messages_to_file - Cannot extract package_key, locale, and charset from file path $file_path"
       }

       # Create the catalog directory if it doesn't exist
       set catalog_dir [package_catalog_dir $package_key]
       if { ![file isdirectory $catalog_dir] } {
           ns_log Notice "lang::catalog::export_messages_to_file - Creating new catalog directory $catalog_dir"
           file mkdir $catalog_dir
       }

       # Create a backup file first if there isn't one already
       set backup_path "${file_path}.orig"
       if { [file exists $file_path] && ![file exists $backup_path] } {
           ns_log Notice "lang::catalog::export_package_to_files - Backing up catalog file $file_path"
           file copy $file_path $backup_path
       } else {
           ns_log Notice "lang::catalog::export_package_to_files - Not backing up $file_path as backup file already exists"
       }

       # Open the catalog file for writing, truncate if it exists
       set catalog_file_id [open $file_path w]
       fconfigure $catalog_file_id -encoding [ns_encodingforcharset $charset]

       # Open the root node of the document
       puts $catalog_file_id "<?xml version=\"1.0\"?>
<!-- Generated by lang::catalog::export_package_to_files on [clock format [clock seconds] -format {%Y %B %d %H:%M}] -->
<message_catalog package_key=\"$package_key\" locale=\"$locale\" charset=\"$charset\">
"

      # Loop over and write the messages to the file
      set message_count "0"
      foreach message_key $message_key_list {
          puts $catalog_file_id "  <msg key=\"[ad_quotehtml $message_key]\">[ad_quotehtml $messages_array($message_key)]</msg>"          
          incr message_count
      }

      # Close the root node and close the file
      puts $catalog_file_id "</message_catalog>"
      close $catalog_file_id       

      ns_log Notice "lang::catalog::export_messages_to_file - Wrote $message_count messages to file $file_path"
   }

    ad_proc -public import_from_files { package_key } {
        Import (load) all catalog files of a certain package. Catalog files
        should be stored in the /packages/package_key/catalog directory
        and have the ending .xml (i.e. /package/dotlrn/catalog/dotlrn.en_US.iso-8859-1.xml).

        @param package_key The package key of the package to import catalog files for

        @author Peter Marklund (peter@collaboraid.biz)
    } {
        # Check arguments
        if { [empty_string_p $package_key] } {
            error "lang::catalog::import_from_files - the package_key argument is the empty string"
        }

        # Get all catalog files of the package
        set glob_pattern [file join [acs_package_root_dir $package_key] catalog *.xml]
        set msg_file_list [glob -nocomplain $glob_pattern]

        # Issue a warning and exit if there are no catalog files
        if { [empty_string_p $msg_file_list] } {
            ns_log Warning "lang::catalog::import_from_files - No catalog files found for package $package_key"
            return
        }

        # Loop over each catalog file
        ns_log Notice "lang::catalog::import_from_files - Starting import of message catalogs: $msg_file_list"
        foreach msg_file $msg_file_list {
            set msg_file_contents [read_file $msg_file]
            array set catalog_array [parse $msg_file_contents]

            # Compare xml package_key with file path package_key - abort if there is a mismatch
            if { ![string equal $package_key $catalog_array(package_key)] } {
                error "lang::catalog::import_from_files - the package_key $catalog_array(package_key) in the file $msg_file does not match the package_key $package_key in the filesystem"
            }

            # TODO: Peter: Check that locale and charset in xml match info in file path
            
            # Loop over and register the messages
            array set messages_array [lindex [array get catalog_array messages] 1]
            foreach message_key [array names messages_array] {
                lang::message::register $catalog_array(locale) \
                                        $catalog_array(package_key) \
                                        $message_key \
                                        $messages_array($message_key)
            }
        }
    }

    ad_proc -public -deprecated -warn import_from_tcl_files {
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
        ns_log Notice "lang::catalog::import_from_tcl_files - Starting load of the message catalogs $glob_pattern"
        
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
    
        ns_log Notice "lang::catalog::import_from_tcl_files - Finished load of the message catalog" 
        
        unset __lang_catalog_load_package_key 
    
        return $files
    }
        
    ad_proc -public import_from_all_files {} {
        Loops over all installed and enabled packages that don't already have messages in the database
        and imports messages from the catalog files of each such package.

        @author Peter Marklund (peter@collaboraid.biz)
    } {
        db_foreach all_enabled_not_loaded_packages {} {
            if { [file isdirectory [file join [acs_package_root_dir $package_key] catalog]] } {
                lang::catalog::import_from_files $package_key
            }
        }
    }
    
    ad_proc -private translate {} {
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
