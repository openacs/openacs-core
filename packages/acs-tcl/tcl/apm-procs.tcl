ad_library {

    Routines used by the package manager.

    @creation-date 13 Apr 2000
    @author Bryan Quinn (bquinn@arsdigita.com)
    @author Jon Salz (jsalz@arsdigita.com)
    @cvs-id $Id$
}

namespace eval apm {}

#
# Use either "class" or "blueprint" reloading.
#
# Blueprint reloading (starting with OpenACS 5.10) updates the
# blueprint of nsd, which has the consequence the also threads for
# running scheduled procedures can be updated. So far blueprint
# reloading is just tested with NaviServer, but should work with
# AOLserver as well (modulo bugs).
#
#set ::apm::reloading classic
set ::apm::reloading blueprint

#####
# Globals used by the package manager:
#
#     apm_current_package_key
#         Identifies which package is currently being loaded.
#
#
#
# NSV arrays used by the package_manager: (note that all paths are relative
# to [acs_path_root] unless otherwise indicated)
#
#     apm_version_properties($info_file_path)
#
#         Contains a list [list $mtime $properties_array], where $properties_array
#         is a cached copy of the version properties array last returned by
#         [apm_read_package_info_file $info_file_path], and $mtime is the
#         modification time of the $info_file_path when it was last examined.
#
#         This is a cache for apm_read_package_info_file.
#
#     apm_library_mtime($path)
#
#         The modification time of $file (a *-procs.tcl, *-init.tcl or .xql file)
#         when it was last loaded.
#
#     apm_version_procs_loaded_p($version_id)
#     apm_version_init_loaded_p($version_id)
#
#         1 if the *-procs.tcl and *-init.tcl files (respectively) have been
#         loaded for package version $version_id.
#
#     apm_vc_status($path)
#
#         A cached result from apm_fetch_cached_vc_status (of the form
#         [list $mtime $path]) containing the last-known CVS status of
#         $path.
#
#     apm_properties(reload_level)
#
#         The current "reload level" for the server.
#
#     apm_reload($reload_level)
#
#         A list of files which need to be loaded to bring the current interpreter
#         up to reload level $reload_level from level $reload_level - 1.
#
#     apm_reload_watch($path)
#
#         Indicates that $path is a -procs.tcl file which should be examined
#         every time apm_load_any_changed_libraries is invoked, to see whether
#         it has changed since last loaded. The path starts at $::acs::rootdir.
#
# RELOADING VOODOO
#
#     To allow for automatically reloading of Tcl libraries, we introduce the
#     concept of a server-wide "reload level" (starting at zero) stored in
#     the apm_properties(reload_level) NSV array entry. Whenever we determine
#     we want to have all interpreters source a particular -procs.tcl file,
#     we:
#
#         1) Increment apm_properties(reload_level), as a signal to each
#            interpreter that it needs to source some new -procs.tcl files
#            to bring itself up to date.
#         2) Set apm_reload($reload_level), where $reload_level is the new
#            value of apm_properties(reload_level) set in step #1, to the
#            list of files which actually need to be sourced.
#
#     Each interpreter maintains its private, interpreter-specific reload level
#     as a proc named apm_reload_level_in_this_interpreter. Every time the
#     request processor sees a request, it invokes
#     apm_load_any_changed_libraries, which compares the server-wide
#     reload level to the interpreter-private one. If it notes a difference,
#     it reloads the set of files necessary to bring itself up-to-date (i.e.,
#     files noted in the applicable entries of apm_reload).
#
#     Example:
#
#         - The server is started. apm_properties(reload_level) is 0.
#         - I modify /packages/acs-tcl/utilities-procs.tcl.
#         - Through the package manager GUI, I invoke
#           apm_mark_version_for_reload. It notices that utilities-procs.tcl
#           has changed. It increments apm_properties(reload_level) to 1,
#           and sets apm_reload(1) to [list "packages/acs-tcl/utilities-procs.tcl"].
#         - A request is handled in some other interpreter, whose reload
#           level (as returned by apm_reload_level_in_this_interpreter)
#           is 0. apm_load_any_changed_libraries notes that
#           [apm_reload_level_in_this_interpreter] != [nsv_get apm_properties reload_level],
#           so it sources the files listed in apm_reload(1) (i.e., utilities-procs.tcl)
#           and redefines apm_reload_level_in_this_interpreter to return 1.
#
#####


### Callback functions are used to control the logging that occurs during
### the execution of any apm_package that uses the -callback argument.

ad_proc -public apm_dummy_callback { string } {

    A dummy callback routine which does nothing.

} {
    # Do nothing!
}

ad_proc -public apm_ns_write_callback { string } {

    A simple callback which prints out the log message to the server stream.

} {
    ns_write $string
}

ad_proc -public apm_body_callback { string } {
    This callback uses the document API to append more text to the stream.
} {
    append ::__apm_body $string
}


ad_proc apm_callback_and_log { { -severity Notice } callback message } {

    Executes the $callback callback routine with $message as an argument,
    and calls ns_log with the given $severity.

} {
    $callback $message
    ns_log $severity [ad_html_to_text -maxlen 140 -- $message]
}

ad_proc apm_one_package_descendents {
    package_key
} {

    Returns a list of package keys of all packages that inherit from the given
    package

} {

    foreach descendent [db_list get_descendents {}] {
        if { [info exists ::apm_visited_package_keys($descendent)] } {
            continue
        }
        set ::apm_visited_package_keys($descendent) 1
        lappend ::apm_package_descendents $descendent
        apm_one_package_descendents $descendent
    }

}

ad_proc apm_build_subsite_packages_list {} {

    Build the nsv_set cache of all packages which claim to implement subsite
    semantics.  The kludge to add acs-subsite if it's not declared with the subsite
    attribute set true is needed during the upgrade process ...

} {
    nsv_set apm_subsite_packages_list package_keys {}

    # Make sure old versions work ...
    catch { nsv_set apm_subsite_packages_list package_keys [db_list get_subsites {}] }
    if {"acs-subsite" ni [nsv_get apm_subsite_packages_list package_keys]} {
        nsv_lappend apm_subsite_packages_list package_keys acs-subsite
    }

}

ad_proc apm_package_list_url_resolution {
    package_list
} {
    Use a left-right, breadth-first traverse of the inheritance DAG to build a
    structure to be used by the request processor to resolve URLs based on a
    package's "extends" and "embeds" dependencies.
} {

    foreach package $package_list {
        lassign $package package_key dependency_type
        if { [info exists ::apm_visited_package_keys($package_key)] } {
            continue
        }
        switch -- $dependency_type {
            extends -
            "" { lappend ::apm_package_url_resolution $::acs::rootdir/packages/$package_key/www }
            embeds {

                # Reference to an embedded package is through URLs relative to the embedding
                # package's mount point, taking one  of the forms package-key,
                # admin/package-key and sitewide-admin/package-key.  These map to package-key/embed,
                # package-key/embed/admin, and package-key/embed/sitewide-admin respectively.

                # We break references like package-key/admin because such references are unsafe,
                # as the request processor will not perform the expected permission check.

                lappend ::apm_package_url_resolution \
                    [list $::acs::rootdir/packages/$package_key/embed/admin admin/$package_key]
                lappend ::apm_package_url_resolution \
                    [list "" $package_key/admin]

                lappend ::apm_package_url_resolution \
                    [list $::acs::rootdir/packages/$package_key/embed/sitewide-admin \
                         sitewide-admin/$package_key]
                lappend ::apm_package_url_resolution \
                    [list "" $package_key/sitewide-admin]

                lappend ::apm_package_url_resolution \
                    [list $::acs::rootdir/packages/$package_key/embed $package_key]
            }
            default {
                error "apm_package_list_url_resolution: dependency type is $dependency_type"
            }
        }
        set ::apm_visited_package_keys($package_key) 1
    }

    # Make sure old versions work ...
    foreach package $package_list {
        lassign $package package_key dependency_type
        set inherit_templates_p t
        #fix!
        catch { db_1row get_inherit_templates_p {} }
        apm_package_list_url_resolution [db_list_of_lists get_dependencies {}]
    }
}

