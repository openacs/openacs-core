ad_library {
    Check all the proc documentation

    @author Jeff Davis
    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2005-02-28
}

aa_register_case -cats {smoke production_safe} -procs {
    aa_log_result
} documentation__check_proc_doc {
    checks if documentation exists for public procs.

    @author Jeff Davis davis@xarg.net
} {
    set count 0
    set good 0
    #
    # Certain procs are defined outside the OpenACS installation
    # source tree, e.g. in nsf. If they fail the test, the regular
    # OpenACS administrator cannot do much about it, so we only
    # generate a warning for them.
    #
    set ignored_namespaces {
        nx
        nsshell
    }
    foreach p [lsort -dictionary [nsv_array names api_proc_doc]] {
        set pa [nsv_get api_proc_doc $p]
        if { [dict exists $pa protection]
             && "public" in [dict get $pa protection]
             && !([dict get $pa deprecated_p] || [dict get $pa warn_p])
             && ![string match *::slot* $p]
         } {
            incr count
            if { [string is space [join [dict get $pa main]]] &&
                 (![dict exists $pa return] || [string is space [join [dict get $pa return]]]) &&
                 (![dict exists $pa param] || [string is space [join [dict get $pa param]]]) &&
                 (![dict exists $pa see] || [string is space [join [dict get $pa see]]])
             } {
                if {[regexp "^(\\s+Class ::)?([join $ignored_namespaces |])::.*\$" $p m]} {
                    set test_result warning
                } else {
                    set test_result fail
                }
                aa_log_result $test_result "No documentation for public proc $p"
            } else {
                incr good
            }
        }
    }
    aa_log "Found $good public procs with proper documentation (out of $count checked)"

    if {[::acs::icanuse "ns_parsehtml"]} {
        set nrTags 0
        set nrNotAllowedTags 0
        set allowedTags {
            h3 /h3
            h4 /h4
            p /p
            a /a
            blockquote /blockquote
            dd /dd
            dt /dt
            dl /dl
            ul /ul
            ol /ol
            li /li
            table /table
            td /td
            th /th
            tr /tr
            pre /pre
            code /code
            tt /tt
            strong /strong
            b /b
            i /i
            em /em
            span /span
            br
        }
        foreach p [lsort -dictionary [nsv_array names api_proc_doc]] {
            set dict [nsv_get api_proc_doc $p]
            if {[dict exists $dict main]} {
                set text [dict get $dict main]
                foreach chunk [::ns_parsehtml -- $text] {
                    lassign $chunk what chunk content
                    if {$what eq "tag"} {
                        incr nrTags
                        set tag [lindex $content 0]
                        if {$tag ni $allowedTags} {
                            aa_error "[api_proc_link $p]: tag '$tag' not allowed '[ns_quotehtml <$content>]'"
                            incr nrNotAllowedTags
                        }
                    }
                }
            }
        }
        aa_log "Found $nrTags tags in documentation, $nrNotAllowedTags not allowed"
    }


}


