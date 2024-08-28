ad_library {

    Tests for api in /tcl/apm-file-procs.tcl

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        apm_workspace_dir
        apm_workspace_install_dir
    } \
    apm_workspace_directories {
        Test requiring the workspace directories via the API.
    } {
        aa_section "Create the directories"

        set workspace_dir [apm_workspace_dir]
        set workspace_install_dir [apm_workspace_install_dir]
        aa_true "'$workspace_dir' was created" [file isdirectory $workspace_dir]
        aa_true "'$workspace_install_dir' was created" [file isdirectory $workspace_install_dir]


        aa_section "Create the directories (they already exist and contain something)"

        aa_log "Create a file in '$workspace_install_dir/test.txt'"
        set wfd [open $workspace_install_dir/test.txt w]
        puts $wfd ABCD
        close $wfd
        apm_workspace_dir
        aa_true "'$workspace_dir' was created" [file isdirectory $workspace_dir]
        aa_true "'$workspace_install_dir' was created" [file isdirectory $workspace_install_dir]
        aa_true "'$workspace_install_dir/test.txt' still exists" \
            [file exists $workspace_install_dir/test.txt]


        aa_section "Create the directories (a file is in the way)"

        aa_log "A file instead of '$workspace_dir'"
        file delete -force -- $workspace_dir $workspace_install_dir
        set wfd [open $workspace_dir w]
        puts $wfd ABCD
        close $wfd
        apm_workspace_dir
        apm_workspace_install_dir
        aa_true "'$workspace_dir' was created" [file isdirectory $workspace_dir]
        aa_true "'$workspace_install_dir' was created" [file isdirectory $workspace_install_dir]

        aa_log "A file instead of '$workspace_install_dir'"
        file delete -force -- $workspace_dir $workspace_install_dir
        file mkdir $workspace_dir
        set wfd [open $workspace_install_dir w]
        puts $wfd ABCD
        close $wfd
        apm_workspace_dir
        apm_workspace_install_dir
        aa_true "'$workspace_dir' was created" [file isdirectory $workspace_dir]
        aa_true "'$workspace_install_dir' was created" [file isdirectory $workspace_install_dir]
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        apm_extract_tarball
        apm_generate_tarball
        apm_get_package_files
        content::revision::get_cr_file_path
        util::file_content_check

        db_blob_get_file
    } \
    apm_tarballs {
        Test creating and extracting a tarball from an APM Package
        version.
    } {
        aa_run_with_teardown -rollback -test_code {
            set package_key acs-tcl
            set version_id [db_string get_latest_version {
                select max(version_id) from apm_package_versions
                where package_key = :package_key
                and enabled_p = 't'
            }]
            aa_log "Latest enabled version for '$package_key' is '$version_id'"


            aa_section "Creating the tarball"

            apm_generate_tarball $version_id

            aa_true "Tarball was found" [db_0or1row get_tarball {
                select max(live_revision) as revision_id from cr_items
                where name = 'tarball-for-package-version-' || :version_id
            }]

            set tarball_path [content::revision::get_cr_file_path -revision_id $revision_id]

            aa_true "File is a gzipped archive" \
                [util::file_content_check -type gzip -filename $tarball_path]


            aa_section "Extracting the tarball"

            set tmpdir [ad_mktmpdir]
            aa_log "Extracting tarball in '$tmpdir'"
            apm_extract_tarball $version_id $tmpdir

            aa_log "Walking through the extracted tarball..."
            set tmp_length [string length $tmpdir/$package_key/]
            set files [list $tmpdir]
            while {[llength $files] > 0} {
                set f [lindex $files 0]
                set files [lrange $files 1 end]
                if {[file isdirectory $f]} {
                    lappend files {*}[glob -directory $f *]
                } else {
                    set f [string range $f $tmp_length end]
                    set tar_visited($f) 1
                }
            }

            aa_log "Check it against the actual files in the package"
            foreach f [apm_get_package_files -all -package_key acs-tcl] {
                aa_true "File '$f' was found in the tarfile" [info exists tar_visited($f)]
            }
            
            file delete -force $tmpdir
        }
    }