ad_proc apm_one_package_inherit_order {
    package_key
} {

    Returns a list of package keys in package inheritance order.

} {

    if { [info exists ::apm_visited_package_keys($package_key)] } {
        return
    }
    set ::apm_visited_package_keys($package_key) 1

    foreach dependency [db_list get_dependencies {}] {
        apm_one_package_inherit_order $dependency
    }

    lappend ::apm_package_inherit_order $package_key
}

ad_proc apm_one_package_load_libraries_dependencies {
    package_key
} {

    Generate a list of package keys in library load dependency order.

} {

    if { [info exists ::apm_visited_package_keys($package_key)] } {
        return
    }
    set ::apm_visited_package_keys($package_key) 1
    set package_key_list ""

    foreach dependency [db_list get_dependencies {}] {
        apm_one_package_load_libraries_dependencies $dependency
    }
    lappend ::apm_package_load_libraries_order $package_key
}

ad_proc apm_build_one_package_relationships {
    package_key
} {

    Builds the nsv dependency structures for a single package.

} {

    array unset ::apm_visited_package_keys
    set ::apm_package_url_resolution [list]
    apm_package_list_url_resolution $package_key
    nsv_set apm_package_url_resolution $package_key $::apm_package_url_resolution

    array unset ::apm_visited_package_keys
    set ::apm_package_inherit_order [list]
    apm_one_package_inherit_order $package_key
    nsv_set apm_package_inherit_order $package_key $::apm_package_inherit_order

    array unset ::apm_visited_package_keys
    set ::apm_package_load_libraries_order [list]
    apm_one_package_load_libraries_dependencies $package_key
    nsv_set apm_package_load_libraries_order $package_key $::apm_package_load_libraries_order

    array unset ::apm_visited_package_keys
    set ::apm_package_descendents [list]
    apm_one_package_descendents $package_key
    nsv_set apm_package_descendents $package_key $::apm_package_descendents

}

ad_proc apm_build_package_relationships {} {

    Builds the nsv dependency and ancestor structures.

} {
    foreach package_key [apm_enabled_packages] {
        apm_build_one_package_relationships $package_key
    }
}

ad_proc apm_package_descendents {
    package_key
} {
    Wrapper that returns the cached package descendents list.
} {
    return [nsv_get apm_package_descendents $package_key]
}

ad_proc apm_package_inherit_order {
    package_key
} {
    Wrapper that returns the cached package inheritance order list.
} {
    return [nsv_get apm_package_inherit_order $package_key]
}

ad_proc apm_package_url_resolution {
    package_key
} {
    Wrapper that returns the cached package search order list.
} {
    return [nsv_get apm_package_url_resolution $package_key]
}


ad_proc apm_package_load_libraries_order {
    package_key
} {
    Wrapper that returns the cached package library load order list.
} {
    return [nsv_get apm_package_load_libraries_order $package_key]
}

ad_proc -public apm_version_loaded_p { version_id } {

    Returns 1 if a version of a package has been loaded and initialized, or 0 otherwise.

} {
    return [nsv_exists apm_version_init_loaded_p $version_id]
}

ad_proc -private apm_mark_files_for_reload {
    {-force_reload:boolean}
    file_list
} {
    Mark the given list of Tcl and query files for reload in all
    interpreters. Only marks files for reload if they haven't been
    loaded before or they have changed since last reload.

    @param file_list A list of paths relative to $::acs::rootdir
    @param force_reload Mark the files for reload even if their modification
    time in the nsv cache doesn't differ from the one
    in the filesystem.

    @return The list of files marked for reload.

    @author Peter Marklund
} {
    set changed_files [list]
    foreach relative_path $file_list {
        set full_path "$::acs::rootdir/$relative_path"

        # If the file exists, and either has never been loaded or has an mtime
        # which differs the mtime it had when last loaded, mark to be loaded.
        if { [file isfile $full_path] } {
            set mtime [file mtime $full_path]
            if { $force_reload_p
                 || (![nsv_exists apm_library_mtime $relative_path]
                     || [nsv_get apm_library_mtime $relative_path] != $mtime
                     || [clock seconds]-$mtime < 5) } {
                lappend changed_files $relative_path
            }
        }
    }

    if {$::apm::reloading eq "classic"} {
        if { [llength $changed_files] > 0 } {
            set reload [nsv_incr apm_properties reload_level]
            nsv_set apm_reload $reload $changed_files
        }
    }

    return $changed_files
}

proc ::foo0 {} {return 0}

ad_proc -private apm_mark_version_for_reload {
    version_id
    { changed_files_var "" }
} {
    Examines all tcl_procs files in package version $version_id; if any have
    changed since they were loaded, marks (in the apm_reload array) that
    they must be reloaded by each Tcl interpreter (using the
    apm_load_any_changed_libraries procedure).

    <p>Saves a list of files that have changed (and thus marked to be reloaded) in
    the variable named <code>$file_info_var</code>, if provided. Each element
    of this list is of the form:

    <blockquote><pre>[list $file_id $path]</pre></blockquote>

} {
    if { $changed_files_var ne "" } {
        upvar $changed_files_var changed_files
    }
    set package_key [apm_package_key_from_version_id $version_id]
    #ns_log notice "apm_mark_version_for_reload $package_key version_id $version_id"
    set changed_files [list]

    set file_types [list tcl_procs query_file]
    if { [apm_load_tests_p] } {
        lappend file_types test_procs
    }

    foreach path [apm_get_package_files -package_key $package_key -file_types $file_types] {
        set full_path "[acs_package_root_dir $package_key]/$path"
        set relative_path "packages/$package_key/$path"

        set reload_file [apm_mark_files_for_reload $relative_path]
        if { [llength $reload_file] > 0 } {
            # The file marked for reload
            lappend changed_files $relative_path
        }
    }
    return $changed_files
}

ad_proc -private apm_version_load_status { version_id } {

    If a version needs to be reloaded (i.e., a <code>-procs.tcl</code> has changed
                                       or been added since the version was loaded), returns "needs_reload".
    If the version has never been loaded, returns "never_loaded". If the
    version is up-to-date, returns "up_to_date".

} {
    # See if the version was ever loaded.
    if { ![apm_package_version_enabled_p $version_id] } {
        return "never_loaded"
    }

    set package_key [apm_package_key_from_version_id $version_id]
    set procs_types [list tcl_procs]
    if { [apm_load_tests_p] } {
        lappend procs_types test_procs
    }
    foreach file [apm_get_package_files -package_key $package_key -file_types $procs_types] {
        # If $file has never been loaded, i.e., it has been added to the version
        # since the version was initially loaded, return needs_reload.
        if { ![nsv_exists apm_library_mtime "packages/$package_key/$file"] } {
            return "needs_reload"
        }

        set full_path "[acs_package_root_dir $package_key]/$file"
        # If $file had a different mtime when it was last loaded, return
        # needs_reload. (If the file should exist but doesn't, just skip it.)
        if { [file exists $full_path]
             &&  [file mtime $full_path] ne [nsv_get apm_library_mtime "packages/$package_key/$file"]
         } {
            return "needs_reload"
        }
    }

    foreach file [apm_get_package_files -package_key $package_key -file_types "query_file"] {
        # If $file has never been loaded, i.e., it has been added to the version
        # since the version was initially loaded, return needs_reload.
        if { ![nsv_exists apm_library_mtime "packages/$package_key/$file"] } {
            return "needs_reload"
        }

        set full_path "[acs_package_root_dir $package_key]/$file"
        # If $file had a different mtime when it was last loaded, return
        # needs_reload. (If the file should exist but doesn't, just skip it.)
        if { [file exists $full_path]
             && [file mtime $full_path] ne [nsv_get apm_library_mtime "packages/$package_key/$file"]
         } {
            return "needs_reload"
        }
    }

    return "up_to_date"
}

