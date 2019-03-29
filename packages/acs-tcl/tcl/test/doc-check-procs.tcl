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

aa_register_case \
    -cats {smoke production_safe} \
    -error_level warning \
    documentation__check_proc_testcase {

    Checks if testcases exist for public procs.

    @author Monika Andergassen <manderga@wu.ac.at>
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
            if { [info exists pa(testcase)] } {
                incr good
                aa_log "Testcase found for public proc $p"
            } else {
                aa_log_result fail "No testcase for public proc $p"
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
    foreach p [lsort -dictionary [nsv_array names api_proc_doc]] {
        incr count
        set typo_number 0
        set proc_doc [nsv_get api_proc_doc $p]
        if {[dict exists $proc_doc main]} {
            set main_doc [string tolower [dict get $proc_doc main]]
            #
            # Remove extra characters from the doc.
            #
            set proc_doc_clean [string map $ignorechars $main_doc]
            if { [string length $proc_doc_clean] > 0} {
                #
                # Check the words of the documentation string
                # against the dictionary.
                #
                foreach word [lsort -unique $proc_doc_clean] {
                    incr checks
                    if {[dict exists $typos $word]} {
                        # Typo found!
                        incr typo_number
                        aa_log_result fail "spelling error in proc $p: $word -> [dict get $typos $word]"
                    }
                }
            }
            # Just count the number of procs without doc typos for summarizing
            if { $typo_number == 0 } {
                incr good
            }
        }
    }
    aa_log "Documentation seems typo free in $good of $count checked procs (total typo checks: $checks)"
}

aa_register_case -cats {smoke production_safe} -error_level warning documentation__check_parameters {

    Check if the parameters defined in the proc doc as '@param' are actual
    parameters.

    Sometimes proc parameter changes are not reflected in the proc doc, this
    should take care of some of these cases.

    Test is case sensitive.

    @author Héctor Romojaro <hector.romojaro@gmail.com>

    @creation-date 2018-07-24

} {
    set count 0
    set good 0
    set ignorechars {
        , " "
        ( " " ) " " < " " > " "
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

    foreach p [lsort -dictionary [nsv_array names api_proc_doc]] {
        set param_unknown 0
        set proc_doc [nsv_get api_proc_doc $p]
        if {[dict exists $proc_doc param]} {
            incr count
            set params [dict get $proc_doc param]
            #
            # Build the real parameters list
            #
            set real_params [list \
                {*}[dict get $proc_doc switches] \
                {*}[dict get $proc_doc positionals]]
            #
            # Check if the last parameter is 'args', as it is not included into
            # 'switches' or 'positionals', and add it to the real parameter list
            #
            if {[dict get $proc_doc varargs_p]} {
                lappend real_params args
            }
            #
            # Check if the @param exists in the list of parameters
            #
            foreach param_doc $params {
                set param [lindex [string map $ignorechars $param_doc] 0]
                # Allow boolean parameter name with appended '_p'
                regsub -- _p$ $param "" param_trim_p
                if {"$param" ni $real_params && "$param_trim_p" ni $real_params} {
                    # Nonexistent @param found!
                    incr param_unknown
                    aa_log_result fail "Unknown parameter '$param' in documentation of proc '$p'"
                }
            }
            # Just count the number of procs without nonexistent @params
            if { $param_unknown == 0 } {
                incr good
            }
        }
    }
    aa_log "@param names seem coherent with the actual proc parameters in $good of $count checked procs"
}

if {[parameter::get \
    -package_id [apm_package_id_from_key acs-api-browser] \
    -parameter IncludeCallingInfo \
    -default false]} {

    aa_register_case \
        -cats {smoke production_safe} \
        -error_level warning \
        cross_package_called_private_functions {

            Search for cross-package calls of private functions.

            @author Gustaf Neumann

            @creation-date 2018-07-25
        } {
            set count 0
            set fails 0
            set private 0

            foreach called [lsort -dictionary [nsv_array names api_proc_doc]] {
                incr count
                set called_by_count 0
                set called_info [nsv_get api_proc_doc $called]
                if {[dict exists $called_info calledby]
                    && [dict exists $called_info script]
                    && [dict exists $called_info protection]
                    && [dict get $called_info protection] eq "private"
                } {
                    incr private
                    regexp {^packages/([^/]+)/} [dict get $called_info script] . called_package_key
                    foreach caller [lsort [dict get $called_info calledby]] {
                        incr called_by_count
                        if {[nsv_get api_proc_doc $caller caller_info]
                            && [dict exists $caller_info script]
                            && ![string match "AcsSc.*" $caller]
                        } {
                            regexp {^packages/([^/]+)/} [dict get $caller_info script] . caller_package_key
                            if {$caller_package_key ne $called_package_key} {
                                incr fails
                                set msg ""
                                append msg \
                                    "private function &lt;$called_package_key $called> " \
                                    "called by &lt;$caller_package_key $caller><br>" \
                                    [dict get $called_info script] "<br>" \
                                    [dict get $caller_info script]
                                aa_log_result fail $msg
                            }
                        }
                    }
                    ns_log notice "private function $called called by $called_by_count functions"
                }
            }
            aa_log "Found $fails cross-package private calls out of a total of $private private calls (total: $count call sites)"
        }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
