ad_library {

    Routines needed by the bootstrapper to load package code. 

    @creation-date 26 May 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id $Id$
}

ad_proc apm_first_time_loading_p {} { 
    Returns 1 if this is a -procs.tcl file's first time loading, or 0 otherwise. 
} {
    return [info exists ::apm_first_time_loading_p]
}

ad_proc -public ad_after_server_initialization { name args } {

    Registers code to run after server initialization is complete.

    @param name a human-readable name for the code block (for debugging purposes).
    @param args a code block or procedure to invoke.

} {
    nsv_lappend ad_after_server_initialization . [list name $name script [info script] args $args]
}

ad_proc -public apm_guess_file_type { package_key path } {

    Guesses and returns the file type key corresponding to a particular path
    (or an empty string if none is known). <code>$path</code> should be
    relative to the package directory (e.g., <code>www/index.tcl</code>)
    for <code>/packages/bboard/admin-www/index.tcl</code>. We use the following rules:

    <ol>
    <li>Files with extension <code>.sql</code> are considered data-model files,
    <li>Files with extension <code>.dat</code> are considered SQL data files.
    <li>Files with extension <code>.ctl</code> are considered sql data loader control files.
    or if any path contains the substring <code>upgrade</code>, data-model upgrade files.
    <li>Files with extension <code>.sqlj</code> are considered sqlj_code files.                       
    <li>Files with extension <code>.info</code> are considered package specification files.
    <li>Files with extension <code>.xql</code> are considered query files.
    <li>Files with extension <code>.java</code> are considered java code files.
    <li>Files with extension <code>.jar</code> are considered java archive files.
    <li>Files with a path component named <code>doc</code> are considered
    documentation files.
    <li>Files with extension <code>.pl</code> or <code>.sh</code> or
    which have a path component named
    <code>bin</code>, are considered shell-executable files.
    <li>Files with a path component named <code>templates</code> are considered
    template files.
    <li>Files with extension <code>.html</code> or <code>.adp</code>, in the top
    level of the package, are considered documentation files.
    <li>Files with a path component named <code>www</code> or <code>admin-www</code>
    are considered content-page files.
    <li>Files with a path component named <code>lib</code>
    are considered include_page files.
    <li>Files under package-key/tcl ending in <code>-procs(-)+()*.tcl)</code> 
    or <code>-init.tcl</code> are considered
    Tcl procedure or Tcl initialization files, respectively.
    <li>File ending in <code>.tcl</code> are considered Tcl utility script files 
      (normally found only in the bootstrap installer).
    <li>Files with extension <code>.xml</code> in the directory catalog are
      considered message catalog files.
    <li>Tcl procs or init files under package-key/tcl in a test directory are of type test_procs and test_init
      respectively.
     </ol>
    Rules are applied in this order (stopping with the first match).

} {
    set components [split $path "/"]
    set dirs_in_pageroot [llength [split $::acs::pageroot "/"]]       ;# See comments by RBM

    # Fix to cope with both full and relative paths
    if { [string index $path 0] eq "/"} {                          
        set components_lesser [lrange $components $dirs_in_pageroot end] 
    } else {
        set components_lesser $components
    }
    set extension [file extension $path]
    set type ""


    # DRB: someone named a file "acs-mail-create-packages.sql" rather than
    # the conventional "acs-mail-packages-create.sql", causing it to be
    # recognized as a data_model_create file, causing it to be explicitly
    # run by the installer (the author intended it to be included by
    # acs-mail-create.sql only).  I've tightened up the regexp below to
    # avoid this problem, along with renaming the file...

    # DRB: I've tightened it up again because forums-forums-create.sql
    # was being recognized as a datamodel create script for the forums
    # package.

    if {$extension eq ".sql"} {
        if { [lsearch -glob $components "*upgrade-*-*"] >= 0 } {
            set type "data_model_upgrade"
        } elseif { [regexp -- "^$package_key-(create|drop)\.sql\$" [file tail $path] "" kind] } {
            set type "data_model_$kind"
        } else {
            set type "data_model"
        }
    } elseif {$extension eq ".dat"} {
        set type "sql_data"
    } elseif {$extension eq ".ctl"} {
        set type "ctl_file"
    } elseif {$extension eq ".sqlj"} {
        set type "sqlj_code"
    } elseif {$extension eq ".info"} {
        set type "package_spec"
    } elseif {$extension eq ".xql"} {
        set type "query_file"
    } elseif {$extension eq ".java"} {
        set type "java_code"
    } elseif {$extension eq ".jar"} {
        set type "java_archive"
    } elseif { "doc" in $components } {
        set type "documentation"
    } elseif { $extension eq ".pl" || $extension eq ".sh" || "bin" in $components } {
        set type "shell"
    } elseif { "templates" in $components } {
        set type "template"
    } elseif { [llength $components] == 1 && 
               ($extension eq ".html" || $extension eq ".adp") } {
        # HTML or ADP file in the top level of a package - assume it's documentation.
        set type "documentation"

        # RBM: Changed the next elseif to check for 'www' or 'admin-www' only n levels down
        # the path, since that'd be the minimum in a path counting from the pageroot

    } elseif { "www" in $components_lesser || "admin-www" in $components_lesser } {
        set type "content_page"
    } elseif { "lib" in $components_lesser } {
        set type "include_page"
    } elseif { $extension eq ".tcl" && [lindex $components_lesser 0] eq "tcl" } {
        # A .tcl file residing under dir .../package_key/tcl/
        if { [regexp -- {-(procs|init)(-[0-9a-zA-Z]*)?\.tcl$} [file tail $path] "" kind] } {
            if {[lindex $components end-1] eq "test"} {
                set type "test_$kind"
            } else {
                set type "tcl_$kind"
            }
        } else {
            set type "tcl_util"
        }
    } elseif { [apm_is_catalog_file "${package_key}/${path}"] } {
        set type "message_catalog"
    } 
    
    return $type
}

