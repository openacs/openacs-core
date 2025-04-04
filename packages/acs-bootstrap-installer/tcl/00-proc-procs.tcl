# For documentation, see the ad_library call at the bottom of this script.

nsv_array set api_proc_doc [list]
nsv_array set api_proc_doc_scripts [list]
nsv_array set api_library_doc [list]
nsv_array set proc_doc [list]
nsv_array set proc_source_file [list]

if {[info commands ::nx::Class] ne ""} {
    nx::Class create acs::DocHelper {
        #
        # Helper class to determine the sourcefile, where some "public",
        # "private", or plain "methods" is defined. The mixin is just
        # active during initial bootstrap of the server. The definition
        # assumes, that all definitions for a class are from the same
        # file.
        #
        :method register_filename {} {
            nsv_set proc_source_file " Class [self]" [info script]
            #ns_log notice "INIT registered epoch [ns_ictl epoch] [self] script [info script]"
        }
        :public method method {args} {
            #
            # Intercept "method" definitions to record the current
            # filename for the API browser.
            #
            :register_filename
            return [next]
        }
        :public method public {what name args} {
            #
            # Intercept "public method" definitions to record the
            # current filename for the API browser.
            #
            :register_filename
            return [next]
        }
        :public method protected {what name args} {
            #
            # Intercept "protected method" definitions to record the
            # current filename for the API browser.
            #
            :register_filename
            return [next]
        }
        #
        # Alternate approach, would require a small change in NX.
        #
        # :public method create {name args} {
        #     #ns_log notice "INIT create [self] $name (epoch [ns_ictl epoch])"
        #     set r [next]
        #     if {[self] eq "::nx::Class" && [ns_ictl epoch] < 2} {
        #         set key " Class $name"
        #         nsv_set proc_source_file $key [info script]
        #         ns_log notice "INIT nsv_set proc_source_file $key [info script]"
        #         #
        #         # Problem with
        #         #    ::nx::Class create ::acs::SiteNode {
        #         #        ... :create site_node
        #         #    }
        #     }
        #     return $r
        # }
    }
    if {[ns_ictl epoch] == 0} {
        nx::Class mixins add acs::DocHelper
        #ns_log notice "REGISTER xo::DocHelper INIT epoch [ns_ictl epoch]"
    }
} else {
    ns_log error "no NSD/NX available. Installation is apparently incomplete or misconfigured"
}

#
# Safety belt for ::acs::useNsfProc for upgrade phase to oacs-5-9
#
if {![info exists ::acs::useNsfProc]} {
    ns_log notice "use fallback value for ::acs::useNsfProc"
    set ::acs::useNsfProc 0
} else {
    #
    # Keep the initcmds of classes for documentation purposes.
    #
    ::nsf::configure keepcmds 1
}
if {![info exists ::acs::useNaviServer]} {
    ns_log notice "use fallback value for ::acs::useNaviServer"
    set ::acs::useNaviServer [expr {[ns_info name] eq "NaviServer"}]
}

proc empty_string_p { query_string } {
    return [string equal $query_string ""]
}

proc acs_root_dir {} {
    return $::acs::rootdir
}

proc acs_package_root_dir { package_key } {
    return [file join $::acs::rootdir packages $package_key]
}

proc ad_make_relative_path { path } {
    set root_length [string length $::acs::rootdir]
    if { $::acs::rootdir eq [string range $path 0 $root_length-1] } {
        return [string range $path $root_length+1 [string length $path]]
    }
    error "$path is not under the path root ($::acs::rootdir)"
}

