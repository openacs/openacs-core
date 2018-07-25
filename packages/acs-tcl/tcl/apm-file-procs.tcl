ad_library {

    Functions that APM uses to interact with the file system and I/O.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Fri Oct  6 21:46:05 2000
    @cvs-id $Id$
}


ad_proc -private apm_mkdir {path} {

    Creates the directory specified by path and returns it.

} {
    if { [catch {
        file mkdir $path
    }] } {
        # There must be a file blocking the directory creation.
        if { [catch {
            file delete -force -- $path
            file mkdir $path
        } errmsg]} {
            error "Error creating directory $path: $errmsg"
        }
    }
    return $path
}

ad_proc -public apm_workspace_dir {} {

    Return the path to the apm-workspace, creating the directory if necessary.

} {
    set path [file join $::acs::rootdir apm-workspace]
    if { [file isdirectory $path] } {
        return $path
    } else {
        return [apm_mkdir $path]
    }
}

ad_proc -public apm_workspace_install_dir {} {

    Return the path to the installation directory of the apm-workspace, creating
    the directory if necessary.
} {
    set base_path [apm_workspace_dir]
    set install_path "$base_path/install"
    if { [file isdirectory $install_path] } {
        return $install_path
    } else {
        return [apm_mkdir $install_path]
    }
}

ad_proc -public apm_file_type_names {} {
    Returns an array list with filetypes as keys and
    filetype pretty names as values.

    @author Peter Marklund
} {
    return {
        documentation "Documentation"
        tcl_procs "Tcl procedure library"
        tcl_init "Tcl initialization"
        tcl_util "Tcl utility script"
        content_page "Content page"
        package_spec "Package specification"
        sql_data "SQL Data"
        ctl_file "SQL data loader control"
        data_model "Data model"
        data_model_create "Data model installation"
        data_model_drop "Data model deinstallation"
        data_model_upgrade "Data model upgrade"
        java_code "Java code"
        java_archive "Java archive"
        query_file "Query file"
        template "Template file"
        shell "Shell utility"
        sqlj_code "SQLJ library"
        message_catalog "Message Catalog"
    }
}

ad_proc -public apm_file_type_keys {} {

    Returns a list of valid file type keys.

    @see apm_file_type_names
    @see apm_pretty_name_for_file_type

    @author Peter Marklund
} {
    array set file_type_names [apm_file_type_names]
    return [array names file_type_names]
}

ad_proc -public apm_package_info_file_path {
    {-path ""}
    package_key
} {

    Returns the path to a .info file in a package directory, or throws an
    error if none exists. Currently, only $package_key.info is recognized
    as a specification file.

} {
    if { $path eq "" } {
        set path [acs_package_root_dir $package_key]
    } else {
        set path $path/$package_key
    }
    if { [file exists $path/$package_key.info] } {
        return $path/$package_key.info
    }
    error "The directory $path does not contain a package specification file ($package_key.info)."
}


ad_proc -private apm_extract_tarball { version_id dir } {

    Extracts a distribution tarball into a particular directory,
    overwriting any existing files.
    DCW - 2001-05-03, modified to extract tarball from content repository.

} {

    set apm_file [ad_tmpnam]

    db_blob_get_file distribution_tar_ball_select {
        select content
        from cr_revisions
        where revision_id = (select content_item.get_latest_revision(item_id)
                             from apm_package_versions
                             where version_id = :version_id)
    } $apm_file

    file mkdir $dir
    # avoid chdir
    #ns_log notice "exec sh -c 'cd $dir ; [apm_gzip_cmd] -d -q -c $apm_file | [apm_tar_cmd] xf - 2>/dev/null'"
    exec [apm_gzip_cmd] -d -q -c -S .apm $apm_file | [apm_tar_cmd] -xf - -C $dir 2> [apm_dev_null]

    file delete -- $apm_file
}


