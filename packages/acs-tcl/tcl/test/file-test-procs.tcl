ad_library {
    Sweep the all the files in the system looking for systematic errors.

    @author Jeff Davis
    @creation-date 2005-02-28
    @cvs-id $Id$
}

aa_register_case -cats {smoke} acs_tcl__tcl_file_syntax_errors {
    Test all known tcl files for successful parsing "(in the [info complete] sense at least)" and other common errors.

    @author Jeff Davis davis@xarg.net
} {
    set good 0
    set nfiles 0
    # couple of local helper procs 
    proc ::tcl_p {file} { 
        return [expr [string match {*.tcl} $file] || [file isdirectory $file]]
    }

    # if startdir is not [acs_root_dir]/packages, then somebody checked in the wrong thing by accident
    set startdir [acs_root_dir]/packages

    aa_log "Checks starting from $startdir"

    #inspect every tcl file in the directory tree starting with $startdir
    foreach file [ad_find_all_files -check_file_func ::tcl_p $startdir] { 
        incr nfiles

        set fp [open $file "r"]
        set data [read $fp]
        close $fp

        # Check that the file parses        
        if {! [info complete $data] } { 
            aa_log_result fail "$file parses successfully"
        } else {
            incr good
        }
    }
    aa_log "$good good of $nfiles checked"
}

aa_register_case -cats {} -error_level notice acs_tcl__tcl_file_common_errors {
    Check for some common error patterns 

    @author Jeff Davis davis@xarg.net
} {
    # couple of local helper procs 
    proc ::tcl_p {file} { 
        return [expr [string match {*.tcl} $file] || [file isdirectory $file]]
    }
    
    # if startdir is not [acs_root_dir]/packages, then somebody checked in the wrong thing by accident
    set startdir [acs_root_dir]/packages
    
    aa_log "Checks starting from $startdir"

    #inspect every tcl file in the directory tree starting with $startdir
    foreach file [ad_find_all_files -check_file_func ::tcl_p $startdir] { 

        set fp [open $file "r"]
        set data [read $fp]
        close $fp

	if {![regexp {/packages/acs-tcl/tcl/test/acs-tcl-test-procs\.tcl$} $file match]} {
	    aa_true "$file should not contain '@returns'.  @returns is probably a typo of @return" [expr [string first @returns $data] == -1]
	}
    }
}

aa_register_case -cats {db smoke production_safe} acs-tcl__named_constraints {
    Check that there are no tables with unnamed constraints

    @author Jeff Davis davis@xarg.net
} {
    switch -exact -- [db_name] {
        PostgreSQL {
            db_foreach check_constraints {
                select relname as table from pg_constraint r join (select relname,oid from pg_class) c on (c.oid = r.conrelid) where conname like '$%'
            } {
                aa_true "Table $table constraints named" [string is space $table]
            }
        }
        default {
            aa_log "Not run for [db_name]"
        }
    }
}

