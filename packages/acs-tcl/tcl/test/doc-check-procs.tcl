ad_library {
    Check all the proc documentation

    @author Jeff Davis
    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2005-02-28
    @cvs-id $Id$
}

aa_register_case -cats {smoke production_safe} documentation__check_proc_doc {
    checks if documentation exists for public procs.

    @author Jeff Davis davis@xarg.net
} {
    set count 0
    set good 0
    foreach p [lsort -dictionary [nsv_array names api_proc_doc]] {
        array set pa [nsv_get api_proc_doc $p]
        if { [info exists pa(protection)]
             && "public" in $pa(protection)
             && !($pa(deprecated_p) || $pa(warn_p))
         } {
            incr count
            if { [string is space $pa(main)] } {
                aa_log_result fail "No documentation for public proc $p"
            } else {
                incr good
            }
        }
        array unset pa
    }
    aa_log "Found $good good of $count checked"
}



aa_register_case -cats {smoke production_safe} -error_level warning documentation__check_deprecated_see {
    checks if deprecated procs have an @see clause

    @author Jeff Davis davis@xarg.net
} {
    set count 0
    set good 0
    foreach p [lsort -dictionary [nsv_array names api_proc_doc]] {
        array set pa [nsv_get api_proc_doc $p]
        if { ([info exists pa(deprecated_p)] && $pa(deprecated_p))
             || ([info exists pa(warn_p)] && $pa(warn_p))
         } {
            incr count
            if { ![info exists pa(see)] || [string is space $pa(see)] } {
                aa_log_result fail "No @see for deprecated proc $p"
            } else {
                incr good
            }
        }
        array unset pa
    }
    aa_log "Found $good of $count procs checked"
}

aa_register_case -cats {smoke production_safe} -error_level warning documentation__check_typos {

    Search for spelling errors in the proc documentation, using a list of common
    typos based on the one included in the lintian Debian package:

    https://github.com/Debian/lintian/tree/master/data/spelling

    Limitations:

    1- Only single words are tested.
    2- Words are converted to lowercase before testing, so tests are case
       insensitive.
    3- Every word is compared against more than 4000 typos (currently), so it
       may be slow depending on the particular setup.

    @author Héctor Romojaro <hector.romojaro@gmail.com>

    @creation-date 2018-07-23

} {
    set typo_list "[acs_package_root_dir "acs-tcl"]/tcl/test/doc-check-procs-common-typos.txt"
    set typos [dict create]

    # Create the typo dictionary with values from the common typos file
    set f [open $typo_list "r"]
    while {[gets $f line] >= 0} {
        dict append typos {*}[string tolower $line]
    }
    close $f
    aa_log "Created typo dictionary using data from $typo_list ([dict size $typos] typos loaded)"

    # Check for the typos
    set count 0
    set good 0
    set checks 0
    foreach p [lsort -dictionary [nsv_array names api_proc_doc]] {
        incr count
        set typo_number 0
        set proc_doc [dict create {*}[string tolower [nsv_get api_proc_doc $p]]]
        set main_doc [dict get $proc_doc main]
        #
        # Remove extra characters from the doc.
        #
        # string map is quick, but feel free to replace it with a quicker and/or
        # cleaner method.
        #
        set proc_doc_clean [concat \
            {*}[string map {& " " \" " " < " " > " " \[ " " \] " " , "" \{ "" \} ""} \
                $main_doc]]
        if { $proc_doc_clean ne "" } {
            foreach typo [dict keys $typos] {
                incr checks
                #ns_log Notice "Typo check in $p: Typo: $typo Doc: $proc_doc_clean"
                if { "$typo" in $proc_doc_clean } {
                    # Typo found!
                    incr typo_number
                    aa_log_result fail "$p spelling error: $typo -> [dict get $typos $typo]"
                }
            }
        }
        # Just count the number of procs without doc typos for summarizing
        if { $typo_number == 0 } {
            incr good
        }
    }
    aa_log "Documentation seems typo free in $good of $count checked procs (total typo checks: $checks)"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