ad_proc -public apm_get_package_files {
    {-include_data_model_files:boolean}
    {-all:boolean}
    {-all_db_types:boolean}
    {-package_key:required}
    {-package_path {}}
    {-file_types {}}
} {
    <p>
    Returns all files, or files of a certain types, belonging to an APM
    package. Ignores files based on proc apm_include_file_p and determines file type
    of files with proc apm_guess_file_type. Only returns file with no db type or a
    db type matching that of the system.
    </p>

    <p>
    Goes directly to the filesystem to find
    files instead of using a file listing in the package info file or the database.
    </p>

    @param package_key    The key of the package to return file paths for
    @param file_types     The type of files to return. If not provided files of all types
    recognized by the APM are returned.
    @param package_path   The full path of the root directory of the package. Defaults to 
    acs_package_root_dir.

    @return The paths, relative to the root dir of the package, of matching files.    

    @author Peter Marklund

    @see apm_include_file_p
    @see apm_guess_file_type
    @see apm_guess_db_type
} {
    if { $package_path eq "" } {
        set package_path [acs_package_root_dir $package_key]
    }

    if {$all_p} {
        set file_function ""
    } else {
        set file_function [expr {$include_data_model_files_p ? "apm_include_data_model_file_p" : "apm_include_file_p"}]
    }
    set files [lsort [ad_find_all_files -check_file_func $file_function $package_path]]
    # We don't assume db_type proc is defined yet
    set system_db_type [nsv_get ad_database_type .]

    set matching_files [list]
    foreach file $files {
        set rel_path [string range $file [string length $package_path]+1 end]
        set file_type [apm_guess_file_type $package_key $rel_path]
        set file_db_type [apm_guess_db_type $package_key $rel_path]

        set type_match_p [expr {$file_types eq "" || $file_type in $file_types}]

        if { $all_db_types_p } {
            set db_match_p 1
        } else {
            set db_match_p [expr {$file_db_type eq "" || $file_db_type eq $system_db_type}]
        }

        if { $type_match_p && $db_match_p } {
            lappend matching_files $rel_path
        }
    }

    return $matching_files
}