ad_proc -private apm_generate_tarball { version_id } {

    Generates a tarball for a version, placing it in the content repository.
    DCW - 2001-05-03, change to use the content repository for tarball storage.

} {
    set package_key [apm_package_key_from_version_id $version_id]
    set files [apm_get_package_files -all -package_key $package_key]
    set tmpfile [ad_tmpnam]

    db_1row package_key_select {}

    # Generate a command like:
    #
    #   tar cf - -C /web/arsdigita/packages acs-kernel/00-proc-procs.tcl \
        #                 -C /web/arsdigita/packages 10-database-procs.tcl ...  \
        #     | gzip -c > $tmpfile
    #
    # Note that -C changes the working directory before compressing the next
    # file; we need this to ensure that the tarballs are relative to the
    # package root directory ($::acs::rootdir/packages).

    set cmd [list exec [apm_tar_cmd] cf - 2> [apm_dev_null]]
    foreach file $files {
        lappend cmd -C "$::acs::rootdir/packages"
        lappend cmd "$package_key/$file"
    }

    lappend cmd "|" [apm_gzip_cmd] -c ">" $tmpfile
    {*}$cmd

    # At this point, the APM tarball is sitting in $tmpfile. Save it in
    # the database.

    set creation_ip [ad_conn peeraddr]
    set user_id     [ad_conn user_id]
    set name        "tarball-for-package-version-${version_id}"
    set title       "${package_key}-tarball"
    set description "gzipped tarfile"
    set mime_type   "text/plain"

    db_1row item_exists_p {}

    if {!$item_id} {
        # content item hasen't been created yet - create one.
        set item_id [content::item::new \
                         -name          $name \
                         -title         $title \
                         -description   $description \
                         -mime_type     $mime_type \
                         -creation_user $user_id \
                         -creation_ip   $creation_ip \
                         -is_live       true]

        db_dml set_item_id {}
    }

    set revision_id [content::item::get_live_revision -item_id $item_id]

    # No live revision for this item. Possible if somebody already
    # generated the archive, then deleted or modified the revision
    # manually or by other means. We create a new live revision.
    if {$revision_id eq ""} {
        set revision_id [content::revision::new -item_id $item_id \
                             -title         $title \
                             -description   $description \
                             -mime_type     $mime_type \
                             -creation_user $user_id \
                             -creation_ip   $creation_ip \
                             -is_live       true]
    }

    db_dml update_tarball {} -blob_files [list $tmpfile]

    db_dml update_content_length {}

    file delete -- $tmpfile
}


ad_proc -private apm_files_load {
    {-force_reload:boolean 0}
    {-callback apm_dummy_callback}
    files
} {

    Load the set of files into the currently running Tcl interpreter.
    @param force_reload Indicates if the file should be loaded even if it \
        is already loaded in the interpreter.
} {
    # This will be the first time loading for each of these files (since if a
    # file has already been loaded, we just skip it in the loop below).
    global apm_first_time_loading_p
    set apm_first_time_loading_p 1

    global apm_current_package_key

    foreach file_info $files {
        lassign $file_info package_key path

        if { $force_reload_p || ![nsv_exists apm_library_mtime packages/$package_key/$path] } {
            if { [file exists "$::acs::rootdir/packages/$package_key/$path"] } {
                apm_callback_and_log $callback "Loading packages/$package_key/$path..."
                set apm_current_package_key $package_key

                apm_source "$::acs::rootdir/packages/$package_key/$path"

                # Release outstanding database handles (in case this file
                # used the db_* database API and a subsequent one uses
                # ns_db).
                db_release_unused_handles

                apm_callback_and_log $callback "Loaded packages/$package_key/$path."
                unset apm_current_package_key
            } else {
                apm_callback_and_log $callback "Unable to load packages/$package_key/$path - file is marked as contained in a package but is not present in the filesystem"
            }
        }
    }
    unset apm_first_time_loading_p
}

ad_proc -public apm_file_watch {path} {

    Marks the file of the indicated path to be watched.  If the file changes,
    it will be reloaded prior to the next page load.

    @param path The path of the file relative to server root
} {
    if {$path eq "packages/acs-bootstrap-installer/tcl/30-apm-load-procs.tcl"} {
        ns_log Warning "apm_file_watch: Skipping file $path as it cannot be watched. You have to restart the server instead"
    }

    nsv_set apm_reload_watch $path 1
}

ad_proc -public apm_file_watch_cancel {
    {path ""}
} {
    Stop watching a certain file, or all watched files if path
    is not specified. If the file is not watched
    this procedure does nothing.

    @param path The path relative to server root of the file to stop watching. Optional.

    @author Peter Marklund
} {
    if { $path ne "" } {
        catch { nsv_unset apm_reload_watch $path }
    } else {
        catch {nsv_unset apm_reload_watch}
    }
}