ad_proc -private apm_load_libraries {
    {-force_reload:boolean 0}
    {-packages {}}
    {-callback apm_dummy_callback}
    {-procs:boolean}
    {-init:boolean}
    {-test_procs:boolean}
    {-test_init:boolean}
} {

    Loads all -procs.tcl (if $procs_or_init is "procs") or -init.tcl  files into the
    current interpreter for installed, enabled packages. Only loads
    files which have not yet been loaded. This is intended to be called only during server
    initialization (since it loads libraries only into the running interpreter, as opposed
                    to in *all* active interpreters).

} {
    set file_types [list]
    if { $procs_p } {
        lappend file_types tcl_procs
    }
    if { $init_p } {
        lappend file_types tcl_init
    }
    if { $test_procs_p } {
        lappend file_types test_procs
    }
    if { $test_init_p } {
        lappend file_types test_init
    }

    if { $packages eq "" } {
        set packages [apm_enabled_packages]
    }

    # Scan the package directory for files to source.
    set files [list]
    foreach package $packages {

        set paths [apm_get_package_files -package_key $package -file_types $file_types]

        foreach path [lsort $paths] {
            lappend files [list $package $path]
        }
    }

    # Release all outstanding database handles (since the file we're sourcing
    # might be using the ns_db database API as opposed to the new db_* API).
    db_release_unused_handles
    apm_files_load -force_reload=$force_reload_p -callback $callback $files
}

ad_proc -public apm_load_tests_p {} {
    Determine whether to load acs-automated-testing tests
    for packages.

    @return 1 if tests should be loaded and 0 otherwise

    @author Peter Marklund
} {
    return [apm_package_enabled_p "acs-automated-testing"]
}

ad_proc -public apm_load_packages {
    {-force_reload:boolean 0}
    {-load_libraries_p 1}
    {-load_queries_p 1}
    {-packages {}}
} {
    Load Tcl libraries and queries for the packages with given keys. Only
    loads procs into the current interpreter. Will
    load Tcl tests if the acs-automated-testing package is enabled.

    @param force_reload Reload Tcl libraries even if they are already loaded.
    @param load_libraries_p Switch to indicate if Tcl libraries in (-procs.tcl and -init.tcl)
    files should be loaded. Defaults to true.
    @param load_queries_p   Switch to indicate if xql query files should be loaded. Default true.
    @param packages     A list of package_keys for packages to be loaded. Defaults to
    all enabled packages.  These packages, along with the packages
    they depend on, will be loaded in dependency-order using the
    information provided in the packages' "provides" and "requires"
    attributes.

    @see apm_mark_version_for_reload

    @author Peter Marklund
} {
    if { $packages eq "" } {
        set packages [apm_enabled_packages]
    }

    set packages_to_load [list]
    foreach package_key $packages {
        foreach package_to_load [::apm_package_load_libraries_order $package_key] {
            if {$package_to_load ni $packages_to_load} {
                lappend packages_to_load $package_to_load
            }
        }
    }

    # Should acs-automated-testing tests be loaded?
    set load_tests_p [apm_load_tests_p]

    # Load *-procs.tcl files
    if { $load_libraries_p } {
        apm_load_libraries -force_reload=$force_reload_p -packages $packages_to_load -procs
    }

    # Load up the Queries (OpenACS, ben@mit.edu)
    if { $load_queries_p } {
        apm_load_queries -packages $packages_to_load
    }

    # Load up the Automated Tests and associated Queries if necessary
    if {$load_tests_p} {
        apm_load_libraries -force_reload=$force_reload_p -packages $packages -test_procs
        apm_load_queries -packages $packages_to_load -test_queries
    }

    if { $load_libraries_p } {
        # branimir: acs-lang needs to be initialized before anything else
        # because there are packages whose *-init.tcl files depend on it.
        apm_load_libraries -force_reload=$force_reload_p -init -packages acs-lang
        set p [lsearch $packages_to_load acs-lang]
        if {$p > -1} {
            set unique_packages [lreplace $packages_to_load $p $p]
        } else {
            set unique_packages $packages_to_load
        }
        apm_load_libraries -force_reload=$force_reload_p -init -packages $unique_packages
    }

    # Load up the Automated Tests initialisation scripts if necessary
    if {$load_tests_p} {
        apm_load_libraries -force_reload=$force_reload_p -packages $packages_to_load -test_init
    }
}

ad_proc -private apm_load_queries {
    {-packages {}}
    {-callback apm_dummy_callback}
    {-test_queries:boolean}
} {
    Load up the queries for all enabled packages
    (or all specified packages). Follows the pattern
    of the load_libraries proc, but only loads query information

    @param packages Optional list of keys for packages to load queries for.

    @author ben@mit.edu
} {
    if { $packages eq "" } {
        set packages [apm_enabled_packages]
    }

    # Scan the package directory for files to source.
    set files [list]
    foreach package $packages {

        set files [ad_find_all_files $::acs::rootdir/packages/$package]
        if { [llength $files] == 0 } {
            ns_log Error "apm_load_queries: Unable to locate $::acs::rootdir/packages/$package/*. when scanning for SQL queries to load."
        }

        set testdir    "$::acs::rootdir/packages/$package/tcl/test"
        set testlength [string length $testdir]

        foreach file [lsort $files] {

            set file_db_type [apm_guess_db_type $package $file]
            set file_type [apm_guess_file_type $package $file]

            if {![string compare -length $testlength $testdir $file]} {
                set is_test_file_p 1
            } else {
                set is_test_file_p 0
            }

            #
            # Note this exclusive or represents the following:
            # test_queries_p - Load normal xql files or load test xql files
            # is_test_file_p - Current file is a test file or not.
            #
            # !(test_queries_p ^ is_test_file_p)  = Load it or not?
            #             !( 0 ^ 0 )             = Yep
            #             !( 0 ^ 1 )             = Nope
            #             !( 1 ^ 0 )             = Nope
            #             !( 1 ^ 1 )             = Yep
            #
            if {!($test_queries_p ^ $is_test_file_p)
                && $file_type eq "query_file"
                && ($file_db_type eq "" || $file_db_type eq [db_type])
            } {
                db_qd_load_query_file $file
            }
        }
    }
    ns_log debug "apm_load_queries: DONE looping through files from which to load queries"
}

ad_proc -private apm_subdirs { path } {

    Returns a list of subdirectories of path (including path itself)

} {
    set dirs [list]
    lappend dirs $path
    foreach subdir [glob -nocomplain -type d [file join $path *]] {
        lappend dirs {*}[apm_subdirs $subdir]
    }
    return $dirs
}

ad_proc -private apm_pretty_name_for_file_type { type } {

    Returns the pretty name corresponding to a particular file type key

    @see apm_file_type_names
    @see apm_file_type_keys

    @author Peter Marklund
} {
    array set file_type_names [apm_file_type_names]

    return $file_type_names($type)
}