aa_register_case -cats {smoke production_safe} acs-tcl__check_info_files {
    Check that all the info files parse correctly

    @author Jeff Davis davis@xarg.net
} {
    foreach spec_file [glob -nocomplain "[acs_root_dir]/packages/*/*.info"] {
        set errp 0
        if {  [catch {array set version [apm_read_package_info_file $spec_file]} errMsg] } {
            aa_log_result fail "$spec_file returned $errMsg"
            set errp 1
        } else {
            regexp {packages/([^/]*)/} $spec_file match key
            if {![string equal $version(package.key) $key]} {
                aa_log_result fail "MISMATCH DIRECTORY/PACKAGE KEY: $spec_file $version(package.key) != $key"
                set errp 1
            }
            # check on the requires, provides, etc stuff.
            if {[empty_string_p $version(provides)]
                && [string equal $version(package.type) apm_service] } {
                aa_log_result fail "$spec_file SERVICE MISSING PROVIDES: $key"
                set errp 1
            } elseif { ![empty_string_p $version(provides)]} {
                if { ![string equal $version(name) [lindex [lindex $version(provides) 0] 1]]} {
                    aa_log_result fail "$spec_file: MISMATCH PROVIDES VERSION: $version(provides) $version(name)"
                    set errp 1
                }
                if { ![string equal $key [lindex [lindex $version(provides) 0] 0]]} {
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

aa_register_case -cats {smoke production_safe} acs-tcl__check_upgrade_ordering { 
    Check that all the upgrade files are well ordered (non-overlapping and v1 > v2)

    @author Jeff Davis davis@xarg.net
} {
    foreach dir [lsort [glob -nocomplain -types f "[acs_root_dir]/packages/*/*.info"]] {

        set error_p 0

        regexp {/([^/]*).info} $dir match package
        set files [apm_get_package_files -package_key $package -file_types data_model_upgrade]

        # build list of files for each db type, sort, check strict ordering.
        foreach db_type {postgresql oracle} {
            set upgrades [list]
            foreach file $files {
                set db [apm_guess_db_type $package $file]
                if {[string is space $db] 
                    || [string equal $db $db_type]} {
                    set tail [file tail $file]
                    if {[regexp {\-(.*)-(.*).sql} $tail match v1 v2]} {
                        set v1s [apm_version_sortable $v1]
                        set v2s [apm_version_sortable $v2]
                        if {[string compare $v1s $v2s] > -1} {
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

            # if we have more than 1 upgrade check they are well ordered.
            if {[llength $upgrades] > 1} {
                set u1 [lsort -dictionary -index 0 $upgrades]
                set u2 [lsort -dictionary -index 1 $upgrades]

                foreach f1 $u1 f2 $u2 {
                    if {![string equal $f1 $f2]} {
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




aa_register_case -cats {smoke} acs_tcl__check_xql_files {
    Check for some common errors in the xql files.

    @author Jeff Davis davis@xarg.net
} {
    # couple of local helper procs 
    proc ::xql_p {file} { 
        return [expr [string match {*.xql} $file] || [file isdirectory $file]]
    }
    
    # if startdir is not [acs_root_dir]/packages, then somebody checked in the wrong thing by accident
    set startdir [acs_root_dir]/packages
    
    aa_log "Checks starting from $startdir"

    #inspect every tcl file in the directory tree starting with $startdir
    foreach file [ad_find_all_files -check_file_func ::xql_p $startdir] { 

        set fp [open $file "r"]
        set data [read $fp]
        close $fp
        ns_log debug "acs_tcl__check_xql_files: read $file"
        set data [db_qd_internal_prepare_queryfile_content $data]

        if { [catch {set parse [xml_parse $data]} errMsg] } {
            ns_log warning "acs_tcl__check_xql_files: failed parse $file $errMsg"
            aa_log_result fail "XML Parse Error: $file [ad_quotehtml $errMsg]"
        } else {
            # lets walk the nodes and check they are what we want to see.

            # We are done so just let it go man.

        }

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
            ns_log debug "JCD: acs_tcl__check_xql_files: $db $base from $file"
            if { ![empty_string_p $db]
                 && ![string match $db oracle]
                 && ![string match $db postgresql] } {
                aa_log_result fail "bad db name $db file $file (or maybe .tcl or .vuh missing)"
            } elseif { ![empty_string_p $db]
                       && ![regexp $db $data] } {
                aa_log_result fail "rdbms $db missing $file"

            } elseif {[empty_string_p $db]
                      && [regexp {<rdbms>} $data] } {
                aa_log_result fail "rdbms found in generic $file"
            } else {
                set allxql($base) 1
            }

            if {[string equal $db postgresql] || [empty_string_p $db]} {
                if {[regexp {(nvl[ ]*\(|decode[ ]*\()} $data]} {
                    aa_log_result fail "postgres or generic with oracle code $file" 
                }
            } else {
                if {[regexp {(now[ ]*\()} $data] || [empty_string_p $db]} {
                    aa_log_result fail "oracle or generic with oracle code $file" 
                }
            }

        }
    }

    foreach xql [array names allxql] {
        # check there is a corresponding .tcl file
        if {![file exists ${xql}.tcl]
            && ![file exists ${xql}.vuh]} {
            aa_log_result fail "missing .tcl or .vuh file for $xql" 
        }
        if { 0 } { 
            # check that if there is a db specific version that the corresponding
            # generic or other db file exists...
            if {[info exists onexql(${xql}-oracle)]
                && !([info exists onexql(${xql}-postgresql)]
                     || [info exists onexql(${xql})]) } {
                aa_log_result fail "No postgresql or generic $xql" 
            }
            if {[info exists onexql(${xql}-postgresql)]
                && !([info exists onexql(${xql}-oracle)]
                     || [info exists onexql(${xql})]) } {
                aa_log_result fail "No oracle or generic $xql" 
            }

        }
    }
}

