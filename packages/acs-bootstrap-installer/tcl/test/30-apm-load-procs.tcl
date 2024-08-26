ad_library {
    Tests for procs in tcl/30-apm-load-procs.tcl
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        apm_get_package_files
        acs_package_root_dir
        ad_find_all_files
    } \
    get_package_files {
        Test apm_get_package_files

        Note: this tests assumes that for a package such as acs-tcl,
        only "package-relevant" files are contained in the package
        folder. This is not a rule in general in OpenACS, e.g. the
        acs-automated-testing package may create many files during its
        operations that do not belong to the package source tree.
    } {
        set package_key acs-tcl

        set package_files [apm_get_package_files -all -package_key $package_key]

        set package_path [acs_package_root_dir $package_key]
        set package_length [string length $package_path]
        foreach f [ad_find_all_files $package_path] {
            set f [string range $f $package_length+1 end]
            aa_true "File '$f' belongs to '$package_key' and was found by the API" {
                $f in $package_files
            }
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_after_server_initialization
    } \
    ad_after_server_initialization {
        Test ad_after_server_initialization proc
    } {
        set name test-30-apm-load-procs
        set args "ns_log warning Test"

        ad_after_server_initialization $name $args

        set found_p false
        foreach result [nsv_get ad_after_server_initialization .] {
            if {[dict exists $result name] && [dict get $result name] eq $name} {
                set found_p true
                break
            }
        }
        aa_true "Found our settings among the values" $found_p
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_library
        ad_make_relative_path
    } \
    ad_library {
        Test ad_library proc
    } {
        set doc_string {
            Tests for procs in tcl/30-apm-load-procs.tcl
        }

        ad_parse_documentation_string $doc_string doc_elements

        set this_script [acs_root_dir]/packages/acs-bootstrap-installer/tcl/test/30-apm-load-procs.tcl
        set relative_path [ad_make_relative_path $this_script]

        aa_true "Info script belongs to the root folder" \
            [regexp "^[acs_root_dir]/(.*)$" $this_script _ rest]
        aa_equals "Info script's relative is the path after the root dir" \
            $relative_path $rest

        aa_equals "The library nsv was populated as expected" \
            [nsv_get api_library_doc $relative_path] [array get doc_elements]
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        apm_bootstrap_upgrade
        ad_opentmpfile
        ad_mktmpdir
    } \
    apm_bootstrap_upgrade {
        Test apm_bootstrap_upgrade proc
    } {
        set tmpdir [ad_mktmpdir]

        set root_dir_real [acs_root_dir]

        try {
            set ::acs::rootdir $tmpdir

            set content aaa

            set tmpfiles [list]

            #
            # Put some fake content as .adp and .tcl in the bootstrap
            # installer folders
            #
            file mkdir -- $tmpdir/packages/acs-bootstrap-installer/installer/tcl
            file mkdir -- $tmpdir/tcl
            set wfd [ad_opentmpfile filename .tcl]
            puts -nonewline $wfd $content
            close $wfd
            aa_log "copy $filename to $tmpdir/packages/acs-bootstrap-installer/installer/tcl"
            file copy $filename $tmpdir/packages/acs-bootstrap-installer/installer/tcl
            set tclfile $tmpdir/tcl/[file tail $filename]

            file mkdir -- $tmpdir/packages/acs-bootstrap-installer/installer/www
            file mkdir -- $tmpdir/www
            set wfd [ad_opentmpfile filename .adp]
            lappend tmpfiles $filename
            puts -nonewline $wfd $content
            close $wfd
            aa_log "copy $filename to $tmpdir/packages/acs-bootstrap-installer/installer/www"
            file copy $filename $tmpdir/packages/acs-bootstrap-installer/installer/www
            set adpfile $tmpdir/www/[file tail $filename]

            #
            # Call the API
            #
            apm_bootstrap_upgrade \
                -from_version_name from_version_name \
                -to_version_name to_version_name

            #
            # Check that files were copied
            #
            aa_true "File '$tclfile' exists" [file exists $tclfile]

            set rfd [open $tclfile r]; set c [read $rfd]; close $rfd
            aa_equals "Content for '$tclfile' is correct" $c $content

            aa_true "File '$adpfile' exists" [file exists $adpfile]

            set rfd [open $adpfile r]; set c [read $rfd]; close $rfd
            aa_equals "Content for '$adpfile' is correct" $c $content

        } finally {
            set ::acs::rootdir $root_dir_real
            file delete -force -- $tmpdir
        }
    }


aa_register_case \
    -cats {api smoke} \
    -procs {
        apm_first_time_loading_p
    } \
    apm_first_time_loading_p {
        Test apm_first_time_loading_p proc
    } {
        aa_false "This proc should always return false, unless we are installing an instance" \
            [apm_first_time_loading_p]

        aa_log "Set variable"
        set ::apm_first_time_loading_p 1
        aa_true "With the variable set, this should return true" \
            [apm_first_time_loading_p]
        aa_log "Unset variable"
        unset ::apm_first_time_loading_p
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        apm_guess_file_type
        apm_is_catalog_file
    } \
    apm_guess_file_type {
        Test apm_guess_file_type proc
    } {
        set testcases [list \
                           anyfile.sql anypackage data_model \
                           anypackage.sql anypackage data_model \
                           anypackage/upgrade/test-create.sql anypackage data_model \
                           anypackage/upgrade-1.0-3.0/test-create.sql anypackage data_model_upgrade \
                           anypackage-create.sql anypackage data_model_create \
                           anypackage-drop.sql anypackage data_model_drop \
                           anyfile.dat anypackage sql_data \
                           anypackage-test.dat anypackage sql_data \
                           anyfile.ctl anypackage ctl_file \
                           anypackage-test.ctl anypackage ctl_file \
                           anyfile.sqlj anypackage sqlj_code \
                           anypackage-test.sqlj anypackage sqlj_code \
                           anyfile.info anypackage package_spec \
                           anypackage-test.info anypackage package_spec \
                           anyfile.xql anypackage query_file \
                           anypackage-test.xql anypackage query_file \
                           anyfile.java anypackage java_code \
                           anypackage-test.java anypackage java_code \
                           anyfile.jar anypackage java_archive \
                           anypackage-test.jar anypackage java_archive \
                           /atest/doc/testfile anypackage documentation \
                           /anypackage/doc/testfile anypackage documentation \
                           anypackage-test.pl anypackage shell \
                           anyfile.pl anypackage shell \
                           anypackage-test.pl anypackage shell \
                           anyfile.pl anypackage shell \
                           anypackage-test.sh anypackage shell \
                           anyfile.sh anypackage shell \
                           anypackage/bin/test.onext anypackage shell \
                           /bin/anyfile.anotherext anypackage shell \
                           /bin/templates/anyfile.anotherext anypackage shell \
                           /templates/anyfile.anotherext anypackage template \
                           /templates/www/anyfile.anotherext anypackage template \
                           anyfile/templates/test.anotherext anypackage template \
                           test.adp anypackage documentation \
                           test.html anypackage documentation \
                           /www/apath.html anypackage "" \
                           /admin-www/apath.html anypackage "" \
                           /lib/apath.html anypackage "" \
                           $::acs::pageroot/test/www/apath anypackage content_page \
                           $::acs::pageroot/test/admin-www/apath anypackage content_page \
                           $::acs::pageroot/test/lib/apath anypackage include_page \
                           $::acs::pageroot/test/tcl/test2/apath.tcl anypackage "" \
                           $::acs::pageroot/test/tcl/test2/apath-init.tcl anypackage "" \
                           $::acs::pageroot/test/tcl/test2/apath-procs.tcl anypackage "" \
                           $::acs::pageroot/tcl/test2/apath.tcl anypackage tcl_util \
                           $::acs::pageroot/tcl/test2/apath-init.tcl anypackage tcl_init \
                           $::acs::pageroot/tcl/test2/apath-procs.tcl anypackage tcl_procs \
                           catalog/acs-kernel.en_US.ISO-8859-1.xml acs-kernel message_catalog
                      ]

        foreach {path package_key expected} $testcases {
            aa_equals "Path '$path' for package_key '$package_key' returns expected value" \
                [apm_guess_file_type $package_key $path] $expected
        }
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        apm_package_supports_rdbms_p
    } \
    apm_package_supports_rdbms_p {
        Test apm_package_supports_rdbms_p proc
    } {
        set system_db_type [db_type]

        aa_true "tsearch-driver is a Postgres-only package" {
            $system_db_type ne "postgresql" || [apm_package_supports_rdbms_p \
                                                    -package_key tsearch-driver]
        }

        aa_true "intermedia-driver is an Oracle-only package" {
            $system_db_type ne "oracle" || [apm_package_supports_rdbms_p \
                                                -package_key intermedia-driver]
        }

        aa_true "acs-kernel should always be supported" \
            [apm_package_supports_rdbms_p -package_key acs-kernel]
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        apm_parse_catalog_path
    } \
    apm_parse_catalog_path {
        Test apm_parse_catalog_path proc
    } {
        set path acs-kernel/catalog/acs-kernel.en_US.ISO-8859-1.xml
        set file_info [apm_parse_catalog_path $path]
        set expected {locale en_US package_key acs-kernel charset ISO-8859-1 prefix {}}

        foreach key {package_key prefix locale charset} {
            aa_equals "'$key' from path '$path' extracted" \
                [dict get $file_info $key] [dict get $expected $key]
        }

        set path my-package/no-catalog/acs-kernel.en_US.ISO-8859-1.xml
        set file_info [apm_parse_catalog_path $path]
        aa_equals "Result from path '$path' is empty" \
            $file_info ""

        set path acs-kernel/catalog/prefix-acs-kernel.en_US.UTF-8.xml
        set file_info [apm_parse_catalog_path $path]
        set expected {locale en_US package_key acs-kernel charset UTF-8 prefix {prefix-}}

        foreach key {package_key prefix locale charset} {
            aa_equals "'$key' from path '$path' extracted" \
                [dict get $file_info $key] [dict get $expected $key]
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        apm_source
        ad_make_relative_path
    } \
    apm_source {
        Test apm_source proc
    } {
        aa_section "Source nonexistent"
        aa_silence_log_entries -severities error {
            aa_equals "Proc returns 0 on nonexistent files" \
                [apm_source noexist] 0
        }

        aa_section "Source file outside the root_dir"
        close [ad_opentmpfile tmpfile]
        aa_true \
            "Proc throws an error on an existing file '$tmpfile' not belonging to '[acs_root_dir]'" \
            [catch {
                apm_source $tmpfile
            }]

        set wfd [ad_opentmpfile tmpfile]
        puts $wfd {if \{ }
        close $wfd

        aa_section "Source broken script"
        set testscript [acs_root_dir]/packages/acs-bootstrap-installer/[file tail $tmpfile]

        file copy -- $tmpfile [file dirname $testscript]
        aa_silence_log_entries -severities error {
            apm_source $testscript errors
        }
        file delete -- $testscript

        aa_true "Loading a broken script returned errors in the errors var" \
            [llength [array get errors]]
        aa_silence_log_entries -severities error {
            aa_equals "Proc returns 0 on broken scripts" \
                [apm_source $testscript] 0
        }
        unset errors

        aa_section "Source a good script"
        set testscript [acs_root_dir]/packages/acs-bootstrap-installer/tcl/test/30-apm-load-procs.tcl
        set mtime [file mtime $testscript]
        set r_file [ad_make_relative_path $testscript]
        apm_source $testscript errors

        aa_false "Loading a good script returned no errors" \
            [llength [array get errors]]
        aa_equals "Proc returns 1 on good scripts" \
            [apm_source $testscript] 1
        aa_equals "mtime was stored in the nsv" \
            $mtime [nsv_get apm_library_mtime $r_file]

    }

namespace eval test {}
namespace eval test::acs_bootstrap_installer {}

ad_proc -private test::acs_bootstrap_installer::db_map {
    qn
} {
    set dollar_value test
    set bind_value anything
    return [::db_map $qn]
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        db_map
        db_qd_load_query_file
    } \
    db_map {
        Test db_map proc.
    } {
        aa_log "Flush the pre-loaded query"
        set qn dbqd.acs-bootstrap-installer.tcl.test.30-apm-load-procs.test::acs_bootstrap_installer::db_map.full_query_2
        nsv_unset OACS_FULLQUERIES $qn

        set xql_file [acs_root_dir]/packages/acs-bootstrap-installer/tcl/test/30-apm-load-procs.xql
        db_qd_load_query_file \
            $xql_file \
            errors

        aa_false "No errors loading '$xql_file'" [info exists errors]

        set qn dbqd.acs-bootstrap-installer.tcl.test.30-apm-load-procs.test::acs_bootstrap_installer::db_map.full_query_2
        aa_true "Nsv was loaded with query from '$xql_file'" \
            [nsv_get OACS_FULLQUERIES $qn value]

        set db_type [db_type]

        if {$db_type eq "postgresql"} {
            set expected [join {
                select 'test' as d,
                :bind_value as b
                1 as c
            }]
        } elseif {$db_type eq "oracle"} {
            set expected [join {
                select 'test' as d,
                :bind_value as b
                1 as c
                from dual
            }]
        } else {
            set expected ""
        }

        set result [join [::test::acs_bootstrap_installer::db_map full_query_1]]
        aa_equals "'$db_type' fetches full_query_1" \
            $result $expected

        if {$db_type eq "postgresql"} {
            set expected {limit 1}
        } elseif {$db_type eq "oracle"} {
            set expected {WHERE ROWNUM <= 1}
        } else {
            set expected ""
        }

        set result [join [::test::acs_bootstrap_installer::db_map partial_query_1]]
        aa_equals "'$db_type' fetches partial_query_1" \
            $result $expected

        set expected [join {
            select 'test' as d,
            :bind_value as b
            1 as c
            from dual as generic
        }]

        set result [join [::test::acs_bootstrap_installer::db_map full_query_2]]
        aa_equals "'$db_type' fetches full_query_2" \
            $result $expected

        set expected {fetch first 1 rows only}

        set result [join [::test::acs_bootstrap_installer::db_map partial_query_2]]
        aa_equals "'$db_type' fetches partial_query_2" \
            $result $expected
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        ad_arg_parser
    } \
    ad_arg_parser {
        Test ad_arg_parser proc.
    } {
        aa_true "Error when allowed argument is not a flag" [catch {
            ad_arg_parser {
                one two three
            } {
                three
            }
        }]
        aa_true "Error when allowed argument has no value" [catch {
            ad_arg_parser {
                one two three
            } {
                -three
            }
        }]
        aa_true "Not allowed flag with value throws error" [catch {
            ad_arg_parser {
                one two three
            } {
                -four value
            }
        }]
        aa_true "Not allowed flag with value is NOT OK when 'args' is there" [catch {
            ad_arg_parser {
                one two three args
            } {
                -four value
            }
        }]
        aa_false "Extra args when 'args' is there is OK" [catch {
            ad_arg_parser {
                one two three args
            } {
                arg1 arg2 arg3
            }
        }]
        aa_false "Allowed flag with value is OK" [catch {
            ad_arg_parser {
                one two three
            } {
                -three value
            }
        }]
    }