ad_proc -private apm_get_changed_watched_files {} {

    Check, which of the watched files have to be reloaded

    @return list of filenames
} {
    set files_to_reload [list]
    foreach file [nsv_array names apm_reload_watch] {
        set path "$::acs::rootdir/$file"
        ns_log Debug "APM: File being watched: $path"

        if { [file exists $path]
             && (![nsv_exists apm_library_mtime $file]
                 || [file mtime $path] ne [nsv_get apm_library_mtime $file])
         } {
            lappend files_to_reload $file
        }
    }
    if {[llength $files_to_reload] > 0} {
        if {[llength $files_to_reload] > 1} {
            lassign {s have} suffix verb
        } else {
            lassign {{} has} suffix verb
        }
        ns_log Notice "apm_reloads: Watched file$suffix [join $files_to_reload ", "] $verb changed"
    }

    return $files_to_reload
}

ad_proc -public apm_load_any_changed_libraries {
    {-version_files ""}
    {errorVarName {}}
} {

    In the running interpreter, reloads files marked for reload by
    apm_mark_version_for_reload. If any watches are set, examines watched
    files to see whether they need to be reloaded as well. This is intended
    to be called only by the request processor (since it should be invoked
    before any filters or registered procedures are applied).

} {
    set files $version_files

    if {$errorVarName ne ""} {
        upvar $errorVarName errors
    } else {
        array set errors [list]
    }

    if {$::apm::reloading eq "blueprint"} {
        #ns_log notice "### blueprint_reloading: apm_load_any_changed_libraries [time {apm_get_changed_watched_files}]"

        #
        # Add the watched files, but don't load these if these are
        # already included.
        #
        foreach file [apm_get_changed_watched_files] {
            if {$file ni $files} {
                lappend files $file
            }
        }
        if {[llength $files] > 0} {
            ns_log notice "### blueprint_reloading: [llength $files] files $files"

            #
            # Transform files into reload-cmds
            #
            set cmds [apm_package_reload_cmds $files]
            #
            # Execute these cmds in a fresh interp to produce a new
            # blueprint.
            #
            ns_log notice "### blueprint_reloading: cmds:\n[join $cmds \;\n]"

            ns_eval [join $cmds \;]
        }
    }

    if {$::apm::reloading eq "classic"} {

        #ns_log notice "### classic_reloading: apm_load_any_changed_libraries"

        #
        # Determine the current reload level in this interpreter by
        # calling apm_reload_level_in_this_interpreter. If this fails, we
        # define the reload level to be zero.
        #
        if { [catch { set reload_level [apm_reload_level_in_this_interpreter] } error] } {
            proc apm_reload_level_in_this_interpreter {} { return 0 }
            set reload_level 0
        }

        #
        # Check watched files, adding them to files_to_reload if they have
        # changed.
        #
        set files_to_reload [apm_get_changed_watched_files]

        #
        # If there are any changed watched files, stick another entry on
        # the reload queue.
        #
        if { [llength $files_to_reload] > 0 } {
            ns_log Notice "apm_load_any_changed_libraries: Reloading [join $files_to_reload {, }]"
            set new_level [nsv_incr apm_properties reload_level]
            nsv_set apm_reload $new_level $files_to_reload
        }

        set changed_reload_level_p 0

        # Keep track of which files we've reloaded in this loop so we never
        # reload the same one twice.
        while { $reload_level < [nsv_get apm_properties reload_level] } {
            incr reload_level
            set changed_reload_level_p 1
            # If there's no entry in apm_reload for that reload level, back out.
            if { ![nsv_exists apm_reload $reload_level] } {
                incr reload_level -1
                break
            }
            set reload_cmds [apm_package_reload_cmds [nsv_get apm_reload $reload_level]]
            foreach cmd $reload_cmds {
                if {$cmd ne ""} {
                    ns_log notice "### apm classic reload level $reload_level: cmd $cmd"
                    {*}$cmd
                }
            }
        }

        # We changed the reload level in this interpreter, so redefine the
        # apm_reload_level_in_this_interpreter proc.
        #
        if { $changed_reload_level_p } {
            proc apm_reload_level_in_this_interpreter {} "return $reload_level"
        }
    }
}

ad_proc -private apm_package_reload_cmds {files} {

    Map file names into reloading cmds. For every file, a loading
    command is appended to the result. The command might be empty.

    @return list of Tcl cmds to be executed to load these files.

} {
    set cmds {}
    if { [llength $files] > 0 } {
        ns_log Notice "apm_reload: Reloading *-procs.tcl amd .xql files in this interpreter..."
    }

    foreach file $files {
        set cmd {}
        #
        # If we haven't yet reloaded the file in this loop, source it.
        #
        if { ![info exists reloaded_files($file)] } {
            # File is usually of form packages/package_key
            set file_path "$::acs::rootdir/$file"
            set file_ext [file extension $file_path]
            switch -- $file_ext {
                .tcl {
                    # Make sure this is not a -init.tcl file as those should only be sourced on server startup
                    if { ![string match "*-init.tcl" $file_path] } {
                        ns_log Notice "apm: Reloading $file..."
                        set cmd [list apm_source $file_path errors]
                    }
                }
                .xql {
                    ns_log Notice "apm: Reloading $file..."
                    set cmd [list db_qd_load_query_file $file_path errors]
                }
                default {
                    ns_log Notice "apm: File $file_path has unknown extension. Not reloading."
                }
            }
            set reloaded_files($file) 1
        }
        lappend cmds $cmd
    }
    return $cmds
}


ad_proc -private apm_package_version_release_tag { package_key version_name } {

    Returns a CVS release tag for a particular package key and version name.

} {
    regsub -all {\.} [string toupper "$package_key-$version_name"] "-" release_tag
    return $release_tag
}

ad_proc -public apm_package_parameters {package_key} {
    @return A list of all the package parameter names.
} {
    return [db_list get_names {
        select parameter_name from apm_parameters
        where package_key = :package_key
    }]
}

ad_proc -public apm_package_supported_databases {
    package_key
} {
    Return a list of db types (i.e. oracle, postgresql)
    supported by the package with given key.

    @author Peter Marklund

    @see db_known_database_types
    @see apm_package_supports_rdbms_p
} {
    set supported_databases_list [list]
    foreach db_type_info [db_known_database_types] {
        set db_type [lindex $db_type_info 0]
        if { [apm_package_supports_rdbms_p -package_key $package_key] } {
            lappend supported_databases_list $db_type
        }
    }

    return $supported_databases_list
}

ad_proc -public apm_package_registered_p {
    package_key
} {
    Returns 1 if there is a registered package with the indicated package_key.
    Returns 0 otherwise.
} {
    ### Query the database for the indicated package_key
    return [db_string apm_package_registered_p {
        select 1 from apm_package_types
        where package_key = :package_key
    } -default 0]
}

ad_proc -public apm_package_installed_p {
    package_key
} {
    Returns 1 if there is an installed package version corresponding to the package_key,
    0 otherwise. Uses a cached value for performance.
} {
    if { [util_memoize_initialized_p] } {
        return [util_memoize [list apm_package_installed_p_not_cached $package_key]]
    } else {
        return [apm_package_installed_p_not_cached $package_key]
    }
}

ad_proc -private apm_package_installed_p_not_cached {
    package_key
} {
    return [db_string apm_package_installed_p {
        select exists (select 1 from apm_package_versions
                        where package_key = :package_key
                          and installed_p) from dual
    }]
}

ad_proc -public apm_package_enabled_p {
    package_key
} {
    Returns 1 if there is an enabled package version corresponding to the package_key
    and 0 otherwise.
} {
    return [db_string apm_package_enabled_p {} -default 0]
}

ad_proc -public apm_enabled_packages {} {
    Returns a list of package_key's for all enabled packages.

    @author Peter Marklund
} {
    return [db_list enabled_packages {}]
}


ad_proc -public apm_version_installed_p {
    version_id
} {
    @return Returns 1 if the specified version_id is installed, 0 otherwise.
} {
    return [db_string apm_version_installed_p {} -default 0]
}