ad_proc -private apm_parse_catalog_path { file_path } {
    Given the path of a file attempt to extract package_key, 
    prefix, charset and locale
    information from the path assuming the path is on valid format
    for a message catalog file. If the parsing fails
    then the file is not considered a catalog file and the
    empty list is returned.

    @param file_path   Path of file, relative to the OpenACS /packages dir, 
    one of its parent directories, or absolute path.

    @author Peter Marklund
} {
    array set filename_info {}

    # Catalog filepaths are on the form
    # package_key/catalog/optional_prefix_package_key.language.country.charset.xml
    set regexp_pattern "(?i)(\[^/\]+)/catalog/(.*)\\1\\.(\[a-z\]{2,3}_\[a-z\]{2})\\.(\[^.\]+)\\.xml\$"
    if { ![regexp $regexp_pattern $file_path match package_key prefix locale charset] } {
        return [list]
    }

    set filename_info(package_key) $package_key
    set filename_info(prefix) $prefix
    set filename_info(locale) $locale
    set filename_info(charset) $charset

    return [array get filename_info]
}

ad_proc -public apm_is_catalog_file { file_path } {
    Given a file path return 1 if
    the path represents a message catalog file and 0 otherwise.

    @param file_path Should be absolute or relative to OpenACS /packages dir
    or one of its parent dirs.

    @see apm_parse_catalog_path
    @author Peter Marklund
} {
    array set filename_info [apm_parse_catalog_path $file_path]

    if { [array size filename_info] == 0 } {
        # Parsing failed
        set return_value 0
    } else {
        # Parsing succeeded
        set prefix $filename_info(prefix)
        if { $prefix eq "" } {
            # No prefix - this is considered a catalog file
            set return_value 1
        } else {
            # Catalog files don't have a prefix before the package_key
            set return_value 0
        }
    }

    return $return_value
}

ad_proc -private apm_guess_db_type { package_key path } {

    Guesses and returns the database type key corresponding to a particular path
    (or an empty string if none is known). <code>$path</code> should be
    relative to the package directory (e.g., <code>www/index.tcl</code> for <code>/packages/bboard/admin-www/index.tcl</code>).  

    We consider two cases:
    
    1. Data model files.
    
    If the path contains a string matching "sql/" followed by a database type known
    to this version of OpenACS, the file is assumed to be specific to that database type.
    The empty string is returned for all other data model files.

    Example: "sql/postgresql/apm-create.sql" is assumed to be the PostgreSQL-specific
    file used to create the APM datamodel.

    If the path contains a string matching "sql/common" the file is assumed to be
    compatible with all supported RDBMS's and a blank db_type is returned.

    Otherwise "oracle" is returned.  This is a hardwired kludge to allow us to
    handle legacy ACS 4 packages.

    2. Other files.

    If it is a tcl, xql, or sqlj file not under the sql dir and whose name 
    ends in a dash and database type, the file is assumed to be specific to 
    that database type.

    Example: "tcl/10-database-postgresql-proc.tcl" is asusmed to be the file that
    defines the PostgreSQL-specific portions of the database API.

} {
    set components [split $path "/"]
    set file_type [apm_guess_file_type $package_key $path]

    if { [string match "data_model*" $file_type] ||
         "ctl_file" eq $file_type } {
        set sql_index [lsearch $components "sql"]
        if { $sql_index >= 0 } {
            set db_dir [lindex $components $sql_index+1]
            if {$db_dir eq "common"} {
                return ""
            }
            foreach known_database_type $::acs::known_database_types {
                if {[lindex $known_database_type 0] eq $db_dir} {
                    return $db_dir
                }
            }
        }
        return "oracle"
    }

    set file_name [file tail $path]
    foreach known_database_type $::acs::known_database_types {
        if { [regexp -- "\-[lindex $known_database_type 0]\.(xql|tcl|sqlj)\$" $file_name match] } {
            return [lindex $known_database_type 0]
        }
    }

    return ""
}

ad_proc apm_package_supports_rdbms_p {
    {-package_key:required}
} {
    Returns 1 if the given package supports the rdbms of the system and 0 otherwise.
    The package is considedered to support the given rdbms if there is at least one
    file in the package of matching db_type, or if there are no files in the package
    of a certain db type.

    @author Peter Marklund
} {    
    set system_db_type [db_type]

    # LARS: This is a crude check, but there's really not any way of knowing for certain without the package telling us
    # We need to add that information back into the .info files.
    
    set package_path [acs_package_root_dir $package_key]
    return [expr {![file exists "${package_path}/sql"] || [file exists "${package_path}/sql/[db_type]"]}]
}