ad_proc -public apm_file_watchable_p { path } {
    Given the path of a file determine if it is
    appropriate to be watched for reload. The file should
    be db compatible with the system and be of right
    type (for example contain Tcl procs or xql queries).

    @param path The path of the file relative to server root

    @return 1 If file is watchable and 0 otherwise. The proc will throw an error if the
    file doesn't exist or if the given path cannot be parsed as a path relative
    to server root.

    @see apm_guess_file_type
    @see apm_guess_db_type

    @author Peter Marklund
} {
    # The apm_guess procs need package_key and a path relative to package root
    # so parse those out of the given path
    if { [regexp {^packages/([^/]+)/(.*)$} $path match package_key package_rel_path] } {
        if { ![file exists "$::acs::rootdir/$path"] } {
            error "apm_file_watchable_p: path $path does not correspond to an existing file"
        }
    } else {
        error "apm_file_watchable_p: path $path cannot be parsed as a path relative to server root"
    }

    # Check the db type
    set file_db_type [apm_guess_db_type $package_key $package_rel_path]
    set right_db_type_p [expr {$file_db_type eq "" || $file_db_type eq [db_type]}]

    # Check the file type
    set file_type [apm_guess_file_type $package_key $package_rel_path]
    # I would like to add test_procs to the list but currently test_procs files are used to register test cases
    # and we don't want to resource these files in every interpreter. Test procs should be defined in test_init files.
    set watchable_file_types [list tcl_procs query_file test_procs]
    set right_file_type_p [expr {$file_type in $watchable_file_types}]

    # Both db type and file type must be right
    set watchable_p [expr {$right_db_type_p && $right_file_type_p}]

    return $watchable_p
}

ad_proc -private apm_watch_all_files { package_key } {
    Watch all Tcl procs and xql query files in the given
    package

    @see apm_file_watch
    @see apm_get_watchable_files

    @author Peter Marklund
} {
    foreach rel_path [apm_get_watchable_files $package_key] {
        apm_file_watch $rel_path
    }
}

ad_proc -private apm_cancel_all_watches { package_key } {
    Cancel all watches in the given package.

    @param package_key The package_key of the package to stop watching.

    @see apm_file_watch_cancel
    @see apm_get_watchable_files

    @author Peter Marklund
} {
    foreach rel_path [apm_get_watchable_files $package_key] {
        apm_file_watch_cancel $rel_path
    }
}

ad_proc -private apm_get_watchable_files { package_key } {
    Get a list of paths relative to server root of watchable
    files in the given package

    @param package_key Key of the package to get paths for

    @author Peter Marklund
} {
    set watchable_files [list]

    set files [ad_find_all_files $::acs::rootdir/packages/$package_key]
    foreach file [lsort $files] {
        set rel_path [ad_make_relative_path $file]
        if { [apm_file_watchable_p $rel_path] } {
            lappend watchable_files $rel_path
        }
    }

    return $watchable_files
}


ad_proc -private apm_system_paths {} {

    @return a list of acceptable system paths to search for executables in.

} {
    set paths [ad_parameter_all_values_as_list -package_id [ad_acs_kernel_id] SystemCommandPaths acs-kernel]
    if {$paths eq ""} {
        return [list "/usr/local/bin" "/usr/bin" "/bin" "/usr/sbin" "/sbin" "/usr/sbin"]
    } else {
        return $paths
    }
}

ad_proc -public apm_gzip_cmd {} {

    @return A valid command name for gzip.

} {
    return gzip
}


ad_proc -private apm_tar_cmd {} {

    @return A valid command name for tar.

} {
    return tar
}


ad_proc -private apm_dev_null {} {

    @return null device

} {
    if {$::tcl_platform(platform) ne "windows"} {
        return /dev/null
    } else {
        return nul
    }
}