ad_proc -public apm_highest_version {package_key} {
    Return the highest version of the indicated package.
    @return the version_id of the highest installed version of a package.
} {
    return [db_exec_plsql apm_highest_version {}]
}

ad_proc -public apm_highest_version_name {package_key} {
    Return the highest version of the indicated package.
    @return the version_name of the highest installed version of a package.
} {
    return [db_string apm_highest_version_name {} -default ""]
}

ad_proc -public apm_num_instances {package_key} {

    @return The number of instances of the indicated package.
} {
    return [db_string query {
        select count(*) from apm_packages
        where package_key = :package_key
    }]
}

ad_proc -public apm_parameter_update {
    {-callback apm_dummy_callback}
    parameter_id
    package_key
    parameter_name
    description
    default_value
    datatype
    {section_name ""}
    {min_n_values 1}
    {max_n_values 1}
} {
    @return The parameter id that has been updated.
} {
    if {$section_name eq ""} {
        set section_name [db_null]
    }

    db_dml parameter_update {
        update apm_parameters
        set parameter_name = :parameter_name,
        default_value  = :default_value,
        datatype       = :datatype,
        description       = :description,
        section_name   = :section_name,
        min_n_values   = :min_n_values,
        max_n_values   = :max_n_values
        where parameter_id = :parameter_id
    }

    db_dml object_title_update {
        update acs_objects
        set title = :parameter_name
        where object_id = :parameter_id
    }

    return $parameter_id
}

ad_proc -public apm_parameter_register {
    {-callback apm_dummy_callback}
    {-parameter_id ""}
    {-scope instance}
    parameter_name
    description
    package_key
    default_value
    datatype
    {section_name ""}
    {min_n_values 1}
    {max_n_values 1}
} {
    Register a parameter in the system.

    The new "scope" parameter is named rather than positional to avoid breaking existing
    code.

    @return The parameter id of the new parameter.

} {
    if {$parameter_id eq ""} {
        set parameter_id [db_null]
    }

    if {$section_name eq ""} {
        set section_name [db_null]
    }

    ns_log debug "apm_parameter_register: Registering $parameter_name, $section_name, $default_value"

    set parameter_id [db_exec_plsql parameter_register {}]

    # Propagate to descendents if it's an instance parameter.

    if { $scope eq "instance" } {
        apm_copy_param_to_descendents $package_key $parameter_name
    }

    # Update the cache.
    db_foreach apm_parameter_cache_update {} {
        ad_parameter_cache -set $attr_value $package_id $parameter_name
    }
    return $parameter_id
}

ad_proc -public apm_parameter_unregister {
    {-callback apm_dummy_callback}
    {-package_key ""}
    {-parameter ""}
    parameter_id
} {
    Unregisters a parameter from the system.
} {
    if { $parameter_id eq "" } {
        set parameter_id [db_string select_parameter_id {}]
    }

    db_1row get_scope_and_name {}

    ns_log Debug "apm_parameter_unregister: Unregistering parameter $parameter_id."

    if { $scope eq "global" } {
        ad_parameter_cache -delete $package_key $parameter_name
    } else {
        db_foreach all_parameters_packages {} {
            ad_parameter_cache -delete $package_id $parameter_name
        }
    }
    db_exec_plsql unregister {}
}

ad_proc -public apm_dependency_add {
    {-callback apm_dummy_callback}
    {-dependency_id ""}
    dependency_type
    version_id
    dependency_uri
    dependency_version
} {
    Add a dependency to a version.
    @return The id of the new dependency.
} {

    if {$dependency_id eq ""} {
        set dependency_id [db_null]
    }

    return [db_exec_plsql dependency_add {}]
}

ad_proc -public apm_dependency_remove {dependency_id} {

    Removes a dependency from the system.

} {
    db_exec_plsql dependency_remove {}
}

ad_proc -public apm_interface_add {
    {-callback apm_dummy_callback}
    {-interface_id ""}
    version_id
    interface_uri
    interface_version
} {

    Add a interface to a version.
    @return The id of the new interface.
} {

    if {$interface_id eq ""} {
        set interface_id [db_null]
    }

    return [db_exec_plsql interface_add {}]
}

ad_proc -public apm_interface_remove {interface_id} {

    Removes a interface from the system.

} {
    db_exec_plsql interface_remove {}
}

ad_proc -public apm_version_get {
    {-version_id ""}
    {-package_key ""}
    {-array:required}
} {
    Gets information about a package version. TODO: Cache this proc, put it in
    a namespace and make sure it's used everywhere.

    @param version_id The id of the package version to get info for
    @param package_key Can be specified instead of version_id in which case
    the live version of the package will be used.
    @param array      The name of the array variable to upvar the info to

    @author Peter Marklund
} {
    upvar $array row

    if { $package_key ne "" } {
        set version_id [apm_version_id_from_package_key $package_key]
    }

    db_1row select_version_info {} -column_array row
}

namespace eval ::acs {}
#
# package_id -> package_key
#

ad_proc -public apm_package_key_from_id {package_id} {
    @return The package key of the instance.
} {
    set key ::acs::apm_package_key_from_id($package_id)
    if {[info exists $key]} {return [set $key]}
    set $key [apm_package_key_from_id_mem $package_id]
}

ad_proc -private apm_package_key_from_id_mem {package_id} {
    unmemoized version of apm_package_key_from_id
} {
    return [db_string apm_package_key_from_id {
        select package_key from apm_packages where package_id = :package_id
    } -default ""]
}

#
# package_id -> instance_name
#

ad_proc -public apm_instance_name_from_id {package_id} {
    @return The name of the instance.
} {
    return [util_memoize [list apm_instance_name_from_id_mem $package_id]]
}

ad_proc -private apm_instance_name_from_id_mem {package_id} {
    unmemoized version of apm_instance_name_from_id
} {
    return [db_string apm_package_instance_name_from_id {
        select instance_name from apm_packages where package_id = :package_id
    } -default ""]
}


#
# package_key -> package_id
#

ad_proc -public apm_package_id_from_key {package_key} {
    @return The package id of the instance of the package.
    0 if no instance exists, error if several instances exist.
} {
    set var ::apm::package_id_from_key($package_key)
    if {[info exists $var]} {return [set $var]}
    set result [util_memoize [list apm_package_id_from_key_mem $package_key]]
    #set result [ns_cache_eval ns:memoize apm_package_id_from_key_$package_key [list apm_package_id_from_key_mem $package_key]]
    if {$result != 0} {
        set $var $result
    }
    return $result
}

ad_proc -private apm_package_id_from_key_mem {package_key} {
    unmemoized version of apm_package_id_from_key
} {
    return [db_string apm_package_id_from_key {
        select package_id from apm_packages where package_key = :package_key
    } -default 0]
}

ad_proc -public apm_package_ids_from_key {
    -package_key:required
    -mounted:boolean
} {
    @param package_key The package key we are looking for the package
    @param mounted Does the package have to be mounted?

    @return List of package ids of all instances of the package.
    Empty string
} {
    return [util_memoize [list apm_package_ids_from_key_mem -package_key $package_key -mounted_p $mounted_p]]
}

ad_proc -private apm_package_ids_from_key_mem {
    -package_key:required
    {-mounted_p "0"}
} {
    unmemoized version of apm_package_ids_from_key
} {

    if {$mounted_p} {
        set package_ids [list]
        db_foreach apm_package_ids_from_key {
            select package_id from apm_packages where package_key = :package_key
        } {
            if {"" ne [site_node::get_node_id_from_object_id -object_id $package_id] } {
                lappend package_ids $package_id
            }
        }
        return $package_ids
    } else {
        return [db_list apm_package_ids_from_key {
            select package_id from apm_packages where package_key = :package_key
        }]
    }
}