ad_proc -private apm_source { __file {errorVarName ""}} {
    Sources $__file in a clean environment, returning 1 if successful or 0 if not.
    Records that the file has been sourced and stores its mtime in the nsv array
    apm_library_mtime
} {
    if {$errorVarName ne ""} {
        upvar $errorVarName errors
    } else {
        array set errors [list]
    }

    if { ![file exists $__file] } {
        ns_log "Error" "Unable to source $__file: file does not exist."
        return 0
    }

    set r_file [ad_make_relative_path $__file]

    # Actually do the source.
    if { [catch { source $__file } errorMsg] } {
        set backTrace $::errorInfo
        ns_log "Error" "Error sourcing $__file:\n$backTrace"
        set package_key ""
        regexp {/packages/([^/]+)/} $__file -> package_key
        lappend errors($package_key) $r_file $backTrace
        return 0
    }

    nsv_set apm_library_mtime $r_file [file mtime $__file]    

    return 1
}

# Special boot strap load file routine.  

ad_proc -private apm_bootstrap_load_file { root_directory file {errorVarName ""}} {
    Source a single file during initial bootstrapping and set APM data.
} {
    ns_log "Notice" "Loading [file tail $root_directory]/$file"
    if {$errorVarName ne ""} {upvar $errorVarName errors}
    apm_source ${root_directory}/${file} errors
}

ad_proc -private apm_bootstrap_load_libraries {
    {-load_tests:boolean 0}
    {-init:boolean}
    {-procs:boolean}
    package_key
    {errorVarName ""}
} {
    Scan all the files in the "tcl" dir of the package and load those asked for by the init
    and procs flags.

    This proc is an analog of apm_load_libraries.  In addition though
    this proc sets apm_first_time_loading_p variable.

    @author Don Baccus (dhogaza@pacifier.com)
    @author Peter Marklund

    @param package_key The package to load (normally acs-tcl)
    @param init Load initialization files
    @param procs Load the proc library files
} {
    set file_types [list]
    if { $procs_p } {
        lappend file_types tcl_procs
    }
    if { $init_p } {
        lappend file_types tcl_init
    }
    if { $load_tests_p } {
        lappend file_types test_procs
    }
    if {$errorVarName ne ""} {
        upvar $errorVarName error
    }

    # This is the first time each of these files is being loaded (see
    # the documentation for the apm_first_time_loading_p proc).
    set ::apm_first_time_loading_p 1

    set package_root_dir [acs_package_root_dir $package_key]
    foreach file [apm_get_package_files -package_key $package_key -file_types $file_types] {

        apm_bootstrap_load_file $package_root_dir $file error

        # Call db_release_unused_handles, only if the library defining it
        # (10-database-procs.tcl) has been sourced yet.
        if { [info commands db_release_unused_handles] ne ""} {
            db_release_unused_handles
        }
    }

    unset ::apm_first_time_loading_p
}

proc apm_bootstrap_load_queries { package_key } {

    # Load up queries.

    set db_type [nsv_get ad_database_type .]

    # DRB: We can't parse the $package_key.info file at this point in time, primarily because
    # grabbing the package information uses not only the XML file but tables from the APM,
    # which haven't been loaded yet if we're installing.  So we just snarf all of the
    # queryfiles in this package that match the current database or no database
    # (which we interpret to mean all supported databases).

    set files [ad_find_all_files $::acs::rootdir/packages/$package_key]
    if { [llength $files] == 0 } {
        error "Unable to locate $::acs::rootdir/packages/$package_key/*."
    }

    foreach file [lsort $files] {

        set file_db_type [apm_guess_db_type $package_key $file]
        set file_type [apm_guess_file_type $package_key $file]

        if {$file_type eq "query_file" &&
            ($file_db_type eq "" || $file_db_type eq $db_type)} {
            db_qd_load_query_file $file
        } 
    }
}

ad_proc -private apm_load_install_xml_file {} {
    Loads any install.xml file and returns the root node. Returns
    the empty string if there is no install.xml file.

    @author Peter Marklund
} {
    set fn [apm_install_xml_file_path]
    # Abort if there is no install.xml file
    if { ![file exists $fn] } {
        return ""
    }

    #ns_log notice "==== LOADING xml file: $fn"
    set file [open $fn]
    set root_node [xml_doc_get_first_node [xml_parse -persist [read $file]]]
    close $file

    return $root_node
}