proc ad_get_tcl_call_stack { { level -2 }} {
    set stack ""
    #
    # keep the previous state of ::errorInfo
    #
    set errorInfo $::errorInfo

    for { set x [expr {[info level] + $level}] } { $x > 0 } { incr x -1 } {
        set info [info level $x]
        regsub -all \n $info {\\n} info
        #
        # In case, we have an NSF frame, add information about the
        # current object and the current class to the debug output.
        #
        if {![catch {uplevel #$x ::nsf::current} obj]
            && ![catch {uplevel #$x [list ::nsf::current class]} class]
        } {
            set objInfo [list $obj $class]
            set info "{$objInfo} $info"
        }
        #
        # Don't produce too long lines
        #
        if {[string length $info]>200} {
            set arglist ""
            foreach arg $info {
                if {[string length $arg]>40} {set arg [string range $arg 0 40]...}
                lappend arglist $arg
            }
            set info $arglist
        }
        append stack "    called from $info\n"
    }
    #
    # restore previous state of ::errorInfo
    #
    set ::errorInfo $errorInfo
    return $stack
}

proc ad_parse_documentation_string { doc_string elements_var } {
    upvar $elements_var elements
    if { [info exists elements] } {
        unset elements
    }

    set lines [split $doc_string "\n\r"]

    array set elements [list]
    set current_element main
    set buffer ""

    foreach line $lines {

        # lars@pinds.com, 8 July, 2000
        # We don't do a string trim anymore, because it breaks the formatting of
        # code examples in the documentation, something that we want to encourage.

        # set line [string trim $line]

        if { [regexp {^[ \t]*@([-a-zA-Z_]+)(.*)$} $line "" element remainder] } {
            lappend elements($current_element) [string trim $buffer]

            set current_element $element
            set buffer "$remainder\n"
        } else {
            append buffer $line "\n"
        }
    }

    lappend elements($current_element) [string trim $buffer]
}

proc ad_proc_valid_switch_p {str} {
    #
    # Check if this looks like a switch:
    #   - first character is '-'
    #   - next character is not a Tcl number
    #   - next string is a printable character
    #
    return [expr {[string index $str 0] eq "-"
              && ![string is double -strict $str]
              && [regexp {^-[[:graph:]]+$} $str]
    }]
}

proc ad_proc args {
    set public_p 0
    set private_p 0
    set deprecated_p 0
    set warn_p 0
    set debug_p 0
    set callback ""
    set impl ""

    # Loop through args, stopping at the first argument which is
    # not a switch.
    for { set i 0 } { $i < [llength $args] } { incr i } {
        set arg [lindex $args $i]

        # If the argument doesn't begin with a hyphen, break.
        if { ![ad_proc_valid_switch_p $arg] } {
            break
        }

        # If the argument is "--", stop parsing for switches (but
        # bump up $i to the next argument, which is the first
        # argument which is not a switch).
        if {$arg eq "--"} {
            incr i
            break
        }

        switch -- $arg {
            -public { set public_p 1 }
            -private { set private_p 1 }
            -deprecated { set deprecated_p 1 }
            -warn { set warn_p 1 }
            -debug { set debug_p 1 }
            -callback {
                incr i
                set callback [lindex $args $i]
                if { [ad_proc_valid_switch_p $callback] } {
                    return -code error "Missing callback name: -callback <name>"
                }
            }
            -impl {
                incr i
                set impl [lindex $args $i]
                if { [ad_proc_valid_switch_p $impl] } {
                    return -code error "Missing implementation name: -impl <name>"
                }
            }
            default {
                return -code error "Invalid switch [lindex $args $i] passed to ad_proc"
            }
        }
    }

    # Callback hooks and callback implementations are treated as
    # private: rationale is they never get called by other packages
    # directly.
    if {$callback ne ""} {
        set public_p 0
        set private_p 1
    }

    if { $public_p && $private_p } {
        return -code error "Mutually exclusive switches -public and -private passed to ad_proc"
    }

    if { !$public_p && !$private_p } {
        set public_p 1
    }
    if {$public_p} {
        set protection public
    } else {
        set protection private
    }

    if { $warn_p && !$deprecated_p } {
        return -code error "Switch -warn can be provided to ad_proc only if -deprecated is also provided"
    }

    if { $deprecated_p } {
        set warn_p 1
    }

    if { $impl ne "" && $callback eq "" } {
        return -code error "A callback contract name must be specified with -callback when defining an implementation with -impl"
    }

    if { $impl eq "impl" || [string match $impl "impl::*"] } {
        return -code error "Callback implementations may not be named impl"
    }

    if { $callback eq "contract" || [string match $callback "contract::*"] } {
        return -code error "Callbacks may not be named contract"
    }

    # Now $i is set to the index of the first non-switch argument.
    # There must be either three or four arguments remaining.
    set n_args_remaining [expr { [llength $args] - $i }]

    if {$callback eq ""} {
        #
        # We are creating an ordinary proc so the proc name is an
        # argument
        #
        if { $n_args_remaining < 3 || $n_args_remaining > 4} {
            return -code error "Wrong number of arguments passed to ad_proc"
        }

        # Set up the remaining arguments.
        set proc_name [lindex $args $i]
    } else {
        if {$impl ne "" } {
            #
            # We are creating a callback implementation
            #
            if {$n_args_remaining != 3} {
                return -code error "ad_proc callback implementation must have: arguments (can be empty) docs code_body"
            }
        }
        if {$impl eq ""} {
            #
            # We are creating a contract for a callback
            #
            if {!( $n_args_remaining == 3 || $n_args_remaining == 2 ) } {
                return -code error "ad_proc callback contract must have: arguments docs \[empty_code_body\]"
            } elseif {$n_args_remaining == 3
                      && [lindex $args end] ne ""
                      && [lindex $args end] ne "-" } {
                return -code error "ad_proc callback contract must have an empty code_body"
            }
        }

        set callback [string trimleft $callback ::]
        set proc_name ::callback::${callback}

        if {$impl eq ""} {
            append proc_name ::contract
        } else {
            append proc_name ::impl::${impl}
        }

        # pretend to the rest of the proc that we were passed the proc name
        incr n_args_remaining
        set args [linsert $args 0 $proc_name]
    }

    # (SDW - OpenACS). If proc_name is being defined inside a namespace, we
    # want to use the fully qualified name. Except for actually defining the
    # proc where we want to use the name as passed to us. We always set
    # proc_name_as_passed and conditionally make proc_name fully qualified
    # if we were called from inside a namespace eval.

    #
    # RBM: 2003-01-26:
    # With the help of Michael Cleverly, fixed the namespace code so procs
    # declared like ::foo::bar would work, by only trimming the first ::
    # Also moved the uplevel'd call to namespace current to the if statement,
    # to avoid it being called unnecessarily.
    #

    set proc_name_as_passed $proc_name
    set parent_namespace [string trimleft [uplevel 1 {::namespace current}] ::]

    if { ![string match "::*" $proc_name] } {
        set proc_name ${parent_namespace}::$proc_name
    }
    if {$parent_namespace ne {} && ![string match "::*" $proc_name]} {
        ns_log Debug "proc $proc_name_as_passed declared in namespace $parent_namespace via namespace eval; coding standard is to declare as $proc_name"
    }
    set proc_name [string trimleft $proc_name ::]


    if { $callback ne "" } {
        # Do a namespace eval of each namespace to ensure it exists
        set namespaces [lrange [split $proc_name ::] 0 end-1]

        set curr_ns ""
        foreach ns $namespaces {
            if {$ns ne "" } {
                append curr_ns "::$ns"
                namespace eval $curr_ns {}
            }
        }
    }

    set arg_list [lindex $args $i+1]
    if { $n_args_remaining == 3 } {
        # No doc string provided.
        #ns_log notice "missing doc string for ad_proc $proc_name ([info script])"
        array set doc_elements [list]
        set doc_elements(main) ""
    } else {
        # Doc string was provided.
        ad_parse_documentation_string [lindex $args end-1] doc_elements
    }

    #
    # Preserve pre-existing values, e.g. from testcases, which might
    # be loaded in a different order.
    #
    if {[nsv_exists api_proc_doc $proc_name]} {
        set old_doc_elements [nsv_get api_proc_doc $proc_name]
        #array set doc_elements $old_doc_elements
        if {[dict exist $old_doc_elements testcase]} {
            #ns_log notice "PRESERVE TESTCASES: $proc_name"
            set doc_elements(testcase) [dict get $old_doc_elements testcase]
        }
    }

    set code_block [lindex $args end]

    if {$callback ne "" && $impl ne "" } {
        if {[info exists doc_elements(see)]} {
            lappend doc_elements(see) "callback::${callback}::contract"
        } else {
            set doc_elements(see) "callback::${callback}::contract"
        }
    }

    #####
    #
    #  Parse the argument list.
    #
    #####

    set switches0 {}
    set switches1 {}
    set positionals [list]
    set seen_positional_with_default_p 0
    set n_positionals_with_defaults 0
    array set default_values [list]
    array set flags [list]
    set seen_arg_checkers_p 0
    set varargs_p 0
    set switch_code ""

    #
    # If the first element contains 0 or more than 2 elements, then it must
    # be an old-style ad_proc. Mangle effective_arg_list accordingly.
    #
    if { [llength $arg_list] > 0 } {
        set first_arg [lindex $arg_list 0]
        if { [llength $first_arg] == 0 || [llength $first_arg] > 2 } {
            ns_log Warning "Convert old (deprecated) style proc: $proc_name"
            set new_arg_list [list]
            foreach { switch default_value } $first_arg {
                lappend new_arg_list [list $switch $default_value]
            }
            set arg_list [concat $new_arg_list [lrange $arg_list 1 end]]
        }
    }

    set effective_arg_list $arg_list

    set last_arg [lindex $effective_arg_list end]
    if { [llength $last_arg] == 1 && [lindex $last_arg 0] eq "args" } {
        set varargs_p 1
        set effective_arg_list [lrange $effective_arg_list 0 [llength $effective_arg_list]-2]
    }

    set check_code ""
    foreach arg $effective_arg_list {
        if { [llength $arg] == 2 } {
            set default_p 1
            lassign $arg arg default_value
        } else {
            if { [llength $arg] != 1 } {
                return -code error "Invalid element \"$arg\" in argument list"
            }
            set default_p 0
        }

        set arg_flags [list]
        set arg_split [split $arg ":"]
        if { [llength $arg_split] == 2 } {
            set arg [lindex $arg_split 0]
            foreach flag [split [lindex $arg_split 1] ","] {
                set flag [string trim $flag]
                if { $flag ne "required" && $flag ne "boolean" } {
                    #
                    # In earlier versions, we used to raise an error here
                    #
                    #    return -code error "Invalid flag \"$flag\""
                    #
                    # However, since XOTcl 2 (and nsf::proc) support
                    # arg checkers since many years, and since XOTcl
                    # is a required component of OpenACS, we can allow
                    # these as well safely. However, in order to avoid
                    # surprises during upgrades, we should avoid the
                    # checker usage in acs-core, until OpenACS 5.10 is
                    # released.
                    #
                    set seen_arg_checkers_p 1
                }
                lappend arg_flags $flag
            }
        } elseif { [llength $arg_split] != 1 } {
            return -code error "Invalid element \"$arg\" in argument list"
        }

        if {[string index $arg 0] eq "-"} {
            if { [llength $positionals] > 0} {
                if {$::acs::useNsfProc} {
                    set trailing_nonpos_p 1
                } else {
                    return -code error "Switch -$arg specified after positional parameter"
                }
            } else {
                set trailing_nonpos_p 0
            }

            set switch_p 1
            set arg [string range $arg 1 end]
            lappend switches$trailing_nonpos_p $arg

            if {"boolean" in $arg_flags} {
                set default_values(${arg}_p) 0
                append switch_code "            -$arg - -$arg=1 - -$arg=t - -$arg=true {
                        ::uplevel ::set ${arg}_p 1
                    }
                    -$arg=0 - -$arg=f - -$arg=false {
                        ::uplevel ::set ${arg}_p 0
                    }
                "
            } else {
                append switch_code "            -$arg {
                    if { \$i >= \[llength \$args\] - 1 } {
                        ::return -code error \"No argument to switch -$arg\"
                    }
                    ::upvar ${arg} val ; ::set val \[::lindex \$args \[::incr i\]\]\n"
                append switch_code "            }\n"
            }

            if {"required" in $arg_flags} {
                append check_code "    ::if { !\[::uplevel ::info exists $arg\] } {
                    ::return -code error \"Required switch -$arg not provided\"
                    }
                "
            }
        } else {
            set switch_p 0
            if { $default_p } {
                incr n_positionals_with_defaults
            }
            if { !$default_p && $n_positionals_with_defaults != 0 } {
                return -code error "Positional parameter $arg needs a default value (since it follows another positional parameter with a default value)"
            }
            lappend positionals $arg
        }

        set flags($arg) $arg_flags

        if { $default_p } {
            set default_values($arg) $default_value
        }

        if { [llength $arg_split] > 2 } {
            return -code error "Invalid format for parameter name: \"$arg\""
        }
    }

    foreach element { protection deprecated_p warn_p varargs_p arg_list switches0 positionals switches1} {
        set doc_elements($element) [set $element]
    }
    foreach element { default_values flags } {
        set doc_elements($element) [array get $element]
    }

    set script [info script]
    if {$script eq "" && [info exists ::ad_conn(file)]} {
        set script $::ad_conn(file)
        ns_log notice "ad_proc: get script name for proc '$proc_name' from ad_conn(file): $script"
    }
    if {$script eq "" && [info exists ::xotcl::currentScript]} {
        set script $::xotcl::currentScript
    }
    set root_length [string length $::acs::rootdir]
    if { $::acs::rootdir eq [string range $script 0 $root_length-1] } {
        set script [string range $script $root_length+1 end]
    }

    set doc_elements(script) $script
    if {[regexp {^packages/([^/]+)/} $script . package_key]} {
        set  doc_elements(package_key) $package_key
    } else {
        ad_log warning "cannot determine package key from script '$script': ad_proc $args"
    }
    #
    # As acs-automated-testing/tcl/aa-test-procs.tcl is loaded on startup before
    # acs-bootstrap-installer/tcl/00-proc-procs.tcl, it is possible that the
    # testcase element of the api_proc_doc nsv has been already populated,
    # therefore creating the key for that proc on the nsv.
    #
    # Previously, some procs where not included in the api_proc_doc_scripts nsv
    # because of that, as the nsv lappend was skipped if the key existed.
    #
    # For example:
    # - file_storage::twt::delete_file
    # - file_storage::twt::create_url_in_folder
    # - file_storage::twt::create_url
    # - ...
    #
    # We avoid this by checking as well if the testcase element is the only one
    # for that particular proc in the nsv.
    #
    if { ![nsv_exists api_proc_doc $proc_name]
         || (
             [dict exists [nsv_get api_proc_doc $proc_name] testcase]
             && [dict size [nsv_get api_proc_doc $proc_name]] eq "1"
             )
    } {
        nsv_lappend api_proc_doc_scripts $script $proc_name
    }

    nsv_set api_proc_doc $proc_name [array get doc_elements]

    # Backward compatibility: set proc_doc and proc_source_file
    nsv_set proc_doc $proc_name [lindex $doc_elements(main) 0]
    if { [nsv_exists proc_source_file $proc_name]
      && [nsv_get proc_source_file $proc_name] ne [info script]
     } {
        ns_log Warning "Multiple definition of $proc_name in [nsv_get proc_source_file $proc_name] and [info script]"
    }
    nsv_set proc_source_file $proc_name [info script]

    if {$code_block eq "-"} {
        if {$callback eq ""} {
            return
        } else {
            # we are creating a callback so create an empty body
            set code_block {
            # this is a callback contract which only invokes its arg parser for input validation
            }
        }
    }

    set log_code ""
    if { $warn_p } {
        set log_code [list ad_log_deprecated proc $proc_name]
    }

    if { $callback ne "" && $impl ne "" } {

        if { [namespace which ::callback::${callback}::contract__arg_parser] eq "" } {
            # We create a dummy arg parser for the contract in case
            # the contract hasn't been defined yet.  We need this
            # because the implementation doesn't tell us what the
            # args of the contract should be.
            uplevel [::list proc ::callback::${callback}::contract__arg_parser {} {}]
        }

        # We are creating a callback implementation so we invoke the
        # arg parser of the contract proc

        if {$::acs::useNsfProc} {
            uplevel [::list proc $proc_name_as_passed args \
                 "    ::callback::${callback}::contract__arg_parser {*}\$args\n${log_code}$code_block"]
        } else {
            uplevel [::list proc $proc_name_as_passed args \
                 "    ::callback::${callback}::contract__arg_parser\n${log_code}$code_block"]
        }

    } elseif { $callback eq ""
               && [llength $switches0] + [llength $switches1] == 0
               && !$seen_arg_checkers_p} {
        #
        # Nothing special is used in the argument definition, create a
        # plain proc
        #
        uplevel [::list proc $proc_name_as_passed $arg_list "${log_code}$code_block"]

    } else {
        #
        # Default case, plain Tcl can't handle these cases
        #

        if {$::acs::useNsfProc} {
            #
            # nsf::proc can handle these cases. Just in case of the
            # callback implementations we have to provide an
            # arg_parser of the contract, since OpenACS uses always
            # the argument definition of the contract to pass
            # arguments in the implementation (which can be very
            # confusing).
            #
            if {$callback ne ""} {
                uplevel [::list ::nsf::proc -ad ::callback::${callback}::contract__arg_parser $arg_list {
                    foreach _ [info vars] {
                        uplevel [::list set $_ [set $_]]
                    }
                }]
            }
            #ns_log notice "---- define nsf::proc for [::list proc -ad -debug=$debug_p $proc_name_as_passed $arg_list $code_block]"
            uplevel [::list ::nsf::proc \
                         -ad \
                         -debug=$debug_p \
                         $proc_name_as_passed \
                         $arg_list \
                         ${log_code}$code_block]
            return
        }

        #
        # There is no nsf::proc available. Define for every remaining
        # function two procs, one for argument parsing, and one for
        # the invocation. The latter one is defined with "args" and
        # calls as first step the argument parser.
        #
        set parser_code "    ::upvar args args\n"
        foreach { name value } [array get default_values] {
            append parser_code "    ::upvar $name val ; ::set val [::list $value]\n"
        }

        append parser_code "
            ::for { ::set i 0 } { \$i < \[::llength \$args\] } { ::incr i } {
                ::set arg \[::lindex \$args \$i\]
                ::if { !\[::ad_proc_valid_switch_p \$arg\] } {
                    ::break
                }
                ::if { \[::string equal \$arg \"--\"\] } {
                    ::incr i
                    ::break
                }
                ::switch -- \$arg {
        $switch_code
                    default { ::return -code error \"Invalid switch: \\\"\$arg\\\"\" }
                }
            }
        "

        set n_required_positionals [expr { [llength $positionals] - $n_positionals_with_defaults }]
        append parser_code "
            ::set n_args_remaining \[::expr { \[::llength \$args\] - \$i }\]
            ::if { \$n_args_remaining < $n_required_positionals } {
                ::return -code error \"No value specified for argument \[::lindex { [::lrange $positionals 0 [::expr { $n_required_positionals - 1 }]] } \$n_args_remaining\]\"
            }
        "
        for { set i 0 } { $i < $n_required_positionals } { incr i } {
                append parser_code "    ::upvar [::lindex $positionals $i] val ; ::set val \[::lindex \$args \[::expr { \$i + $i }\]\]\n"
        }
        for {} { $i < [llength $positionals] } { incr i } {
            append parser_code "    ::if { \$n_args_remaining > $i } {
                    ::upvar [::lindex $positionals $i] val ; ::set val \[::lindex \$args \[::expr { \$i + $i }\]\]
                }
            "
        }

        if { $varargs_p } {
            append parser_code "    ::set args \[::lrange \$args \[::expr { \$i + [::llength $positionals] }\] end\]\n"
        } else {
            append parser_code "    ::if { \$n_args_remaining > [::llength $positionals] } {
                    return -code error \"Too many positional parameters specified\"
                }
                ::unset args
            "
        }

        append parser_code $check_code

        if { $debug_p } {
            ns_write "PARSER CODE:\n\n$parser_code\n\n"
        }

        #
        # old style proc
        # for a function foo, define "foo $args" and "foo__arg_parser"
        #
        #ns_log notice "=== old style proc $proc_name_as_passed"

        uplevel [::list proc ${proc_name_as_passed}__arg_parser {} $parser_code]
        uplevel [::list proc $proc_name_as_passed args "    ${proc_name_as_passed}__arg_parser\n${log_code}$code_block"]
    }
}

ad_proc -public ad_proc {
    -public:boolean
    -private:boolean
    -deprecated:boolean
    -warn:boolean
    {-callback ""}
    {-impl ""}
    arg_list
    [doc_string]
    body
} {
    <p>
    Declare a procedure with the following enhancements
    over regular Tcl "<code>proc</code>":
    </p>

    <p>
    <ul>
      <li> A procedure can be declared as public, private, deprecated, and warn.</li>
      <li> Procedures can be declared with regular <i>positional</i> parameters (where
           you pass parameters in the order they were declared), or with <i>named</i>
           parameters, where the order doesn't matter because parameter names are
           specified explicitly when calling the parameter. Named parameters are
           preferred.</li>
      <li> If you use named parameters, you can specify which ones are required, optional,
           (including default values), and boolean. See the examples below.</li>
      <li> Positional parameters are always required, unless they provide with a default value,
           making them optional. If the parameter follows another positional parameter with a default
           value, a default value for it is also required.</li>
      <li> As well as in the original Tcl "<code>proc</code>", if the last parameter is called
           "<tt>args</tt>", the proc will accept a variable number of arguments, which will be
           assigned to the variable "<tt>args</tt>" as elements of a list.</li>
      <li> There is now a callback facility. See below.</li>
      <li> The declaration can (and <b>should!</b>) include documentation. This documentation
           may contain tags which are parsed for display by the API browser.  Some tags are
           <tt>@param</tt>, <tt>@return</tt>, <tt>@error</tt>, <tt>@see</tt>, <tt>@author</tt>
           (probably this should be better documented).</li>
    </ul>
    </p>

    <p>
      When a parameter is declared as <tt>boolean</tt>, it creates a variable <tt>$param_name_p</tt>.
      For example: <tt>-foo:boolean</tt> will create a variable <tt>$foo_p</tt>.
      If the parameter is passed, <tt>$foo_p</tt> will have value 1. Otherwise,
      <tt>$foo_p</tt> will have value 0.
    </p>
    <p>
      Boolean named parameters can optionally take a boolean value than can
      make your code cleaner. The following example by Michael Cleverly shows why:
      If you had a procedure declared as <tt>ad_proc foobar {-foo:boolean} { ... }</tt>,
      it could be invoked as <tt>foobar -foo</tt>, which could yield some code like
      the following in your procedure:
    </p>
    <pre>
if {$flush_p} {
    some_proc -flush $key
} else {
    some_proc $key
}
    </pre>

    <p>
      However, you could invoke the procedure as <tt>foobar -foo=$some_boolean_value</tt>
      (where some_boolean_value can be 0, 1, t, f, true, false),
      which could make your procedure cleaner because you could write instead:
      <tt>some_proc -flush=$foo_p $key</tt>.
    </p>
    <p>
      With named parameters, the same rule as the Tcl <tt>switch</tt> statement apply,
      meaning that <tt>--</tt> marks the end of the parameters. This is important if
      your named parameter contains a value of something starting with a "-".
    </p>
    <p>
    Here's an example with named and positional parameters, and also namespaces (notice the
    preferred way of declaring namespaces and namespaced procedures). Ignore the \ in "\@param",
    I had to use it so the API browser wouldn't think the parameter docs were for ad_proc
    itself:
    </p>

    <p>
    <pre>
namespace eval ::foobar {}

ad_proc -public ::foobar::new {
    {-oacs_user:boolean}
    {-shazam:required}
    {-foo}
    {-user_id ""}
    {pos}
    {pos_opt ""}
} {
    The documentation for this procedure should have a brief description of the
    purpose of the procedure (the WHAT), but most importantly, WHY it does what it
    does. One can read the code and see what it does (but it's quicker to see a
    description), but one cannot read the mind of the original programmer to find out
    what s/he had in mind.

    \@author Roberto Mello
    \@creation-date 2002-01-21

    \@param oacs_user   If this user is already an OpenACS user. oacs_user_p is defined
                        per default as "false", when specified as "true". The parameter is optional.
    \@param shazam      Magical incantation that calls Captain Marvel. Required parameter.
    \@param foo         Parameter, which can be omitted. Check with [info exists ...] if was given.
    \@param user_id     The id for the user to process. Optional with default "".
                        (api-browser shows the default).
    \@param pos         Positional parameter. Required, as it does not provide a default value.
    \@param pos_opt     Positional parameter. Optional with default "".
                        (api-browser shows the default).
    \@return empty list

    \@see ::foobar::related_proc
} {
    if { $user_id eq "" } {
        # Do something if this is not an empty string
    }
    if { [info exists foo] } {
        # Do something if we got a value for "foo"
    }

    if { $oacs_user_p } {
        # Do something if this is an OpenACS user
    }

    # return empty list anyway...
    return [list]
}
</pre>
    </p>
    <p>
      (note, most of the info on callbacks here due to leeldn)<p>
      You can define callbacks, both generally (which you would do first) and specific
      to a particular implementation. The way you do so is:
    </p>
    <p>
      <ul>
        <li>you have to first define the callback contract with
          <code>ad_proc -callback foo::bar::zip { arg1 arg2 } { docs } -</code>
          <p>This defines the callback generally. (<em>Note! Don't define a body here!</em>)
        <li>then define an implementation with
            <code>ad_proc -callback foo::bar::zip -impl myimpl  { } { } { #code }</code>
        <li>Two ways to call:
            <ul>
              <li>then you can call _all_ implementations (i.e. in an event / event handler type arrangement) with
                <code>callback foo::bar::zip $arg1 $arg2</code>
                      <li>or you can call a specific implementation (i.e. in a service contract type arrangement) with
                          <code>callback -impl myimpl foo::bar::zip $arg1 $arg2</code>
            </ul>
            <li>in both cases the result is a list of the results of each called implementation (with empty results removed),
            so in the case of calling a specific implementation you get a list of one element as the result
        <li>See <a href="/api-doc/proc-view?proc=callback"><code>callback</code></a> for more info.
      </ul>
    </p>


    @param public specifies that the procedure is part of a public API.
    @param private specifies that the procedure is package-private.
    @param deprecated specifies that the procedure should not be used.
    @param warn specifies that the procedure should generate a warning
                when invoked (requires that -deprecated also be set)
    @param callback the name of the callback contract being defined or
                    implemented. When this flag is specified, -private
                    and -public flags are ignored and the resulting
                    proc will always be private.
    @param impl the name of the callback implementation for the specified
                contract
    @param arg_list the list of switches and positional parameters which can be
        provided to the procedure.
    @param [doc_string] documentation for the procedure (optional, but greatly desired).
    @param body the procedure body.  Documentation may be provided for an arbitrary function
    by passing the body as a "-".

} -

ad_proc -public ad_arg_parser { allowed_args argv } {
    Parses an argument list for a database call (switches at the end).
    Switch values are placed in corresponding variable names in the calling
    environment.

    GN: This function is a hack to overcome shortcomings of argument
    parsing at the first place, since the old-style argument parser of
    OpenACS does NOT support non-positional arguments after the
    positional ones. Since the advent of XOTcl2, this limitation is
    gone and just used for installations without XOTcl.... but since
    XOTcl is required since many years, this is not an issue anymore.

    @param allowed_args a list of allowable switch names.
    @param argv a list of command-line options. May end with <code>args</code> to
        indicate that extra values should be tolerated after switches and placed in
        the <code>args</code> list.
    @error if the list of command-line options is not valid.

} {
    #ns_log notice "ad_arg_parser '$allowed_args' <$argv>"

    if {[lindex $allowed_args end] eq "args"} {
        set varargs_p 1
        set allowed_args [lrange $allowed_args 0 [llength $allowed_args]-2]
    } else {
        set varargs_p 0
    }

    if { $varargs_p } {
        upvar args args
        set args [list]
    }

    set counter 0
    foreach { switch value } $argv {
        if { [string index $switch 0] ne "-" } {
            if { $varargs_p } {
            set args [lrange $argv $counter end]
            return
            }
            return -code error "Expected switch but encountered \"$switch\""
        }
        set switch [string range $switch 1 end]
        if { [lsearch $allowed_args $switch] < 0 } {
            return -code error "Invalid switch -$switch (expected one of -[join $allowed_args ", -"])"
        }
        upvar $switch switch_var
        set switch_var $value
        incr counter 2
    }
    if { [llength $argv] % 2 != 0 } {
        # The number of arguments has to be even!
        return -code error "Invalid switch syntax - no argument to final switch \"[lindex $argv end]\""
    }
}

ad_proc -public callback {
    -catch:boolean
    {-impl *}
    callback
    args
} {
    Invoke the registered callback implementations for the given
    callback.  The callbacks terminate on error unless -catch
    is provided.  The value returned by the callback function is
    determined by the return codes from the callback implementations.
    <p>
    The callbacks are executed one level below the calling function
    so passing arrays to a callback can be done normally via
    <pre>upvar arrayname $arrayref</pre>
    <p>
    The return codes returned from the implementation are treated
    as follows:
    <dl>
     <dt>return -code ok or "<b>return</b>"</dt>
     <dd>With a plain return, a nonempty return value will be lappended to
       the list of returns from the callback function</dd>

     <dt>return -code error or "<b>error</b>"</dt>
     <dd>errors will simply propagate (and no value returned) unless -catch
       is specified in which case the callback processing will continue but
       no value will be appended to the return list for the implementation
       which returned an error.
     </dd>

     <dt>return -code return</dt>
     <dd>Takes the return value if the implementation returning -code return
       and returns a one element list with that return value.  Note that this means
       if you have code which returns <code>return -code return {x y}</code>,
       you will get {{x y}} as the return value from the callback.  This is
       done in order to unambiguously distinguish a pair of callbacks returning
       x and y respectively from this single callback.
     </dd>

     <dt>return -code break</dt>
     <dd>return the current list of returned values including this implementations
       return value if nonempty</dd>

     <dt>return -code continue</dt>
     <dd>Continue processing, ignore the return value from this implementation</dd>

    </dl>

    @param callback the callback name without leading or trailing ::

    @param impl invoke a specific implementation rather than all implementations
           of the given callback

    @param catch if catch specified errors in the callback will be caught, tracebacks
           logged as errors to the server log, but other callbacks called and the
           list of returns still returned.  If not given an error simply is passed
           further on.

    @param args pass the set of arguments on to each callback

    @return list of the returns from each callback that does a normal (nonempty) return

    @see ad_proc
} {
    if {$callback eq ""} {
        error "callback: no callback name given"
    }
    #
    # Check, if the contract exists and call the contract for
    # arg validation -- ::callback::${callback}::contract is an
    # empty function that only runs the ad_proc generated arg parser.

    if {[namespace which ::callback::${callback}::contract] eq ""} {
        if {[ns_ictl epoch] == 0} {
            #
            # During initial startup, a callback implementation might
            # not be loaded yet. Ignore the callback invocation, but
            # inform the admin in the system log about it.
            #
            ns_log notice "callback invocation $callback during startup ignored. " \
                "The callback implementation might not be loaded yet."
        } else {
            error "Undefined callback $callback"
        }
    }
    ::callback::${callback}::contract {*}$args

    set returns {}

    set base ::callback::${callback}::impl
    foreach procname [lsort [info commands ${base}::$impl]] {
        set c [catch {::uplevel 1 [::list $procname {*}$args]} ret]
        switch -exact $c {
            0 { # code ok
                if { $ret ne "" } {
                    lappend returns $ret
                }
            }
            1 { # code error - either rethrow the current error or log
                if {$catch_p} {
                    set msg "callback $callback error invoking $procname: $ret"
                    if {[aa_test_running_p]} {
                        set severity warning
                    } else {
                        set severity error
                        append msg \n[ad_print_stack_trace]
                    }
                    ns_log $severity $msg
                } else {
                    return -code $c -errorcode $::errorCode -errorinfo $::errorInfo $ret
                }
            }
            2 { # code return -- end processing and return what we got back.
                return [list $ret]
            }
            3 { # code break -- terminate return current list of results.
                if { $ret ne "" } {
                    lappend returns $ret
                }
                return $returns
            }
            4 { # code continue -- just skip this one
            }
            default {
                error "Callback return code unknown: $c"
            }
        }
    }

    if {$impl ne "*" && ![info exists c] && !$catch_p} {
        error "callback $callback implementation $impl does not exist"
    }

    return $returns
}


ad_proc ad_log_deprecated {what oldCmd {newCmd ""}} {

    Provide a standardized interface for reporting deprecated ad_procs
    or other artifacts. In some situations, the flag "-deprecated" in
    the proc is not sufficient. When "newCmd" is not specified, this
    function tries to get the replacement command from the @see
    specification of the documentation.

    @param what type of artifact being used (e.g. "proc" or "class")
    @param oldCmd the name of the deprecated command
    @param newCmd replacement command, when specified

} {
    set msg "*** $what $oldCmd is deprecated."
    if {$newCmd eq "" && $what eq "proc"} {
        #
        # If no replacement command is provided, use whatever is
        # specified in the @see property of the definition.
        #
        # The "oldCmd" should be fully qualified but with no leading
        # colons, like "template::util::date::now_min_interval_plus_hour"
        #
        if {[nsv_get api_proc_doc $oldCmd dict]
            && [dict exists $dict see]
        } {
            set newCmd [dict get $dict see]
        }
    }
    if {$newCmd ne ""} {
        append msg " Use '$newCmd' instead."
    }
    ns_log warning "$msg\n[uplevel ad_get_tcl_call_stack]"
}

ad_proc ad_library {
    doc_string
} {

    Provides documentation for a library (<code>-procs.tcl</code> file).

} {
    ad_parse_documentation_string $doc_string doc_elements
    nsv_set api_library_doc [ad_make_relative_path [info script]] [array get doc_elements]
}

ad_library {

    Routines for defining procedures and libraries of procedures (<code>-procs.tcl</code>
    files).

    @creation-date 7 Jun 2000
    @author Jon Salz (jsalz@mit.edu)
    @cvs-id $Id$
}

ad_proc -deprecated -public empty_string_p {query_string} {
    returns 1 if a string is empty; this is better than using == because it won't fail on long strings of numbers.

    This might have been needed in the old good days, but not anymore.

    @see string equal
} -

ad_proc -public acs_root_dir {} {
    Returns the path root for the OpenACS installation.
} -

ad_proc -public acs_package_root_dir { package_key } {
    Returns the path root for a particular package within the OpenACS installation.
    For example /web/yourserver/packages/foo, i.e., a full filesystem path with no ending slash.
} -

ad_proc -public ad_make_relative_path { path } {
    Returns the relative path corresponding to absolute path $path.
} -

ad_proc -private ad_proc_valid_switch_p {str} {
    Check if the provided argument looks like a switch (i.e. it starts
    with a dash and is not a number).
} -


# procedures for doing type based dispatch
ad_proc -deprecated ad_method {
    method_name
    type
    argblock
    docblock
    body
} {
    Defines a method for type based dispatch. This method can be
    called using <code>ad_call_method</code>. The first arg to the
    method is the target on which the type dispatch happens. Use this
    with care.

    @param method_name the method name
    @param type the type for which this method will be used
    @param argblock the argument description block, is passed to ad_proc
    @param docblock the documentation block, is passed to ad_proc
    @param body the body, is passed to ad_proc

    @see ad_proc
    @see xotcl-core package offers a real ORM interface for acs_object
         types
    @see NSF idioms
    @see OO Tcl idioms
} {
    ad_proc ${method_name}__$type $argblock $docblock $body
}

ad_proc -deprecated ad_call_method {
    method_name
    object_id
    args
} {

    Calls method_name for the type of object_id with object_id as the
    first arg, and the remaining args are the remainder of the args to
    method_name. Example:

    ad_call_method method1 foo bar baz

    calls the method1 associated with the type of foo, with foo bar
    and baz as the 3 arguments.

    @param method_name method name
    @param object_id the target, it is the first arg to the method
    @param args the remaining arguments

    @see expansion operator "{*}"
    @see xotcl-core package offers a real ORM interface for acs_object
         types
    @see NSF idioms
    @see OO Tcl idioms
} {
    return [${method_name}__[util_memoize [list acs_object_type $object_id]] $object_id {*}$args]
}

ad_proc -deprecated ad_dispatch {
    method_name
    type
    args
} {
    Calls method_name with the type as the first arg, and the remaining args are
    the remainder of the args to method_name.

    Example: "ad_dispatch method1 foo bar baz" calls the method1 associated with
             the type foo, with foo bar and baz as the 3 arguments.

    @param method_name method name
    @param type associated type
    @param args the remaining arguments

    @see expansion operator "{*}"
    @see xotcl-core package offers a real ORM interface for acs_object
         types
    @see NSF idioms
    @see OO Tcl idioms
} {
    return [ad_apply ${method_name}__$type $args]
}

ad_proc -public -deprecated ad_assert_arg_value_in_list {
    arg_name
    allowed_values_list
} {
    For use at the beginning of the body of a procedure to
    check that an argument has one of a number of allowed values.

    @param arg_name The name of the argument to check
    @param allowed_values_list The list of values that are permissible for the argument

    Deprecated: this proc can be replaced via very simple expr or if idioms

    @see native if or expr idioms

    @return Returns 1 if the argument has a valid value, throws an informative
                    error otherwise.

    @author Peter Marklund
} {
    upvar $arg_name arg_value

    if {$arg_value ni $allowed_values_list} {
        error "argument $arg_name has value $arg_value but must be in ([join $allowed_values_list ", "])"
    }

    return 1
}

ad_proc -public ad_with_deprecated_code_p {} {
    Check, if we should load deprecated code.

    In order to skip loading of deprecated code, use the following
    snippet in your config file

    # ns_section ns/server/${server}/acs
    #     ns_param WithDeprecatedCode 0

} {
    return [ns_config ns/server/[ns_info server]/acs WithDeprecatedCode 1]
}

ad_proc ad_file {subcmd arg1 args} {

    Tcl supports csh-style tilde substitution. If a filename starts
    with a tilde, then the filename will be interpreted as if the
    first element is replaced with the location of the home directory
    for the given user. If the user does not exist, an exception is
    raised. (e.g. [file dirname ~gustafn.foo]).

    https://www.tcl-lang.org/man/tcl/TclCmd/filename.htm#M20

    This little proc can be used in cases, where (a) the
    tilde-substitution is unwanted, and where the "name" argument
    (usually the first argument after the subcommand) might contain
    user provided values.

} {
    if {[string range $arg1 0 0] eq {~}} {
        set arg1 ./$arg1
    }
    uplevel [list ::file $subcmd $arg1 {*}$args]
}

# if {[cmd_exists xxx]}
if {[info commands ::nsf::cmd::info ] ne ""} {
    interp alias {} cmd_exists {} ::nsf::cmd::info exists
} else {
    ad_proc -private cmd_exists {cmd} {
        expr {[::namespace which $cmd] ne ""}
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