#
# package_id -> package_url
#

ad_proc -public apm_package_url_from_id {package_id} {
    Will return the first url found for a given package_id

    @return The package url of the instance of the package.
} {
    return [lindex [site_node::get_url_from_object_id -object_id $package_id] 0]
}

#
# package_key -> package_url
#

ad_proc -public apm_package_url_from_key {package_key} {
    @return The package url of the instance of the package.
    only valid for singleton packages.
} {
    return [apm_package_url_from_id [apm_package_id_from_key $package_key]]
}

#
# package_key -> version_id
#

ad_proc -public apm_version_id_from_package_key {
    {-all:boolean}
    package_key
} {
    Return the id of the (per default enabled) version of the given package_key.
    If no such version id can be found, returns the empty string.

    @param all when specified, return the enabled or disabled version_ids of the package_key.
    @param package_key
    @author Peter Marklund

    @return the supposedly unique version_id for the enabled package, or a list of
            all the enabled and disabled versions when -all flag is specified
} {
    if {$all_p} {
        return [db_list get_id {}]
    } else {
        return [db_string get_enabled_id {} -default ""]
    }
}

#
# version_id -> package_key
#

ad_proc -public apm_package_key_from_version_id {version_id} {
    Returns the package_key for the given APM package version id. Goes to the database
    the first time called and then uses a cached value. Calls the proc apm_package_key_from_version_id_mem.

    @author Peter Marklund (peter@collaboraid.biz)
} {
    return [util_memoize [list apm_package_key_from_version_id_mem $version_id]]

}

ad_proc -private apm_package_key_from_version_id_mem {version_id} {
    Returns the package_key for the given APM package version id. Goes to the database
    every time called.

    @author Peter Marklund (peter@collaboraid.biz)
} {
    return [db_string apm_package_id_from_key {
        select package_key from apm_package_version_info where version_id = :version_id
    } -default 0]
}

ad_proc -public apm_version_info {version_id} {

    Sets a set of common package information in the caller's environment.

} {

    uplevel 1 {
        db_1row apm_package_by_version_id {
            select pretty_name, version_name, package_key, installed_p, distribution_uri, tagged_p
            from apm_package_version_info where version_id = :version_id
        }
    }
}

ad_proc -public apm_package_version_installed_p {package_key version_name} {

    @return 1 if the indicated package version is installed, 0 otherwise.

} {
    return [db_0or1row apm_package_version_installed_p {
        select 1 from apm_package_versions
         where package_key  = :package_key
           and version_name = :version_name
    }]
}

ad_proc -public apm_package_version_enabled_p {version_id} {

    @return 1 if the indicated package version is installed, 0 otherwise.

} {
    return [db_string apm_package_version_enabled_p {}]
}


ad_proc -private apm_post_instantiation_tcl_proc_from_key { package_key } {
    Generates the name of the Tcl procedure we execute for
    post-instantiation.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-03-05

    @return The name of a Tcl procedure, if it exists, or empty string
    if no such Tcl procedure was found.
} {
    set procedure_name [string tolower "[string trim $package_key]_post_instantiation"]
    # Change all "-" to "_" to mimic our Tcl standards
    regsub -all {\-} $procedure_name "_" procedure_name
    if { [info commands ::$procedure_name] eq "" } {
        # No such procedure exists...
        return ""
    }
    # Procedure exists
    return $procedure_name
}


ad_proc -public apm_package_rename {
    {-package_id ""}
    {-instance_name:required}
} {
    Renames a package instance
} {
    if { $package_id eq "" } {
        set package_id [ad_conn package_id]
    }
    db_transaction {
        db_dml app_rename {
            update apm_packages
            set instance_name = :instance_name
            where package_id = :package_id
        }
        db_dml rename_acs_object {
            update acs_objects
            set title = :instance_name
            where object_id = :package_id
        }
    }
    foreach node_id [db_list nodes_to_sync {}] {
        site_node::update_cache -node_id $node_id
    }
}

ad_proc -public apm_set_callback_proc {
    {-version_id ""}
    {-package_key ""}
    {-type:required}
    proc
} {
    Set the name of an APM Tcl procedure callback for a certain package version.
    Checks if the callback already exists and updates if it does.
    If version_id is not supplied the id of the currently enabled version
    of the package will be used.

    @see apm_supported_callback_types

    @author Peter Marklund
} {
    apm_assert_callback_type_supported $type

    if { $version_id eq "" } {
        if { $package_key eq "" } {
            error "apm_set_package_callback_proc: Invoked with both version_id and package_key empty. You must supply either of these"
        }

        set version_id [apm_version_id_from_package_key $package_key]
    }

    set current_proc [apm_get_callback_proc -type $type -version_id $version_id]

    if { $current_proc eq "" } {
        # We are adding
        db_dml insert_proc {}
    } else {
        # We are editing
        db_dml update_proc {}
    }
}

ad_proc -public apm_get_callback_proc {
    {-type:required}
    {-package_key ""}
    {-version_id ""}
} {
    Return Tcl procedure name for the callback of a certain
    type for the given package. If no callback proc for the
    given type is present returns the empty string.

    @see apm_supported_callback_types

    @author Peter Marklund
} {
    apm_assert_callback_type_supported $type

    if { $version_id eq "" } {
        set version_id [apm_version_id_from_package_key $package_key]
    }
    return [db_string select_proc {} -default ""]
}

ad_proc -public apm_remove_callback_proc {
    {-type:required}
    {-package_key:required}
} {
    Remove the callback of a certain type for the given package.

    @author Peter Marklund
} {
    apm_assert_callback_type_supported $type

    return [db_dml delete_proc {}]
}

ad_proc -public apm_unused_callback_types {
    {-version_id:required}
} {
    Get a list enumerating the supported callback types
    that are not used by the given package version.
} {
    set used_callback_types [db_list used_callback_types {
        select distinct type
        from apm_package_callbacks
        where version_id = :version_id
    }]

    set supported_types [apm_supported_callback_types]

    set unused_types [list]
    foreach supported_type $supported_types {
        if {$supported_type ni $used_callback_types} {
            lappend unused_types $supported_type
        }
    }

    return $unused_types
}

ad_proc -public apm_invoke_callback_proc {
    {-proc_name {}}
    {-version_id ""}
    {-package_key ""}
    {-arg_list {}}
    {-type:required}
} {
    Invoke the Tcl callback proc of a given type
    for a given package version. Any errors during
    invocation are logged.

    @param proc_name if this is provided it is called
    instead of attempting to look up the proc via the package_key or version_id
    (needed for before-install callbacks since the db is not populated when those
     are called).

    @return 1 if invocation
    was carried out successfully, 0 if no proc to invoke could
    be found. Will propagate any error thrown by the callback.

    @author Peter Marklund
} {
    array set arg_array $arg_list

    if {$proc_name eq ""} {
        set proc_name [apm_get_callback_proc \
                           -version_id $version_id \
                           -package_key $package_key \
                           -type $type]
    }

    if { $proc_name eq "" } {
        if {$type eq "after-instantiate"} {
            # We check for the old proc on format: package_key_post_instantiation package_id
            if { $package_key eq "" } {
                set package_key [apm_package_key_from_version_id $version_id]
            }
            set proc_name [apm_post_instantiation_tcl_proc_from_key $package_key]
            if { $proc_name eq "" } {
                # No callback and no old-style callback proc - no options left
                return 0
            }

            {*}$proc_name $arg_array(package_id)

            return 1

        } else {
            # No other callback procs to fall back on
            return 0
        }
    }

    # We have a non-empty name of a callback proc to invoke
    # Form the full command including arguments
    set command [list {*}$proc_name {*}[apm_callback_format_args -type $type -arg_list $arg_list]]

    # We are ready for invocation
    ns_log notice "apm_invoke_callback_proc: invoking callback $type with command <$command>"
    {*}$command

    return 1
}