ad_proc -private apm_install_xml_file_path {} {
    Get the path of the install.xml file.

    @author Peter Marklund
} {
    return "$::acs::rootdir/install.xml"
}

ad_proc -private apm_ignore_file_p { 
    {-data_model_files:boolean}
    path 
} {

    Return 1 if $path should, in general, be ignored for package operations.
    Currently, a file is ignored if it is a backup file or a CVS directory.

} {
    if {[file isdirectory $path]} {
        #
        # ignored directories
        #
        set parts [file split $path]
        if {[lindex $parts end] eq "resources" && [lindex $parts end-1] eq "www"} {
            return 1
        }

        set dir_list {CVS .git catalog}
        if {!$data_model_files_p} {
            lappend dir_list "upgrade"
        }
        
        if {[lindex $parts end] in $dir_list} {
            return 1
        }
    }
    #
    # ignored extensions
    #
    set extension_list {.html .gif .png .jpg .ico .pdf .js .css .xsl .tgz .zip .gz .java}
    if {!$data_model_files_p} {
        lappend extension_list ".sql"
    }
    if {[file extension $path] in $extension_list} {
        return 1 
    }

    if { [apm_backup_file_p [file tail $path]] } {
        return 1
    }

    return 0
}

ad_proc -private apm_backup_file_p { path } {

    Returns 1 if $path is a backup file, or 0 if not. We consider it a backup file if
    any of the following apply:

    <ul>
    <li>its name begins with <code>#</code>
    <li>its name is <code>bak</code>
    <li>its name begins with <code>bak</code> and one or more non-alphanumeric characters
    <li>its name ends with <code>.old</code>, <code>.bak</code>, or <code>~</code>
    </ul>

} {
    return [regexp {(\.old|\.bak|~)$|^#|^bak$|^bak([^a-zA-Z]+)} $path]
}

ad_proc -private apm_include_data_model_file_p { filename } {    
    Check if the APM should consider a file found by ad_find_all_files.
    Files for which apm_ignore_file_p returns true will be ignored.
    Backup files are ignored.
} {
    #ns_log notice "apm_include_file_p <$filename> => [apm_ignore_file_p -data_model_files $filename]"
    return [expr {![apm_ignore_file_p -data_model_files $filename]}] 
}


ad_proc -private apm_include_file_p { filename } {    
    Check if the APM should consider a file found by ad_find_all_files.
    Files for which apm_ignore_file_p returns true will be ignored.
    Backup files and sql scripts (including the ones in upgrade directory) are ignored.
} {
    #ns_log notice "apm_include_file_p <$filename> => [apm_ignore_file_p $filename]"
    return [expr {![apm_ignore_file_p $filename]}] 
}

ad_proc apm_bootstrap_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {

    Copy the files from acs-bootstrap-installer/installer/tcl to the
    Tcl files in the acs root directory. This makes it possible to
    incorporate changes to these files by only updating the
    acs-bootstrap-installer package (rather than a full tar file
    install as in eralier versions). 

    Caveat: don't modify these files in your local installation, adding
    extra files to $::acs::rootdir/tcl is fine.
} {
    set source $::acs::rootdir/packages/acs-bootstrap-installer/installer/tcl
    foreach file [glob -nocomplain $source/*tcl] {
        file copy -force -- $file $::acs::rootdir/tcl/
        #
        # It would be good to allow changes in the setup here, but for
        # that, e.g. 0-acs-tcl has to be split up into two parts: (a)
        # setup of variables, and (b) sourcing everything.
        #
        # source $::acs::rootdir/tcl/[file tail $file]
    }
    set source $::acs::rootdir/packages/acs-bootstrap-installer/installer/www
    foreach file [glob -nocomplain $source/*tcl $source/*adp] {
        file copy -force -- $file $::acs::rootdir/www/
    }
    foreach file [glob -nocomplain $source/SYSTEM/*tcl] {
        file copy -force -- $file $::acs::rootdir/www/SYSTEM/
    }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
