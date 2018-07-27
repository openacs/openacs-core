ad_library {
    Sweep all the files in the system looking for systematic errors.

    @author Jeff Davis
    @creation-date 2005-02-28
    @cvs-id $Id$
}

aa_register_case \
    -cats {smoke production_safe} \
    -procs {apm_get_installed_versions apm_get_package_files} \
    files__tcl_file_syntax_errors {

        Test all known Tcl files for successful parsing "(in the [info complete] sense at least)" and other common errors.

        @author Jeff Davis davis@xarg.net
} {
    # if startdir is not $::acs::rootdir/packages, then somebody checked in the wrong thing by accident
    set startdir $::acs::rootdir/packages

    aa_log "Checks starting from $startdir"

    # get tcl files from installed packages
    set files [list]
    apm_get_installed_versions -array installed_versions
    foreach {package_key version} [array get installed_versions] {
        lappend files {*}[lmap f [apm_get_package_files \
                                      -package_key $package_key] {
            if {[file extension $f] ne ".tcl"} continue
            set f $startdir/$package_key/$f
        }]
    }

    #inspect every Tcl file in the directory tree starting with $startdir
    foreach file $files {
        set fp [open $file "r"]
        set data [read $fp]
        close $fp

        # Check that the file parses
        aa_true "$file parses successfully" [info complete $data]
    }
}

aa_register_case \
    -cats {smoke production_safe} \
    -error_level error \
    -procs {} \
    files__tcl_file_common_errors {
    Check for some common error patterns.

    @author Jeff Davis davis@xarg.net
} {
    # couple of local helper procs
    proc ::tcl_p {file} {
        return [expr {[string match {*.tcl} $file] || [file isdirectory $file]}]
    }

    # if startdir is not $::acs::rootdir/packages, then somebody checked in the wrong thing by accident
    set startdir $::acs::rootdir/packages

    aa_log "Checks starting from $startdir"
    set count 0
    #inspect every Tcl file in the directory tree starting with $startdir
    foreach file [ad_find_all_files -check_file_func ::tcl_p $startdir] {

        if {[string match "*/acs-tcl/tcl/test/file-test-procs.tcl" $file]} {
            continue
        }
        set fp [open $file "r"]
        set data [read $fp]
        close $fp

        if {[string first @returns $data] > -1} {
            aa_log_result fail "$file should not contain '@returns'.  @returns is probably a typo of @return"
        }
    }
    aa_log "Checked $count Tcl files"
}

aa_register_case \
    -cats {smoke production_safe} \
    -procs {apm_read_package_info_file} \
    files__check_info_files {

        Check that all the info files parse correctly and are
        internally consistent.

        @author Jeff Davis davis@xarg.net
} {
    foreach spec_file [glob -nocomplain "$::acs::rootdir/packages/*/*.info"] {
        set errp 0
        if {  [catch {array set version [apm_read_package_info_file $spec_file]} errMsg] } {
            aa_log_result fail "$spec_file returned $errMsg"
            set errp 1
        } else {
            regexp {packages/([^/]*)/} $spec_file match key
            if {$version(package.key) ne $key } {
                aa_log_result fail "MISMATCH DIRECTORY/PACKAGE KEY: $spec_file $version(package.key) != $key"
                set errp 1
            }
            # check on the requires, provides, etc stuff.
            if {$version(provides) eq ""
                && [string equal $version(package.type) apm_service] } {
                aa_log_result fail "$spec_file SERVICE MISSING PROVIDES: $key"
                set errp 1
            } elseif { $version(provides) ne ""} {
                if { $version(name) ne [lindex $version(provides) 0 1] } {
                    aa_log_result fail "$spec_file: MISMATCH PROVIDES VERSION: $version(provides) $version(name)"
                    set errp 1
                }
                if { $key ne [lindex $version(provides) 0 0] } {
                    aa_log_result fail "$spec_file MISMATCH PROVIDES KEY: $key $version(provides)"
                    set errp 1
                }
            }

            # check for duplicate parameters
            array unset params
            foreach param $version(parameters) {
                set name [lindex $param 0]
                if {[info exists params($name)]} {
                    aa_log_result fail "$spec_file: DUPLICATE PARAMETER: $name"
                    set errp 1
                }
                set params($name) $name
            }
        }
        if {!$errp} {
            aa_log_result pass "$spec_file no errors"
        }
    }
}

