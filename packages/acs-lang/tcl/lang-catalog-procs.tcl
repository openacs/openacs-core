#/packages/acs-lang/tcl/lang-catalog-procs.tcl
ad_library {

    Routines for loading message catalog files 
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

    ad_proc -public load {
        {package_key "acs-lang"} 
    } { 
        Load the message catalogs from a package, defaults to /packages/acs-lang/catalog/ directory.
        Catalogs specify the MIME charset name of their encoding in their pathname.
    
        @author Jeff Davis (davis@arsdigita.com)
        @return Number of files loaded
    
    } { 
        set glob_pattern [file join [acs_package_root_dir $package_key] catalog *.cat]
        ns_log Notice "Starting load of the message catalogs $glob_pattern"
        
        global __lang_catalog_load_package_key
        set __lang_catalog_load_package_key $package_key
    
        set files [glob -nocomplain $glob_pattern]
        
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
                
                eval $src
                #if {[catch {eval $src} errMsg]} { 
                #    ns_log Warning "Failed loading message catalog $msg_file:\n$errMsg"
                #}
            }
        }
    
        ns_log Notice "Finished load of the message catalog" 
        
        unset __lang_catalog_load_package_key 
    
        return $files
    }
        
    ad_proc -public load_all {} {
        Loops over all installed and enabled packages and invokes lang_catalog_load
        for each package.
    } {
        db_foreach all_enabled_packages {} {
            if { [file isdirectory [file join [acs_package_root_dir $package_key] catalog]] } {
                lang_catalog_load $package_key
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
                    _mr $lang $key $translated_message
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
    @see lang::catalog::load_all
} {
    return [lang::catalog::load_all]
}
    
ad_proc -deprecated -warn lang_catalog_load {
    {package_key "acs-lang"} 
} {
    @see lang::catalog::load_all
} {
    return [lang::catalog::load $package_key]
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