ad_proc -private apm_transfer_file {
    {-url}
    {-output_file_name}
} {
    #
    # The original solution using ns_httpopen + file_copy does not work
    # reliably under windows, for unknown reasons the downloaded file is
    # truncated.
    #
    # Therefore, we check first for the NaviServer built in ns_http, then
    # if the optional xotcl-core components are available...
    #

    # 5 minutes
    set timeout 300

    set httpImpls [util::http::available -url $url -spool]
    if {$httpImpls ne ""} {
        ns_log notice "we can use the http::util:: interface using the $httpImpls implementation"
        set result [util::http::get -url $url -timeout $timeout -spool]
        file rename [dict get $result file] $output_file_name
    } elseif {[info commands ::ns_http] ne "" && [apm_version_names_compare [ns_info patchlevel] "4.99.5"] == 1} {
        #
        # ... use ns_http when we have a version with the "-file" flag ...
        #
        foreach i {1 2 3} {
            ns_log notice "Transfer $url to $output_file_name based on ns_http"
            set h [ns_http queue -timeout $timeout:0 $url]
            set replyHeaders [ns_set create]
            ns_http wait -file F -headers $replyHeaders -spoolsize 1 $h
            if {[file exists $output_file_name]} {file delete -- $output_file_name}
            file rename -- $F $output_file_name
            set location [ns_set iget $replyHeaders location]
            if {$location eq ""} break
            ns_log notice "Transfer $url redirected to $location ..."
            set url $location
        }
    } elseif {[info commands ::xo::HttpRequest] ne ""} {
        #
        # ... use xo::HttpRequest...
        #
        ns_log notice "Transfer $url to $output_file_name based on ::xo::HttpRequest"
        #
        set r [::xo::HttpRequest new -url $url]
        set fileChan [open $output_file_name w 0640]
        fconfigure $fileChan -translation binary -encoding binary
        puts -nonewline $fileChan [$r set data]
        close $fileChan

    } elseif {[set wget [::util::which wget]] ne ""} {
        #
        # ... if we have no ns_http, no ::xo::* and we have "wget"
        # installed, we use it.
        #
        ns_log notice "Transfer $url to $output_file_name based on wget"
        catch {exec $wget -O $output_file_name $url}

    } else {
        #
        # Everything else failed, fall back to the original solution.
        #
        ns_log notice "Transfer $url to $output_file_name based on ns_httpopen"
        # Open a destination file.
        set fileChan [open  $output_file_name w 0640]
        # Open the channel to the server.
        set httpChan [lindex [ns_httpopen GET $url] 0]
        ns_log Debug "APM: Copying data from $url"
        fconfigure $httpChan -encoding binary
        fconfigure $fileChan -encoding binary
        # Copy the data
        fcopy $httpChan $fileChan
        # Clean up.
        ns_log Debug "APM: Done copying data."
        close $httpChan
        close $fileChan
    }
}