ad_proc -public apm_assert_callback_type_supported { type } {
    Throw an error if the given callback type is not supported.

    @author Peter Marklund
} {
    if { ![apm_callback_type_supported_p $type]  } {
        error "The supplied callback type $type is not supported. Supported types are: [apm_supported_callback_types]"
    }
}

ad_proc -public apm_callback_type_supported_p { type } {
    Return 1 if the given type of callback is supported and 0
    otherwise.

    @author Peter Marklund
} {
    return [expr {$type in [apm_supported_callback_types]}]
}

ad_proc -public apm_callback_format_args {
    {-version_id ""}
    {-package_key ""}
    {-type:required}
    {-arg_list {}}
} {
    Return a string on format -arg_name1 arg_value1 -arg_name2 arg_value2 ...
    for the callback proc of given type.

    @author Peter Marklund
} {
    array set args_array $arg_list

    set arg_string ""
    set provided_arg_names [array names args_array]
    foreach required_arg_name [apm_arg_names_for_callback_type -type $type] {
        if {$required_arg_name ni $provided_arg_names} {
            error "required argument $required_arg_name not supplied to callback proc of type $type"
        }

        append arg_string " -${required_arg_name} $args_array($required_arg_name)"
    }

    return $arg_string
}

ad_proc -public apm_arg_names_for_callback_type {
    {-type:required}
} {
    Return the list of required argument names for the given callback type.

    @author Peter Marklund
} {
    array set arguments {
        after-instantiate {
            package_id
        }
        before-uninstantiate {
            package_id
        }
        before-unmount {
            package_id
            node_id
        }
        after-mount {
            package_id
            node_id
        }
        before-upgrade {
            from_version_name
            to_version_name
        }
        after-upgrade {
            from_version_name
            to_version_name
        }
    }

    if { [info exists arguments($type)] } {
        return $arguments($type)
    } else {
        return {}
    }
}

ad_proc -public apm_supported_callback_types {} {
    Gets the list of package callback types
    that are supported by the system.
    Each callback type represents a certain event or time
    when a Tcl procedure should be invoked, such as after-install

    @author Peter Marklund
} {
    return {
        before-install
        after-install
        before-upgrade
        after-upgrade
        before-uninstall
        after-instantiate
        before-uninstantiate
        after-mount
        before-unmount
    }
}

ad_proc -private apm_callback_has_valid_args {
    {-type:required}
    {-proc_name:required}
} {
    Returns 1 if the specified callback proc of a certain
    type has a valid argument list in its definition and 0
    otherwise. Assumes that the callback proc is defined with
    ad_proc.

    @author Peter Marklund
} {

    if { [info commands ::$proc_name] eq "" } {
        return 0
    }

    set test_arg_list ""
    set test_arg_list_spec ""
    foreach arg_name [apm_arg_names_for_callback_type -type $type] {
        lappend test_arg_list -$arg_name value
        lappend test_arg_list_spec -${arg_name}:required
    }

    if { $test_arg_list eq "" } {
        # The callback proc should take no args
        return [expr {[info args ::$proc_name] eq ""}]
    }

    if {[info commands ::nsf::cmd::info] ne ""} {
        #
        # We can compare the signature of via nsf procs
        #
        return [expr {[::nsf::cmd::info parameter ::$proc_name] eq $test_arg_list_spec}]

    }

    # The callback proc should have required arg switches. Check
    # that the ad_proc arg parser doesn't throw an error with
    # test arg list
    if { [catch {
        set args $test_arg_list
        ::${proc_name}__arg_parser
    } errmsg] } {
        return 0
    } else {
        return 1
    }
}

ad_proc -public apm_package_instance_new {
    {-package_key:required}
    {-instance_name ""}
    {-package_id ""}
    {-context_id ""}
} {

    Creates a new instance of a package and calls the post instantiation proc, if any. If the
    package is a singleton and already exists then this procedure will silently do nothing.

    @param package_key   The package_key of the package to instantiate.
    @param instance_name The name of the package instance, defaults to the pretty name of the
    package type.
    @param package_id    The id of the new package. Optional.
    @param context_id    The context_id of the new package. Optional.

    @return The id of the instantiated package
} {
    if { $instance_name eq "" } {
        set p_name [apm::package_version::attributes::get_instance_name $package_key]

        if {$p_name eq ""} {
            set instance_name [db_string pretty_name_from_key {select pretty_name
                from apm_enabled_package_versions
                where package_key = :package_key}]
        } else {
            set instance_name  "$p_name"
        }
    }

    if { $package_id eq "" } {
        set package_id [db_null]
    }

    set package_id [db_exec_plsql invoke_new {}]

    apm_parameter_sync $package_key $package_id

    foreach inherited_package_key [nsv_get apm_package_inherit_order $package_key] {
        apm_invoke_callback_proc \
            -package_key $inherited_package_key \
            -type after-instantiate \
            -arg_list [list package_id $package_id]
    }

    return $package_id
}

ad_proc apm_parameter_sync {package_key package_id} {

    Syncs the parameters in the database with the memory cache.  This must be called
    after creating a new package instance.

} {

    # Get all the parameter names and values for this package_id.
    set names_and_values [db_list_of_lists apm_parameter_names_and_values {
        select parameter_name, attr_value
        from apm_parameters p, apm_parameter_values v, apm_packages a
        where p.parameter_id = v.parameter_id
        and a.package_id = v.package_id
        and a.package_id = :package_id
    }]

    # Put it in the cache.
    foreach name_value_pair $names_and_values {
        ad_parameter_cache -set [lindex $name_value_pair 1] $package_id [lindex $name_value_pair 0]
    }
}

ad_proc -public apm_package_instance_delete {
    package_id
} {
    Deletes an instance of a package
} {
    set package_key [apm_package_key_from_id $package_id]
    # ns_log notice "apm_package_instance_delete inherit order [nsv_get apm_package_inherit_order $package_key]"
    if {[nsv_exists apm_package_inherit_order $package_key]} {
        foreach inherited_package_key [nsv_get apm_package_inherit_order $package_key] {
            apm_invoke_callback_proc \
                -package_key $inherited_package_key \
                -type before-uninstantiate \
                -arg_list [list package_id $package_id]
        }
    }

    db_exec_plsql apm_package_instance_delete {}
}

ad_proc -public apm_get_installed_versions {
    -array:required
} {
    Sets the current installed version of packages installed on this system
    in an array keyed by package_key.

    @param array Name of array in caller's namespace where you want this set
} {
    upvar 1 $array installed_version

    db_foreach installed_packages {
        select package_key, version_name
        from   apm_package_versions
        where  enabled_p = 't'
    } {
        set installed_version($package_key) $version_name
    }
}

ad_proc -public apm_get_installed_provides {
    -array:required
} {
    Sets the dependencies provided by the packages installed on this system
    in an array keyed by dependency service-uri.

    @param array Name of array in caller's namespace where you want this set
} {
    upvar 1 $array installed_provides

    # All packages provides themselves
    apm_get_installed_versions -array installed_provides

    # Now check what the provides clauses say
    db_foreach installed_provides {
        select service_uri,
        service_version
        from   apm_package_dependencies d,
        apm_package_versions v
        where  d.dependency_type = 'provides'
        and    d.version_id = v.version_id
        and    v.enabled_p = 't'
    } {
        if { ![info exists installed_provides($service_uri)]
             || [apm_version_names_compare $installed_provides($service_uri) $service_version] == -1
         } {
            set installed_provides($service_uri) $service_version
        }
    }
}


##
## Logging
##