aa_register_case -cats {smoke production_safe} -procs {
    aa_log_result
} naming__proc_naming {
    Check if names of Tcl procs follow the naming conventions
    https://openacs.org/xowiki/Naming

} {
    set count 0
    set good 0
    set allowedChars {^[a-zA-Z0-9_]+$}
    set allowedToplevel {^(_|(ad|acs|aa|adp|api|apm|chat|db|doc|ds|dt|cr|export|fs|general_comments|lc|news|ns|package|pkg_info|relation|rp|rss|sec|server_cluster|content_search|util|xml)_.+|callback|exec)$}
    set serverModuleProcs {^(h264open|h264length|h264read|h264eof|h264close|dom|bin|zip|transform|md5|base64|berkdb)$}
    set xmlRPC {^system\.(add|listMethods|multicall|methodHelp)$}
    set functionalOps {^f::(-|/)$}
    set internalUse {^(_.+|AcsSc[.].+|callback::.+|install::.+|.*[-](lob|text|gridfs|file))$}
    set prescribed {^((after|before|notifications)-([a-zA-Z0-9_]+))$}
    set nameWarning {public error private warning}

    foreach p [lsort -dictionary [nsv_array names api_proc_doc]] {
        if {[string match "* *" $p]} continue
        set info [nsv_get api_proc_doc $p]
        if {![dict exists $info script]} {
            aa_log "$p has no script (probably a referenced C-level cmd or a proc (no ad_proc)"
        } elseif {[dict get $info script] eq ""} {
            continue
        }
        incr count
        set tail [namespace tail $p]
        set qualifiers [regsub -all -- "::" [namespace qualifiers $p] "__"]
        if {[regexp $internalUse $p]
            || [regexp $serverModuleProcs $p]
            || [regexp $functionalOps $p]
            || [regexp $xmlRPC $p]
        } {
            continue
        }
        set protection [expr {[dict exists $info protection] && "public" in [dict get $info protection]
                          ? "public" : "private"}]

        if {![regexp $allowedToplevel $p] && ![string match *::* $p]} {
            if {[dict exists $info deprecated_p] && [dict get $info deprecated_p]} {
                aa_log_result warning "deprecated proc '$p' ($protection) is not in a namespace"
            } else {
                aa_log_result fail "proc '$p' ($protection) is not in a namespace: $info"
            }
        } elseif { (![regexp $allowedChars $tail]
                    || $qualifiers ne ""
                    && ![regexp $allowedChars $qualifiers]
                    )
                   && ![regexp $prescribed $tail]
               } {
            aa_log_result [dict get $nameWarning $protection] \
                "proc '$p' ($protection): name/namespace contains invalid characters"
        } else {
            incr good
        }
    }
    aa_log "Found $good good of $count checked"
}

aa_register_case -cats {smoke production_safe} -error_level warning -procs {
    aa_log_result
    api_proc_link
} documentation__check_deprecated_see {
    checks if deprecated procs have an @see clause

    @author Jeff Davis davis@xarg.net
} {
    set count 0
    set good 0
    foreach p [lsort -dictionary [nsv_array names api_proc_doc]] {
        set pa [nsv_get api_proc_doc $p]
        if { ([dict exists $pa deprecated_p] && [dict get $pa deprecated_p])
             || ([dict exists $pa warn_p] && [dict get $pa warn_p])
         } {
            incr count
            if { ![dict exists $pa see] || [string is space [dict get $pa see]] } {
                aa_silence_log_entries -severities warning {
                    aa_log_result fail "No @see for deprecated proc [api_proc_link $p]"
                }
            } else {
                incr good
            }
        }
    }
    aa_log "Found $good of $count procs checked"
}

aa_register_case -cats {smoke production_safe} -error_level warning -procs {
    aa_log_result
    acs_package_root_dir
} documentation__check_typos {

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
    set typo_list "[acs_package_root_dir acs-tcl]/tcl/test/doc-check-procs-common-typos.txt"
    set typos [dict create]

    # Create the typo dictionary with values from the common typos file
    set f [open $typo_list "r"]
    while {[gets $f line] >= 0} {
        if {[regexp {^(.*)[\|][\|](.*)$} [string tolower $line] . word replacement]} {
            dict set typos $word $replacement
        }
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

aa_register_case -cats {smoke production_safe} -error_level warning -procs {
    aa_log_result
} documentation__check_parameters {

    Check if the parameters defined in the proc doc as '@param' are actual
    parameters.

    Sometimes proc parameter changes are not reflected in the proc doc, this
    should take care of some of these cases.

    Test is case-sensitive.

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
        set deprecated_p [expr {[dict exists $proc_doc deprecated_p] &&
                                [dict get $proc_doc deprecated_p]}]
        if {!$deprecated_p && [dict exists $proc_doc param]} {
            incr count
            set params [dict get $proc_doc param]
            #
            # Build the real parameters list
            #
            #ns_log notice "check args for '$p'"
            set real_params [list \
                                 {*}[dict get $proc_doc switches0] \
                                 {*}[dict get $proc_doc positionals] \
                                 {*}[dict get $proc_doc switches1] \
                                ]
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
                if {$param ni $real_params && $param_trim_p ni $real_params} {
                    # Nonexistent @param found!
                    #ns_log notice "param_docs '$param_doc' real_params '$real_params'"
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