ad_proc -private apm_load_apm_file {
    {-callback apm_dummy_callback}
    {-url {}}
    {file_path {}}
} {

    Uncompresses and loads an APM file into the filesystem.

    @param url If specified, will download the APM file first.

    @return If successful, a path to the .info file of the package uncompressed
    into the apm-workspace directory

} {
    # First download the apm file if a URL is provided
    if { $url ne "" } {
        set file_path [ad_tmpnam].apm
        apm_callback_and_log $callback "<li>Downloading $url..."
        if { [catch {apm_transfer_file -url $url -output_file_name $file_path} errmsg] } {
            apm_callback_and_log $callback "Unable to download. Please check your URL.</ul>.
            The following error was returned: <blockquote><pre>[ns_quotehtml $errmsg]
            </pre></blockquote>"
            return
        }

        if {![file exists $file_path]} {
            apm_callback_and_log $callback  "
            The file cannot be found.  Your URL or your file name is incorrect.  Please verify that the file name
            is correct and try again."
            ns_log Error "Error loading APM file form url $url: The file cannot be found."
            return
        }
    }

    #ns_log notice "*** try to exec [apm_gzip_cmd] -d -q -c -S .apm $file_path | [apm_tar_cmd] tf - 2> [apm_dev_null]"
    if { [catch {
        set files [split [string trim \
                              [exec [apm_gzip_cmd] -d -q -c -S .apm $file_path | [apm_tar_cmd] tf - 2> [apm_dev_null]]] "\n"]
        apm_callback_and_log $callback  "<li>Done. Archive is [format %.1f [expr { [file size $file_path] / 1024.0 }]]KB, with [llength $files] files.<li>"
    } errmsg] } {
        apm_callback_and_log $callback "The follow error occurred during the uncompression process:
    <blockquote><pre>[ns_quotehtml $errmsg]</pre></blockquote><br>
    "
                ns_log Error "Error loading APM file form url $url: $errmsg\n$::errorInfo"
        return
    }

    if { [llength $files] == 0 } {
        apm_callback_and_log $callback  "The archive does not contain any files.\n"
        ns_log Error "Error loading APM file form url $url: The archive does not contain any files."
        return
    }

    set package_key [lindex [split [lindex $files 0] "/"] 0]

    # Find that .info file.
    foreach file $files {
        set components [split $file "/"]

        if {[lindex $components 0] ne $package_key  } {
            apm_callback_and_log $callback  "All files in the archive must be contained in the same directory
        (corresponding to the package's key). This is not the case, so the archive is not
        a valid APM file.\n"
            ns_log Error "Error loading APM file form url $url: Invalid APM file. All files in the archive must be contained in the same directory corresponding to the package's key."
            return
        }

        if { [llength $components] == 2 && [file extension $file] eq ".info" } {
            if { [info exists info_file] } {
                apm_callback_and_log $callback  "The archive contains more than one <tt>package/*/*.info</tt> file, so it is not a valid APM file.</ul>\n"
                ns_log Error "Error loading APM file form url $url: Invalid APM file. More than one package .info file."
                return
            } else {
                set info_file $file
            }
        }
    }
    if { ![info exists info_file] || [regexp {[^a-zA-Z0-9\-\./_]} $info_file] } {
        apm_callback_and_log $callback  "The archive does not contain a <tt>*/*.info</tt> file, so it is not
        a valid APM file.</ul>\n"
        ns_log Error "Error loading APM file form url $url: Invalid APM file. No package .info file."
        return
    }

    apm_callback_and_log $callback  "Extracting the .info file (<tt>$info_file</tt>)..."
    set tmpdir [ad_tmpnam]
    file mkdir $tmpdir
    exec [apm_gzip_cmd] -d -q -c -S .apm $file_path | [apm_tar_cmd] -xf - -C $tmpdir $info_file 2> [apm_dev_null]

    #exec sh -c "cd $tmpdir ; [apm_gzip_cmd] -d -q -c -S .apm $file_path | [apm_tar_cmd] xf - $info_file" 2> [apm_dev_null]

    if { [catch {
        array set package [apm_read_package_info_file [file join $tmpdir $info_file]]
    } errmsg]} {
        file delete -force -- $tmpdir
        apm_callback_and_log $callback  "The archive contains an unparseable package specification file:
    <code>$info_file</code>.  The following error was produced while trying to
    parse it: <blockquote><pre>[ns_quotehtml $errmsg]</pre></blockquote>.
    <p>
    The package cannot be installed.
    </ul>\n"
                ns_log Error "Error loading APM file form url $url: Bad package .info file. $errmsg\n$::errorInfo"
        return
    }
    file delete -force -- $tmpdir
    set package_key $package(package.key)
    set pretty_name $package(package-name)
    set version_name $package(name)
    ns_log Debug "APM: Preparing to load $pretty_name $version_name"
    # Determine if this package version is already installed.
    if {[apm_package_version_installed_p $package_key $version_name]} {
        apm_callback_and_log $callback  "<li>$pretty_name $version_name is already installed in your system."
        ns_log Error "Error loading APM file form url $url: Package $pretty_name $version_name is already installed"
    } else {

        set install_path [apm_workspace_install_dir]
        if { ![file isdirectory $install_path] } {
            file mkdir $install_path
        }

        apm_callback_and_log $callback  "<li>Extracting files into the filesystem."
        apm_callback_and_log $callback  "<li>$pretty_name $version_name ready for installation."

        #ns_log notice "exec sh -c 'cd $install_path ; [apm_gzip_cmd] -d -q -c $file_path | [apm_tar_cmd] xf -' 2>/dev/null"
        exec [apm_gzip_cmd] -d -q -c -S .apm $file_path | [apm_tar_cmd] -xf - -C $install_path 2> [apm_dev_null]

        return "${install_path}/${package_key}/${package_key}.info"
    }
}


#
### Deprecated procs
#

# apisano 2018-05-14: current code won't use this proc and is also not
# clear why we should get from the database something we have in a
# proc already. Commented code was the original one
ad_proc -deprecated -public apm_db_type_keys {} {

    Returns a list of valid database type keys.

} {
    return [lmap dbtype $::acs::known_database_types {lindex $dbtype 0}]
    # return [util_memoize [list db_list db_type_keys {select db_type_key from apm_package_db_types}]]
}


#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