ad_proc -public apm_log {
    level
    msg
} {
    Centralized APM logging. If you want to debug the APM, change
    APMDebug to Debug and restart the server.
} {
    if {"APMDebug" ne $level } {
        ns_log $level $msg
    }
}

ad_proc -private apm_application_new_checkbox {} {
    Return an HTML checkbox of package_key and package names
    for applications that can be mounted in the site-map. Excludes
    singletons that are already instantiated.

    @author Peter Marklund
} {
    set options [list]
    db_foreach package_types {
         select package_key, pretty_name
         from apm_package_types t
         where not (singleton_p and exists (select 1 from apm_packages
                                             where package_key = t.package_key))
         order by pretty_name
    } {
        lappend options [subst {<option value="$package_key">$pretty_name</option>}]
    }

    # If this is a site-wide admin, offer a link to the package manager
    if { [acs_user::site_wide_admin_p] } {
        lappend options {<option value="/new">--Install new package--</option>}
    }

    return [subst {<select name="package_key">[join $options]</select>}]
}

ad_proc -private apm::read_files {path file_list} {
    Read the contents from a list of files at a certain path. Return
    the data to the caller as a big string.
} {
    set data ""
    foreach file $file_list {
        if {![catch {set fp [open ${path}/${file} r]} err]} {
            append data [read $fp]
            close $fp
        }
    }
    return $data
}

ad_proc -public apm::metrics {
    -package_key
    -file_type
    -array
} {
    Return some code metrics about the files in package $package_key. This
    will return an array of 3 items:
    <ul>
    <li>count - the number of files</li>
    <li>lines - the number of lines in the files</li>
    <li>procs - the number of procs, if applicable (0 if not applicable)</li>
    </ul>
    This will be placed in the array variable that is provided
    to this proc.
    <p>
    Valid file_type's:
    <ul>
    <li>data_model_pg - PG datamodel files</li>
    <li>data_model_ora - Oracle datamodel files</li>
    <li>include_page - ADP files in package_key/lib</li>
    <li>content_page - ADP files in package_key/www</li>
    <li>tcl_procs - Tcl procs in package_key/tcl</li>
    <li>test_procs - automated tests in package_key/tcl/test</li>
    <li>documentation - docs in package_key/www/doc</li>
    </ul>

    This proc is cached.

    @author Vinod Kurup
    @creation-date 2006-02-09

    @param package_key The package_key of interest
    @param file_type See options above
    @param array variable to hold the array that will be returned
} {
    upvar $array metrics
    array set metrics [util_memoize [list apm::metrics_internal $package_key $file_type]]
}

ad_proc -private apm::metrics_internal {
    package_key
    file_type
} {
    The cached version of apm::metrics

    @see apm::metrics
} {
    array set metrics {}
    set package_path [acs_package_root_dir $package_key]

    # We'll be using apm_get_package_files to get a list of files
    # by file type.

    switch -- $file_type {
        data_model_pg -
        data_model_ora {
            set file_types [list data_model_create data_model]
        }
        default {
            set file_types $file_type
        }
    }

    set filelist [apm_get_package_files \
                      -all_db_types \
                      -package_key $package_key \
                      -file_types $file_types]

    # filelist needs to be weeded for certain file types
    switch -- $file_type {
        include_page -
        content_page {
            # weed out non-.adp files
            set adp_files {}
            foreach file $filelist {
                if { [string match {*.adp} $file] } {
                    lappend adp_files $file
                }
            }
            set filelist $adp_files
        }
        data_model_pg {
            # ignore drop and upgrade scripts
            set pg_files {}
            foreach file $filelist {
                if { [string match {*/postgresql/*} $file]
                     && ![string match "*-drop.sql" $file]
                     && ![string match {*/upgrade/*} $file]
                 } {
                    lappend pg_files $file
                }
            }
            set filelist $pg_files
        }
        data_model_ora {
            # ignore drop and upgrade scripts
            set ora_files {}
            foreach file $filelist {
                if { [string match {*/oracle/*} $file]
                     && ![string match "*-drop.sql" $file]
                     && ![string match {*/upgrade/*} $file]
                 } {
                    lappend ora_files $file
                }
            }
            set filelist $ora_files
        }
    }

    # read the files, so we can count lines and grep for procs
    set filedata [apm::read_files $package_path $filelist]

    # The first 2 metrics are easy (file count and line count)
    set metrics(count) [llength $filelist]
    set metrics(lines) [llength [split $filedata \n]]

    # extract procs, depending on the file_type
    switch -exact $file_type {
        tcl_procs {
            set metrics(procs) [regexp -all -line {^\s*ad_proc} $filedata]
        }
        test_procs {
            set metrics(procs) [regexp -all -line {^\s*aa_register_case} $filedata]
        }
        data_model_pg {
            set metrics(procs) [regexp -all -line -nocase {^\s*create\s+or\s+replace\s+function\s+} $filedata]
        }
        data_model_ora {
            set metrics(procs) [expr {[regexp -all -line -nocase {^\s+function\s+} $filedata] +
                                      [regexp -all -line -nocase {^\s+procedure\s+} $filedata]}]
        }
        default {
            # other file-types don't have procs
            set metrics(procs) 0
        }
    }

    return [array get metrics]
}

ad_proc -public apm::get_package_descendent_options {
    package_key
} {
    Get a list of pretty name, package key pairs for all packages which are descendents
    of the given package key.

    @param package_key The parent package's key.
    @return a list of pretty name, package key pairs suitable for use in a template
    select widget.
} {
    set in_clause '[join [::apm_package_descendents $package_key] ',']'
    return [db_list_of_lists get {}]
}


ad_proc -public apm::convert_type {
    -package_id:required
    -old_package_key:required
    -new_package_key:required
} {
    Convert a package instance to a new type, doing the proper instantiate and mount callbacks and
    parameter creation.

    @param package_id The package instance to convert.
    @param old_package_key The package key we're converting from.
    @param new_package_key The new subsite type we're converting to.

} {
    db_dml update_package_key {}
    util_memoize_flush "apm_package_key_from_id_mem $package_id"

    set node_id [site_node::get_node_id_from_object_id -object_id $package_id]
    if { $node_id ne "" } {
        site_node::update_cache -node_id $node_id
    }

    # DRB: parameter fix!
    db_foreach get_params {} {
        db_1row get_new_parameter_id {}
        db_dml update_param {}
    }
    db_list copy_new_params {}
    apm_parameter_sync $new_package_key $package_id

    foreach inherited_package_key [::apm_package_inherit_order $new_package_key] {
        if {$inherited_package_key ni [::apm_package_inherit_order $old_package_key]} {
            apm_invoke_callback_proc \
                -package_key $inherited_package_key \
                -type after-instantiate \
                -arg_list [list package_id $package_id]
            if { $node_id ne "" } {
                apm_invoke_callback_proc \
                    -package_key $inherited_package_key \
                    -type after-mount \
                    -arg_list [list node_id $node_id package_id $package_id]
            }
        }
    }

}


#
### Deprecated procs
#

# apisano 2018-05-14: there is a thread cache for this now, no need
# IMO to maintain a datamodel to know which databases we
# support. Original code is the commented one.
ad_proc -deprecated -private apm_pretty_name_for_db_type { db_type } {

    Returns the pretty name corresponding to a particular file type key
    (memoizing to save a database hit here and there).

} {
    set pos [lsearch -index 0 -exact $::acs::known_database_types $db_type]
    return [lindex [lindex $::acs::known_database_types $pos] 2]
    # return [util_memoize [list db_string pretty_db_name_select "
    #     select pretty_db_name
    #     from apm_package_db_types
    #     where db_type_key = :db_type
    # " -default "all" -bind [list db_type $db_type]]]
}


#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