aa_register_case \
    -cats {smoke production_safe} \
    -procs {
        apm_get_package_files
        apm_guess_db_type
        apm_version_sortable
    } \
    files__check_upgrade_ordering {

        Check that all the upgrade files are well ordered
        (non-overlapping and v1 > v2).

        @author Jeff Davis davis@xarg.net
} {
    foreach dir [lsort [glob -nocomplain -types f "$::acs::rootdir/packages/*/*.info"]] {

        set error_p 0

        regexp {/([^/]*).info} $dir match package
        set files [apm_get_package_files -package_key $package -file_types data_model_upgrade]

        # build list of files for each db type, sort, check strict ordering.
        foreach db_type {postgresql oracle} {
            set upgrades [list]
            foreach file $files {
                # DRB: Ignore old upgrade scripts that aren't in the proper place.  We
                # still have old ACS 3 -> ACS 4 upgrade scripts lying around, and
                # I don't want to report them as failures nor delete them ...
                if { [string first sql $file] == -1 &&
                     [string first upgrade $file] == -1 } {
                    set db [apm_guess_db_type $package $file]
                    if {[string is space $db]
                        || $db eq $db_type} {
                        set tail [file tail $file]
                        if {[regexp {\-(.*)-(.*).sql} $tail match v1 v2]} {
                            set v1s [apm_version_sortable $v1]
                            set v2s [apm_version_sortable $v2]
                            if {$v1s ne $v2s  > -1} {
                                set error_p 1
                                aa_log_result fail "$file: from after to version"
                            } else {
                                lappend upgrades [list $v1s $v2s $v1 $v2 $file]
                            }
                        } else {
                            set error_p 1
                            aa_log_result fail "$file: could not find version numbers"
                        }
                    }
                }
            }

            # if we have more than 1 upgrade check they are well ordered.
            if {[llength $upgrades] > 1} {
                set u1 [lsort -dictionary -index 0 $upgrades]
                set u2 [lsort -dictionary -index 1 $upgrades]

                foreach f1 $u1 f2 $u2 {
                    if {$f1 ne $f2 } {
                        set error_p 1
                        aa_log_result fail "$package upgrade not well ordered [lindex $f1 end] [lindex $f2 end]\n"
                    }
                }
            }
        }
        if {!$error_p} {
            aa_log_result pass "$package upgrades well ordered"
        }
    }
}

aa_register_case \
    -cats {smoke} \
    -procs {
        apm_get_installed_versions
        apm_get_package_files
        db_qd_internal_prepare_queryfile_content
        xml_parse
    } \
    files__check_xql_files {

        Check for some common errors in the xql files like
        missing rdbms, missing corresponding Tcl files, etc.

        Not production safe since malformed xql can crash AOLserver in the parse.

        @author Jeff Davis davis@xarg.net
} {
    # if startdir is not $::acs::rootdir/packages, then somebody checked in the wrong thing by accident
    set startdir $::acs::rootdir/packages

    aa_log "Checks starting from $startdir"

    # get xql files from installed packages
    set files [list]
    apm_get_installed_versions -array installed_versions
    foreach {package_key version} [array get installed_versions] {
        lappend files {*}[lmap f [apm_get_package_files \
                                      -package_key $package_key \
                                      -file_types {query_file}] {
            set f $startdir/$package_key/$f
        }]
    }

    foreach file $files {

        set fp [open $file "r"]
        set data [read $fp]
        close $fp
        ns_log debug "acs_tcl__check_xql_files: read $file"
        set data [db_qd_internal_prepare_queryfile_content $data]

        set parse_failed_p [catch {set parse [xml_parse $data]} errMsg]
        aa_false "xql $file correctly parsed" $parse_failed_p

        # Errors:
        #   .xql files without .tcl
        #   dbname not blank or postgresql or oracle
        #   -oracle w/o generic or -postgresql
        #   -postgresql w/o generic or -oracle
        #

        regexp {(.*)[.]xql$} $file match base

        if {![file exists ${base}.tcl] && ![file exists ${base}.vuh]} {
            # the file did not exist so we must have a -db extension...
            regexp {(.*?)(-)?([A-Za-z_]*)[.]xql$} $file match base dummy db

            if { $db ne ""
                 && $dummy ne ""
                 && ![string match $db oracle]
                 && ![string match $db postgresql] } {
                aa_log_result fail "bad db name \"$db\" file $file (or maybe .tcl or .vuh missing)"
            } elseif { $db ne ""
                       && $dummy ne ""
                       && ![regexp $db $data] } {
                aa_log_result fail "rdbms \"$db\" missing $file"
            } elseif {$dummy eq ""
                      && [regexp {<rdbms>} $data] } {
                aa_log_result fail "rdbms found in generic $file"
            }

            if {$db eq "postgresql" || $dummy eq ""} {
                if {[regexp -nocase {(nvl[ ]*\(|decode[ ]*\(| connect by )} $data match]} {
                    aa_log_result fail "postgres or generic with oracle code $file: $match"
                }
                if {[regexp -nocase {((limit|offset)[ ]*:)} $data match]} {
                    aa_log_result fail "postgres <7.4 does not support limit :var binding with our driver"
                }
                set allxql($base) $file
            } else {
                if {[regexp -nocase {(now[ ]*\(| limit | offset | outer join )} $data match ] || $dummy eq ""} {
                    aa_log_result fail "oracle or generic with postgres code $file: $match"
                }
                set allxql($base) $file
            }
        } else {
            set allxql($base) $file
        }
    }

    foreach xql [array names allxql] {
        # check there is a corresponding .tcl file
        if {![file exists ${xql}.tcl]
            && ![file exists ${xql}.vuh]} {
            # JCD: Hack to exclude calendar/www/views which is the only current file which has
            # no associated Tcl file.
            if {[string first calendar/www/views $allxql($xql)] <  0} {
                aa_log_result fail "missing .tcl or .vuh file for $allxql($xql)"
            }
        }
        if { 0 } {
            # JCD: disabled for now...

            # check that if there is a db specific version that the corresponding
            # generic or other db file exists...
            if {[info exists onexql(${xql}-oracle)]
                && !([info exists onexql(${xql}-postgresql)]
                     || [info exists onexql(${xql})]) } {
                aa_log_result fail "No postgresql or generic $allxql($xql)"
            }
            if {[info exists onexql(${xql}-postgresql)]
                && !([info exists onexql(${xql}-oracle)]
                     || [info exists onexql(${xql})]) } {
                aa_log_result fail "No oracle or generic $allxql($xql)"
            }
        }
    }
}

aa_register_case \
    -cats {production_safe} \
    -error_level notice \
    -procs {} \
    files__trailing_whitespace {

        Looks for trailing whitespace: spaces or tabs at the end of lines.
        Currently, only checks on .tcl files.

        @author Héctor Romojaro <hector.romojaro@gmail.com>

        @creation-date 2018-07-24

} {
    # if startdir is not $::acs::rootdir/packages, then somebody checked in the wrong thing by accident
    set startdir $::acs::rootdir/packages

    aa_log "Checks starting from $startdir"

    # get tcl files from installed packages
    set files [list]
    apm_get_installed_versions -array installed_versions
    foreach {package_key version} [array get installed_versions] {
        lappend files {*}[lmap f [apm_get_package_files \
                                      -package_key $package_key] {
            if {[file extension $f] ne ".tcl"} continue
            set f $startdir/$package_key/$f
        }]
    }

    #inspect every Tcl file in the directory tree starting with $startdir
    set count 0
    set good 0
    foreach file $files {
        set f [open $file "r"]
        set line_numbers ""
        incr count
        set whitespace_count 0
        set line_number 0

        # Check for trailing whitespace in every line
        while {[gets $f line] >= 0} {
            incr line_number
            set last_line $line
            if {[regexp {[ \t]+$} $line]} {
                # Found trailing whitespace!
                incr whitespace_count
                lappend line_numbers $line_number
            }
        }
        close $f

        # Check for empty lines at the end of the file
        if {[regexp {^\s*$} $last_line]} {
            incr whitespace_count
            lappend line_numbers "end of file"
        }

        # Check results on $file
        if { $whitespace_count == 0 } {
            incr good
        } else {
            aa_log_result fail "$file: trailing whitespace in lines: $line_numbers"
        }
    }
    aa_log "$good of $count tcl files checked have no trailing whitespace"
}

aa_register_case \
    -cats {smoke production_safe} \
    -error_level warning \
    -procs {} \
    files__page_contracts {

    Checks for files without 'ad_page_contract' or 'ad_include_contract' in
    both 'www' and 'lib' package directories.

    There are cases, where includelets are not stored in 'lib' but 'www', or
    have 'ad_page_contract' instead of 'ad_include_contract'.

    Checking if the location of includelets is correct is not so clear, so we
    avoid doing this in this particular test.

    @author Héctor Romojaro <hector.romojaro@gmail.com>

    @creation-date 2018-07-24

} {
    # if startdir is not $::acs::rootdir/packages, then somebody checked in the wrong thing by accident
    set startdir $::acs::rootdir/packages

    aa_log "Checks starting from $startdir"

    # get tcl files from installed packages
    set files [list]
    apm_get_installed_versions -array installed_versions
    foreach {package_key version} [array get installed_versions] {
        lappend files {*}[lmap f [apm_get_package_files \
                                      -package_key $package_key \
                                      -file_types {content_page include_page}] {
            # Ignore non .tcl files
            if {[file extension $f] ne ".tcl"} continue
            # Ignore docs
            if { "$package_key" eq "acs-core-docs" } continue
            set f $startdir/$package_key/$f
        }]
    }

    set ignorechars {
        , " "
        ( " " ) " " < " " > " "
        \[ " " \] " "
        \{ " " \} " "
        < " " > " "
        . " " : " "   ; " " ? " " ! " "
        = " "
        \r " "
        \" " "
        „ " " “ " " ” " "
        ﻿ " "
        ­ ""
    }

    #inspect every Tcl file in the directory tree starting with $startdir
    set count 0
    set good 0
    foreach file $files {
        set f [open $file "r"]
        incr count
        set contract_found_p false
        ns_log Notice "Looking for contracts in file $file"
        while {[gets $f line] >= 0 && !$contract_found_p} {
            set line_clean [string map $ignorechars $line]
            if { "ad_page_contract" in "$line_clean" || "ad_include_contract" in "$line_clean" } {
                # Found contract!
                incr good
                set contract_found_p true
            }
        }
        close $f

        # Check results on $file
        if { !$contract_found_p } {
            aa_log_result fail "$file: no 'ad_page_contract' or 'ad_include_contract' found"
        }
    }
    aa_log "$good of $count tcl files checked have 'ad_page_contract' or 'ad_include_contract'"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
