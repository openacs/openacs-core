##############################################################################
#
#   Copyright 2001, OpenACS, Peter Harper.
#
#   This file is part of acs-automated-testing
#
##############################################################################

ad_library {
    Procs to support the acs-automated-testing package.

    NOTE: There's a hack in packages/acs-bootstrap-installer/bootstrap.tcl to load
    this file on server startup before other packages' -procs files.

    @author Peter Harper (peter.harper@open-msg.com)
    @creation-date 21 June 2001
    @cvs-id $Id$
}

# LARS: We do this here, because if we do it in the -init file, then we cannot register
# test cases in -procs files of packages.
if { ![nsv_exists aa_test cases] } {
    nsv_set aa_test cases {}
    nsv_set aa_test components {}
    nsv_set aa_test init_classes {}
    nsv_set aa_test categories { config db api web smoke stress security_risk populator production_safe }
    nsv_set aa_test exclusion_categories { stress security_risk }
    if {[parameter::get_from_package_key -package_key "acs-automated-testing" -parameter "SeleniumRcServer"] ne ""} {
        nsv_lappend aa_test categories "selenium"
    } else {
        nsv_lappend aa_test exclusion_categories "selenium"
    }
}

proc aa_proc_copy {proc_name_old proc_name_new {new_body ""}} {
    #
    # This is a single proc handling all stub management requirements
    # from aa-testing. Since the arglist nsf::procs is not simply "args"
    # (like for proc based ad_procs), but the real argument/parameter
    # list, we address these differences here for all needed cases.
    #
    if {[info procs $proc_name_old] ne ""} {
        #
        # We copy a regular Tcl proc
        #
        set args {}
        foreach arg [info args $proc_name_old] {
            if { [info default $proc_name_old $arg default_value] } {
                lappend args [list $arg $default_value]
            } else {
                lappend args $arg
            }
        }
        set old_body [info body $proc_name_old]
        if {$new_body eq ""} {
            set new_body $old_body
        }
        set arg_parser "[namespace tail $proc_name_old]__arg_parser"
        #
        # In case an arg-parser was used in the old body, but is
        # missing in the new version, add it automatically to the new
        # body.
        #
        if {[string match "*$arg_parser*" $old_body]} {
            if {![string match "*$arg_parser*" $new_body]} {
                set new_body $arg_parser\n$new_body
                #ns_log notice "... auto added arg_parser for '$proc_name_new' ====> new_body $new_body"
            }
        }
        ::proc $proc_name_new $args $new_body
    } elseif {$::acs::useNsfProc && [info commands $proc_name_old] ne ""} {
        #
        # We copy a nsf::proc
        #
        # Use an absolute name to reference to a nsf::proc
        # unambiguously
        #
        set proc_name [namespace which $proc_name_old]
        if {$new_body eq ""} {
            set new_body [::nsf::cmd::info body $proc_name]
        }
        nsf::proc -ad $proc_name_new \
            [::nsf::cmd::info parameter $proc_name] \
            $new_body
    } else {
        error "no such proc $proc_name_old"
    }
}

ad_proc -public aa_stub {
    proc_name
    new_body
} {
    Stubs a function.  Provide the procedure name and the new body code.
    <p>
    Either call this function from within a testcase for a testcase specific
    stub, or outside a testcase for a file-wide stub.

    @author Peter Harper
    @creation-date 24 July 2001
} {
    global aa_stub_sequence
    global aa_stub_names
    global aa_testcase_id

    if {[info exists aa_testcase_id]} {
        #
        # Runtime testcase stub.
        # If a stub for this procedure hasn't already been defined, take a copy
        # of the original procedure and add it to the aa_stub_names list.
        #
        if {$proc_name ni $aa_stub_names} {
            lappend aa_stub_names $proc_name
            aa_proc_copy $proc_name ${proc_name}_unstubbed
        }
        set aa_stub_sequence($proc_name) 1

        aa_proc_copy $proc_name $proc_name "
      global aa_stub_sequence
      global aa_testcase_id
      set sequence_id \$aa_stub_sequence\($proc_name\)
      incr aa_stub_sequence\($proc_name\)
      $new_body
    "
        return
    } else {
        #
        # File wide stub.
        #
        if {![nsv_exists aa_file_wide_stubs [info script]]} {
            nsv_set aa_file_wide_stubs [info script] {}
        }
        nsv_lappend aa_file_wide_stubs [info script] [list $proc_name $new_body]
    }
}

ad_proc -public aa_unstub {
    proc_name
} {
    @author Peter Harper
    @creation-date 24 July 2001
} {
    aa_proc_copy ${proc_name}_unstubbed $proc_name
    return
}

ad_proc -public aa_register_init_class {
    init_class_id
    init_class_desc
    constructor
    destructor
} {
    Registers a initialization class to be used by one or more testcases.  An
    initialization class can be assigned to a testcase via the
    aa_register_case proc.

    An initialization constructor is called <strong>once</strong> before
    running a set of testcases, and the destructor called <strong>once</strong>
    upon completion of running a set of testcases.<p>
    The idea behind this is that it could be used to perform data intensive
    operations that shared amongst a set if testcases.  For example, mounting
    an instance of a package.  This could be performed by each testcase
    individually, but this would be highly inefficient if there are any
    significant number of them.

    Better to let the acs-automated-testing infrastructure call
    the init_class code to set the package up, run all the tests, then call
    the destructor to unmount the package.

    @author Peter Harper
    @creation-date 04 November 2001

    @param init_class_id Unique string to identify the init class
    @param init_class_desc Longer description of the init class
    @param constructor Tcl code block to run to setup the init class
    @param destructor Tcl code block to tear down the init class
} {
    #
    # Work out the package key
    #
    set package_root [file join $::acs::rootdir packages]
    set package_rel [string replace [info script] \
                         0 [string length $package_root]]
    if {![info exists package_key]} {
        set package_key [lindex [file split $package_rel] 0]
    }
    #
    # First, search the current list of init_classes. If an old version already
    # exists, replace it with the new version.
    #
    set lpos 0
    set found_pos -1
    foreach init_class [nsv_get aa_test init_classes] {
        if {[lindex $init_class 0] == $init_class_id &&
            [lindex $init_class 1] == $package_key} {
            nsv_set aa_test init_classes [lreplace [nsv_get aa_test init_classes] \
                                              $lpos $lpos \
                                              [list $init_class_id $package_key \
                                                   $init_class_desc \
                                                   [info script] \
                                                   $constructor $destructor]]
            set found_pos $lpos
            break
        }
        incr lpos
    }
    #
    # If we haven't already replaced an existing entry, append the new
    # entry to the list.
    #
    if {$found_pos == -1} {
        nsv_lappend aa_test init_classes [list $init_class_id $package_key \
                                              $init_class_desc \
                                              [info script] \
                                              $constructor $destructor]
    }

    #
    # Define the functions.  Note the destructor upvars into the
    # aa_runseries function to gain visibility of all the variables
    # the constructor has exported.
    #
    ad_proc -private _${package_key}__i_$init_class_id {} "
    aa_log \"Running \\\"$init_class_id\\\" initialization class constructor\"
    $constructor
  "
    ad_proc -private _${package_key}__d_$init_class_id {} "
    upvar _aa_exports _aa_exports
    foreach v \$_aa_exports(\[list $package_key $init_class_id\]) {
      upvar \$v \$v
    }
    $destructor
  "
}

ad_proc -public aa_register_component {
    component_id
    component_desc
    body
} {
    Registers a re-usable code component.  Provide a component identifier,
    description and component body code.
    <p>
    This is useful for re-using code that sets up / clears down, data common
    to many testcases.
    @author Peter Harper
    @creation-date 28 October 2001
} {
    #
    # Work out the package key
    #
    set package_root [file join $::acs::rootdir packages]
    set package_rel [string replace [info script] \
                         0 [string length $package_root]]
    set package_key [lindex [file split $package_rel] 0]
    #
    # First, search the current list of components. If an old version already
    # exists, replace it with the new version.
    #
    set lpos 0
    set found_pos -1
    foreach component [nsv_get aa_test components] {
        if {[lindex $component 0] == $component_id &&
            [lindex $component 1] == $package_key} {
            nsv_set aa_test components [lreplace [nsv_get aa_test components] \
                                            $lpos $lpos \
                                            [list $component_id $package_key \
                                                 $component_desc \
                                                 [info script] \
                                                 $body]]
            set found_pos $lpos
            break
        }
        incr lpos
    }
    #
    # If we haven't already replaced an existing entry, append the new
    # entry to the list.
    #
    if {$found_pos == -1} {
        nsv_lappend aa_test components [list $component_id $package_key \
                                            $component_desc \
                                            [info script] \
                                            $body]
    }

    #  set munged_body [subst {uplevel 1 {$body}}]
    ad_proc -private _${package_key}__c_$component_id {} $body
}

ad_proc -public aa_call_component {
    component_id
} {
    Executes the chunk of code associated with the component_id.  <p>
    Call this function from within a testcase body only.
    @author Peter Harper
    @creation-date 28 October 2001
} {
    global aa_package_key
    set body ""

    #
    # Search for the component body
    #
    foreach component [nsv_get aa_test components] {
        if {$component_id    == [lindex $component 0] &&
            $aa_package_key  == [lindex $component 1]} {
            set body [lindex $component 4]
        }
    }

    #
    # If the component exists, execute the body code in the testcases stack
    # level.
    #
    if {$body ne ""} {
        aa_log "Running component $component_id"
        uplevel 1 "_${aa_package_key}__c_$component_id"
        return
    } else {
        error "Unknown component $component_id, package $aa_package_key"
    }
}

ad_proc -public aa_register_case {
    {-libraries {}}
    {-cats {}}
    {-error_level "error"}
    {-bugs {}}
    {-procs {}}
    {-urls {}}
    {-init_classes {}}
    {-on_error {}}
    testcase_id
    testcase_desc
    args
} {
    Registers a testcase with the acs-automated-testing system.
    Whenever possible, cases that fail to register are replaced with
    'metatest' log cases, so that the register-time errors are visible
    at test time.

    See <a href="/doc/tutorial-debug">the tutorial</a> for examples.

    @param libraries A list of keywords of additional code modules to
    load.  The entire test case will fail if any package is missing.
    Currently includes <b>tclwebtest</b>.

    @param cats Properties of the test case.  Must be zero or more of the following:
    <ul>
    <li><b>db</b>: Tests the database directly
    <li><b>api</b>: tests the Tcl API
    <li><b>web</b>: tests HTTP interface
    <li><b>smoke</b>: Minimal test to assure functionality and catch basic errors.
    <li><b>stress</b>: Puts heavy load on server or creates large numbers of records. \
        Intended to simulate maximal production load.
    <li><b>security_risk</b>: May introduce a security risk.
    <li><b>populator</b>: Creates sample data for future use.
    <li><b>production_safe</b>: Can be used on a live production site, \
        i.e. for sanity checking or keepalive purposes. \
        Implies: no risk of adding or deleting data; no risk of crashing; minimal cpu/db/net load.
    </ul>

    @param error_level Force all test failures to this error level. One of
    <ul>
    <li><b>notice</b>: Informative.  Does not indicate an error.
    <li><b>warning</b>: May indicate an problem. \
        Example: a non-critical bug repro case that hasn't been fixed.
    <li><b>error</b>: normal error
    <li><b>metatest</b>: Indicates a problem with the test framework, execution, or reporting. \
        Suggests that current test results may be invalid. \
        Use this for test cases that test the tests. \
        Also used, automatically, for errors sourcing test cases.
    </ul>

    @param bugs A list of integers corresponding to openacs.org bug numbers which relate to this test case.
    @param procs A list of OpenACS procs which are tested by this case.
    @param urls A list of URLs (relative to package) tested in web test case

    @param on_error Deprecated.
    @param init_classes Deprecated.

    @author Peter Harper
    @creation-date 24 July 2001
} {
    # error reporting kludge: if there is any text in this variable
    # we'll not register this test case but indicate in the test case
    # body that there was an error.
    set case_error ""

    set allowed_error_levels { notice warning metatest error }
    if {$error_level ni $allowed_error_levels} {
        set error_level metatest
        append case_error "error_level must be one of following: $allowed_error_levels.\n\n"
    }

    set allowed_categories [nsv_get aa_test categories]
    foreach cat $cats {
        if {$cat ni $allowed_categories} {
            set error_level metatest
            append case_error "cats must contain only the following: $allowed_categories. You had a '$cat' in there.\n\n"
        }
    }

    #
    # Work out the package_key.
    #
    set package_root [file join $::acs::rootdir packages]
    set package_rel [string replace [info script] 0 [string length $package_root]]
    set package_key [lindex [file split $package_rel] 0]

    # run library specific code
    foreach library $libraries {
        if { $library eq "tclwebtest" } {

            # kludge: until tclwebtest installs itself in the proper
            # place following the Tcl way, we use this absolute path
            # hack.
            set tclwebtest_absolute_path "/usr/local/tclwebtest/lib"
            if { ![info exists ::auto_path] || $tclwebtest_absolute_path ni $::auto_path } {
                lappend ::auto_path $tclwebtest_absolute_path
            }
            if { [catch {
                package require tclwebtest
                package require http
            } err] } {
                set error_level metatest
                append case_error "tclwebtest is not available. Not registering this test case.\n\nError message: $err\n\n"
            }
        }
    }

    #
    # Print warnings for any unknown init_classes.  We actually mask out
    # any unknown init_classes here, so we don't get any script errors later.
    #
    set filtered_inits {}
    foreach init_class $init_classes {
        if {[llength $init_class] == 2} {
            set init_class [lindex $init_class 0]
        }
        if {[string trim $init_class] ne ""} {
            set found 0
            foreach init_class_info [nsv_get aa_test init_classes] {
                if {$init_class == [lindex $init_class_info 0]} {
                    set found 1
                }
            }
            if {!$found} {
                ns_log warning " aa_register_case: Unknown init class $init_class"
            } else {
                lappend filtered_inits $init_class
            }
        }
    }
    set init_classes $filtered_inits


    set test_case_list [list $testcase_id $testcase_desc \
                            [info script] $package_key \
                            $cats $init_classes $on_error $args $error_level \
                            $bugs $procs $urls]
    foreach p $procs {
        api_add_to_proc_doc -proc_name $p -property testcase -value [list $testcase_id $package_key]
        #ns_log notice "TESTCASE: api_add_to_proc_doc -proc_name $p -property testcase -value $testcase_id -> [dict get [nsv_get api_proc_doc $p] testcase]"
    }
    #
    # First, search the current list of test cases. If an old version already
    # exists, replace it with the new version.
    #
    set lpos 0
    set found_pos -1
    foreach case [nsv_get aa_test cases] {
        if {[lindex $case 0] == $testcase_id
            && [lindex $case 3] == $package_key
        } {
            nsv_set aa_test cases [lreplace [nsv_get aa_test cases] $lpos $lpos \
                                       $test_case_list]
            set found_pos $lpos
            break
        }
        incr lpos
    }
    #
    # If we haven't already replaced an existing entry, append the new
    # entry to the list.
    #
    if {$found_pos == -1} {
        nsv_lappend aa_test cases $test_case_list
    }

    if { $case_error ne "" } {

        # we don't source this file but insert a little warning text
        # into the procs body. There seems to be no better way to
        # indicate that this test should be skipped.

        ad_proc -private _${package_key}__$testcase_id {} "
          # make sure errorlevel gets through. this is not 100% cleaned up.
          global error_level
          set error_level $error_level
          aa_log_result $error_level \{${case_error}\}"
        return
    }

    if {[llength $init_classes] == 0} {
        set init_class_code ""
    } else {
        set init_class_code [string map [
        list @init_classes@ [list $init_classes] @package_key@ [list $package_key]] {
            global aa_init_class_logs
            upvar 2 _aa_exports _aa_exports
            foreach init_class @init_classes@ {
                if {[llength $init_class] == 2} {
                    lassign $init_class init_class init_package_key
                } else {
                    set init_package_key @package_key@
                }
                foreach v $_aa_exports([list $init_package_key $init_class]) {
                    upvar 2 $v $v
                }
                foreach logpair $aa_init_class_logs([list $init_package_key $init_class]) {
                    aa_log_result [lindex $logpair 0] [lindex $logpair 1]
                }
            }
        }]
    }

    set body [string map [list @init_class_code@ $init_class_code @args@ [list $args]] {
        @init_class_code@
        set _aa_export {}
        set body_count 1
        foreach testcase_body @args@ {
          aa_log "Running testcase body $body_count"
          set ::__aa_test_indent [info level]
          set catch_val [catch $testcase_body msg]
          if {$catch_val != 0 && $catch_val != 2} {
              aa_log_result "fail" "$testcase_id (body $body_count): Error during execution: $msg, stack trace: \n$::errorInfo"
          }
          incr body_count
        }
    }]

    ad_proc -private _${package_key}__$testcase_id {} $body
    ns_log Debug "aa_register_case: Registered test case $testcase_id in package $package_key"

}

ad_proc -public aa_export_vars {
    args
} {
    Called from a initialization class constructor or a component to
    explicitly export the specified variables to the current testcase. You need
    to call aa_export_vars <b>before</b> you create the variables.

    Example:
    <pre>
    aa_export_vars {package_id item_id}
    set package_id 23
    set item_id 109
    </pre>
} {
    uplevel 1 [string map [list @args@ [list $args]] {
        foreach v @args@ {
          upvar $v $v
          uplevel 1 [list lappend _aa_export $v]
        }
    }
}

ad_proc -public aa_runseries {
    {-stress 0}
    {-security_risk 0}
    -quiet:boolean
    {-testcase_id ""}
    {by_package_keys ""}
    {by_category ""}
} {
    Runs a series of testcases.

    Runs all cases if both by_package_keys and by_category are blank,
    otherwise it uses the package and/or category to select which
    testcases to run.

    @author Peter Harper
    @creation-date 24 July 2001
} {
    global aa_run_quietly_p
    global aa_init_class_logs
    global aa_in_init_class

    set aa_run_quietly_p $quiet_p
    #
    # Work out the list of initialization classes.
    #
    set testcase_ids {}
    if {$testcase_id ne ""} {
        lappend testcase_ids $testcase_id
        foreach testcase [nsv_get aa_test cases] {
            if {$testcase_id == [lindex $testcase 0]} {
                set package_key     [lindex $testcase 3]
                set init_classes    [lindex $testcase 5]
                foreach init_class $init_classes {
                    set classes([list $package_key $init_class]) 1
                }
            }
        }
    } else {
        foreach testcase [nsv_get aa_test cases] {
            set testcase_id     [lindex $testcase 0]
            set package_key     [lindex $testcase 3]
            set categories      [lindex $testcase 4]
            set init_classes    [lindex $testcase 5]

            # try to disqualify the test case

            # check if package key belongs to the ones we are testing
            if { $by_package_keys ne "" && $package_key ni $by_package_keys } {
                continue
            }

            # is it the wrong category?
            if { $by_category ne "" && $by_category ni $categories } {
                continue
            }

            # if we don't want stress, then the test must not be stress
            if { ! $stress && "stress" in $categories } {
                continue
            }

            # if we don't want security risks, then the test must not be stress
            if { ! $security_risk && "security_risk" in $categories } {
                continue
            }

            # we made it through the filters, so add the test case
            lappend testcase_ids $testcase_id
            foreach init_class $init_classes {
                set classes([list $package_key $init_class]) 1
            }
        }
    }
    #
    # Run each initialization script.  Keep a list of the exported variables
    # by each initialization script so each testcase (and destructor) can
    # correctly upvar to gain visibility of them.
    #
    if {[info exists classes]} {
        foreach initpair [array names classes] {
            lassign $initpair package_key init_class
            set _aa_export {}
            set aa_init_class_logs([list $package_key $init_class]) {}
            set aa_in_init_class [list $package_key $init_class]
            _${package_key}__i_$init_class
            set _aa_exports([list $package_key $init_class]) $_aa_export
        }
    }
    set aa_in_init_class ""

    #
    # Run each testcase
    #
    foreach testcase_id $testcase_ids {
        aa_run_testcase $testcase_id
    }

    #
    # Run each initialization destructor script.
    #
    if {[info exists classes]} {
        foreach initpair [array names classes] {
            lassign $initpair package_key init_class
            set aa_in_init_class [list $package_key $init_class]
            _${package_key}__d_$init_class
        }
    }
    set aa_in_init_class ""

    # Generate the XML report file
    aa_test::write_test_file
}

ad_proc -private aa_indent {} {
    try to make it easier to read nested test cases.
} {
    if {[info exists ::__aa_test_indent]} {
        return "<tt>[string repeat {<div class='vl'></div>} [expr {[info level] - $::__aa_test_indent -2}]]</tt>"
    }
}

ad_proc -public aa_run_testcase {
    testcase_id
} {
    @author Peter Harper
    @creation-date 24 July 2001
} {
    global aa_stub_names
    global aa_testcase_id
    global aa_testcase_test_id
    global aa_testcase_fails
    global aa_testcase_passes
    global aa_package_key
    global aa_init_class_logs
    global aa_error_level
    upvar  exports exports

    set aa_stub_names {}
    set aa_testcase_id $testcase_id
    set aa_testcase_test_id 0
    set aa_testcase_fails 0
    set aa_testcase_passes 0

    #
    # Lookup the testcase definition.
    #
    set testcase_bodys {}
    foreach testcase [nsv_get aa_test cases] {
        if {$testcase_id == [lindex $testcase 0]} {
            set testcase_file       [lindex $testcase 2]
            set package_key         [lindex $testcase 3]
            set testcase_cats       [lindex $testcase 4]
            set testcase_inits      [lindex $testcase 5]
            set testcase_on_error   [lindex $testcase 6]
            set testcase_bodys      [lindex $testcase 7]
            set aa_error_level      [lindex $testcase 8]

            set aa_package_key    $package_key
        }
    }
    if {[llength $testcase_bodys] == 0} {
        return
    }


    #
    # Create any file-wide stubs.
    #
    if {[nsv_exists aa_file_wide_stubs "$testcase_file"]} {
        foreach stub_def [nsv_get aa_file_wide_stubs "$testcase_file"] {
            aa_stub [lindex $stub_def 0] [lindex $stub_def 1]
        }
    }

    #
    # Run the test
    #
    set sql "delete from aa_test_results
           where testcase_id = :testcase_id"
    db_dml delete_testcase_results $sql
    set sql "delete from aa_test_final_results
           where testcase_id = :testcase_id"
    db_dml delete_testcase_final_results $sql

    ns_log debug "aa_run_testcase: Running testcase $testcase_id"

    set catch_val [catch _${package_key}__$testcase_id msg]
    if {$catch_val} {
        aa_log_result "fail" "$testcase_id: Error calling testcase function _${package_key}__$testcase_id: $msg"
    }

    #
    # Unstub any stubbed functions
    #
    foreach stub_name $aa_stub_names {
        aa_unstub $stub_name
    }
    set aa_stub_names {}

    aa_log_final $aa_testcase_passes $aa_testcase_fails
    unset aa_testcase_id
}


ad_proc -public aa_equals {
    affirm_name
    affirm_actual
    affirm_value
} {
    Tests that the affirm_actual is equal to affirm_value.<p>
    Call this function within a testcase, stub or component.

    @return True if the affirmation passed, false otherwise.

    @author Peter Harper
    @creation-date 24 July 2001
} {
    global aa_testcase_id
    global aa_package_key

    if {$affirm_actual eq $affirm_value} {
        aa_log_result "pass" [subst {[aa_indent] $affirm_name, actual = "$affirm_actual"}]
        return 1
    } else {
        aa_log_result "fail" [subst {[aa_indent] $affirm_name, actual = "$affirm_actual", expected = "$affirm_value"}]
        return 0
    }
}

ad_proc -public aa_true {
    affirm_name
    affirm_expr
} {
    Tests that affirm_expr is true.<p>
    Call this function within a testcase, stub or component.

    @return True if the affirmation passed, false otherwise.

    @author Peter Harper
    @creation-date 24 July 2001
} {
    set result [uplevel 1 [list expr $affirm_expr]]
    if {$affirm_expr in {0 1 t f true false}} {
        set expr ""
    } else {
        set expr [subst {"$affirm_expr" }]
    }
    if { $result } {
        aa_log_result "pass" "[aa_indent] $affirm_name: $expr true"
        return 1
    } else {
        aa_log_result "fail" "[aa_indent] $affirm_name: $expr false"
        return 0
    }
}

ad_proc -public aa_false {
    affirm_name
    affirm_expr
} {
    Tests that affirm_expr is false.
    Call this function within a testcase, stub or component.

    @return True if the affirmation passed, false otherwise.

    @author Peter Harper
    @creation-date 24 July 2001
} {
    global aa_testcase_id
    global aa_package_key

    set result [uplevel 1 [list expr $affirm_expr]]
    if {!$result} {
        aa_log_result "pass" [subst {[aa_indent] $affirm_name: "$affirm_expr" false}]
        return 1
    } else {
        aa_log_result "fail" [subst {[aa_indent] $affirm_name: "$affirm_expr" true}]
        return 0
    }
}

ad_proc -public aa_section {
        log_notes
} {
    Writes a log message indicating a new section to the log file.
} {
    aa_log_result "sect" $log_notes
}

ad_proc -public aa_log {
    log_notes
} {
    Writes a log message to the testcase log.
    Call this function within a testcase, stub or component.

    @author Peter Harper
    @creation-date 24 July 2001
} {
    #global aa_testcase_id
    #global aa_package_key

    #
    # When aa_run_quietly_p exists, we run inside the testing
    # environment.
    #
    if {[info exists ::aa_run_quietly_p]} {
        if {$::aa_run_quietly_p} {
            return
        }
        aa_log_result "log" "[aa_indent] $log_notes"
    } else {
        #
        # Use plain ns_log reporting
        #
        ns_log notice "aa_log: $log_notes"
    }
}

ad_proc -public aa_error {
    error_notes
} {
    Writes an error message to the testcase log.<p>
    Call this function within a testcase, stub or component.
    @author Peter Harper
    @creation-date 04 November 2001
} {
    aa_log_result "fail" $error_notes
}

ad_proc -public aa_log_result {
    test_result
    test_notes
} {
    @author Peter Harper
    @creation-date 24 July 2001
} {
    if { [aa_in_rollback_block_p] } {
        aa_add_rollback_test [list aa_log_result $test_result $test_notes]
        return
    }

    global aa_testcase_id
    global aa_testcase_test_id
    global aa_testcase_fails
    global aa_testcase_passes
    global aa_package_key
    global aa_in_init_class
    global aa_init_class_logs
    global aa_error_level

    #
    # If logging is happened whilst in a initialization class, store the log
    # entry, but don't write it to the database.  Individual testcase will make
    # their own copies of these log entries.
    #
    if {$aa_in_init_class ne ""} {
        lappend aa_init_class_logs($aa_in_init_class) \
            [list $test_result $test_notes]
        return
    }

    incr aa_testcase_test_id
    if {$test_result eq "pass"} {
        ns_log Debug "aa_log_result: PASSED: $aa_testcase_id, $test_notes"
        incr aa_testcase_passes
    } elseif {$test_result eq "fail"} {
        switch $aa_error_level {
            notice {
                ns_log notice "aa_log_result: NOTICE: $aa_testcase_id, $test_notes"
                set test_result "note"
            }
            warning {
                ns_log warning "aa_log_result: WARNING: $aa_testcase_id, $test_notes"
                set test_result "warn"
            }
            error {
                incr aa_testcase_fails
                ns_log Bug "aa_log_result: FAILED: $aa_testcase_id, $test_notes"
            }
            default {
                # metatest
                incr aa_testcase_fails
                ns_log Bug "aa_log_result: FAILED: Automated test did not function as expected: $aa_testcase_id, $test_notes"
            }
        }
    } elseif {$test_result ne "sect"} {
        ns_log Debug "aa_log_result: LOG: $aa_testcase_id, $test_notes"
        set test_result "log"
    }
    # Notes in database can only hold so many characters
    if { [string length $test_notes] > 2000 } {
        set test_notes "[string range $test_notes 0 1996]..."
    }

    db_dml test_result_insert {}
}

ad_proc -public aa_log_final {
    test_passes
    test_fails
} {
    @author Peter Harper
    @creation-date 24 July 2001
} {
    global aa_testcase_id
    global aa_testcase_fails
    global aa_testcase_passes
    global aa_package_key

    if {$test_fails == 0} {
    } else {
        ns_log Bug "aa_log_final: FAILED: $aa_testcase_id, $test_fails tests failed"
    }

    db_dml testcase_result_insert {}
}

ad_proc -public aa_run_with_teardown {
    {-test_code:required}
    {-teardown_code ""}
    -rollback:boolean
} {
    Execute code in test_code and guarantee that code in
    teardown_code will be executed even if error is thrown. Will catch
    errors in teardown_code as well and provide stack traces for both code blocks.

    @param test_code     Tcl code that sets up the test case and executes tests

    @param teardown_code Tcl code that tears down database data etc. that needs to execute
    after testing even if error is thrown.

    @param rollback      If specified, any db transactions in test_code will be rolled back.

    @author Peter Marklund
} {
    if { $rollback_p } {
        set test_code [string map [list @test_code@ $test_code] {
            set errmsg {}
            db_transaction {
               aa_start_rollback_block

               @test_code@

                aa_end_rollback_block
                error "rollback tests"
            } on_error {
                aa_end_rollback_block
            }

            aa_execute_rollback_tests

            if { $errmsg ne {} && $errmsg ne "rollback tests" } {
                error "$errmsg \n\n $::errorInfo"
            }
        }]
    }

    # Testing
    set setup_error_p [catch {uplevel $test_code} setup_error]
    set setup_error_stack $::errorInfo

    # Teardown
    set teardown_error_p 0
    if { $teardown_code ne "" } {
        set teardown_error_p [catch {uplevel $teardown_code} teardown_error]
        set teardown_error_stack $::errorInfo
    }

    # Provide complete error message and stack trace
    set error_text ""
    if { $setup_error_p } {
        append error_text "Setup failed with error $setup_error\n\n$setup_error_stack"
    }
    if { $teardown_error_p } {
        append error_text "\n\nTeardown failed with error $teardown_error\n\n$teardown_error_stack"
    }
    if { $error_text ne "" } {
        error $error_text
    }
}

ad_proc -private aa_start_rollback_block {} {
    Start a block of code that is to be rolled back in the db

    @author Peter Marklund
} {
    global aa_in_rollback_block_p
    set aa_in_rollback_block_p 1
}

ad_proc -private aa_end_rollback_block {} {
    End a block of code that is to be rolled back in the db

    @author Peter Marklund
} {
    global aa_in_rollback_block_p
    set aa_in_rollback_block_p 0
}

ad_proc -private aa_in_rollback_block_p {} {
    Return 1 if we are in a block of code that is to be rolled back in the db
    and 0 otherwise.

    @author Peter Marklund
} {
    global aa_in_rollback_block_p
    if { [info exists aa_in_rollback_block_p] } {
        return $aa_in_rollback_block_p
    } else {
        return 0
    }
}

ad_proc -private aa_add_rollback_test {args} {
    Add a test statement that is to be executed after a rollback block.
    If it were to be executed during the rollback block it would be
    rolled back and this is what we want to avoid.

    @author Peter Marklund
} {
    global aa_rollback_test_statements

    lappend aa_rollback_test_statements $args
}

ad_proc -private aa_execute_rollback_tests {} {
    Execute all test statements from a rollback block.

    @author Peter Marklund
} {
    global aa_rollback_test_statements

    if { [info exists aa_rollback_test_statements] } {
        foreach test_statement $aa_rollback_test_statements {
            eval [join $test_statement " "]
        }
    }

    if { [info exists aa_rollback_test_statements] } {
        unset aa_rollback_test_statements
    }
}




namespace eval acs::test {

    ad_proc -public ::acs::test::require_package_instance {
        -package_key:required
        {-instance_name ""}
        {-empty:boolean}
    } {
        Returns a test instance of specified package_key mounted under
        specified name. Will create it if it is not found. It is
        currently assumed the instance will be mounted under the main
        subsite.

        @param package_key package to be instantiated
        @param instance name name of the site-node this instance will
               be mounted to. Will default to <package_key>-test
        @param empty require an empty instance. If an existing
               instance is found, it will be deleted. If a package
               different than <package_key> is found, it won't be
               deleted and the proc will return an error

        @return a package_id
    } {
        set main_node_id [site_node::get_element \
                              -url / -element node_id]

        set instance_name [expr {$instance_name eq "" ?
                                 "${package_key}-test" : [string trim $instance_name /]}]

        set package_exists_p [db_0or1row lookup_test_package {
            select node_id, object_id as package_id
            from site_nodes
            where parent_id = :main_node_id
            and name = :instance_name
        }]

        if {$package_exists_p} {
            set existing_package_key [apm_package_key_from_id $package_id]
            if {$existing_package_key ne $package_key} {
                error "An instance of '$existing_package_key' is already mounted at '$instance_name'"
            } elseif {$empty_p} {
                site_node::delete -node_id $node_id -delete_package
            }
        }

        if {!$package_exists_p || $empty_p} {
            set package_id [site_node::instantiate_and_mount \
                                -package_name $instance_name \
                                -node_name $instance_name \
                                -package_key $package_key]
        }

        return $package_id
    }

    ad_proc -public ::acs::test::form_reply {
        {-user_id 0}
        {-last_request ""}
        {-form ""}
        {-url ""}
        {-update {}}
        {-remove {}}
        {form_content ""}
    } {

        Send a (POST) request to the specified URL based on the
        provided form_content which has the form of a dict.  For
        convenience the update fields are provided to overload the
        form_content.

        @param last_request pass optionally the past request, from which cookie and login-info can be taken
        @param update key/attribute list of values to be updated in the form content
        @param remove keys to be removed from the form content

    } {
        if {$form_content eq ""} {
            set form_content [form_get_fields $form]
        }
        if {$form_content eq ""} {
            error "either non-empty form or form_content has to be provided"
        }
        if {$url eq ""} {
            set url [dict get $form @action]
        }
        if {$url eq ""} {
            error "either form with action fields or url has to be provided"
        }

        if {$remove ne ""} {
            set form_content [dict remove $form_content {*}$remove]
            ns_log notice "DEBUG: after removing <$remove> from <$form_content>"
        }
        foreach {att value} $update {
            dict set form_content $att $value
        }
        #ns_log notice "final form_content $form_content"
        #
        # Transform the dict into export format. Since export_vars
        # will skip all names containing a ":", such as
        # "formbutton:ok", we do this "manually".
        #
        set export {}
        foreach {att value} $form_content {
            lappend export [ad_urlencode_query $att]=[ad_urlencode_query $value]
        }
        set body [join $export &]
        ns_log notice "body=$body"
        #
        # Send the POST request
        #
        return [http \
                    -user_id $user_id -last_request $last_request \
                    -method POST -body $body \
                    -headers {Content-Type application/x-www-form-urlencoded} \
                    $url]
    }

    ad_proc -public ::acs::test::http {
        {-user_id 0}
        {-user_info ""}
        {-last_request ""}
        {-method GET}
        {-body}
        {-timeout 10}
        {-depth 1}
        {-headers ""}
        {-prefix ""}
        {-verbose:boolean 1}
        request
    } {

        Run an HTTP request against the actual server inside test
        cases.

        @param depth follow redirects up to specified depth. Default
        means redirects won't be followed.

        @author Gustaf Neumann
    } {
        ns_log notice "::acs::test::http -user_id $user_id -user_info $user_info request $request"
        set session ""
        if {[dict exists $last_request session]} {
            set session [dict get $last_request session]
        }
        if {$user_info eq "" && [dict exists $session user_info]} {
            set user_info [dict get $last_request session user_info]
            #aa_log "user_info from last_request [ns_quotehtml <$user_info>]"
        }
        #aa_log "HTTP: user_info [ns_quotehtml <$user_info>]"
        #aa_log "HTTP: start session_info [ns_quotehtml <$session>]"

        #
        # Check, if a testURL was specified in the config file
        #
        # ns_section ns/server/${server}/acs/acs-automated-testing
        #         ns_param TestURL http://127.0.0.1:8080/
        #
        set url [parameter::get \
                     -package_id [apm_package_id_from_key acs-automated-testing] \
                     -parameter TestURL \
                     -default ""]
        if {$url ne ""} {
            set urlInfo [ns_parseurl $url]
            set proto   [dict get $urlInfo proto]
            set address [dict get $urlInfo host]
        } else {
            #
            # There is no configuration in the config file. So try to
            # determine it form either the current connection, or from
            # the configured driver.
            #
            try {
                #
                # First try to get actual information from the
                # connection. This is however only available in newer
                # versions of NaviServer. The actual information is
                # e.g. necessary, when the driver address is set to
                # "0.0.0.0" or "::0" etc, and therefore every address
                # might be provided as peer address in the check in
                # the security-procs.
                #
                set address [ns_conn currentaddr]
                set port    [ns_conn currentport]
                set proto   [ns_conn proto]
            } on error {errorMsg} {
                #
                # If this fails, fall back to configured value.
                #
                set driverInfo [util_driver_info]
                set address [dict get $driverInfo address]
                set port    [dict get $driverInfo port]
                set proto   [dict get $driverInfo proto]
            }
            set url "$proto://\[$address\]:$port/$request"
        }

        #
        # Either authenticate via user_info (when specified) or via
        # user_id.
        #
        if {$user_info ne ""} {
        } else {
            dict set user_info user_id $user_id
            dict set user_info address $address
        }

        set session [::acs::test::set_user -session $session $user_info]
        set login [dict get $session login]

        if {[dict exists $session cookies]} {
            lappend headers Cookie [dict get $session cookies]
        }

        set extra_args {}
        if {[info exists body]} {
            lappend extra_args -body $body
        }

        if {[llength $headers] > 0} {
            set requestHeaders [ns_set create]
            foreach {tag value} $headers {
                ns_set update $requestHeaders $tag $value
            }
            lappend extra_args -headers $requestHeaders
        }


        #
        # Construct a nice log line
        #
        append log_line "${prefix}Run $method $request"
        if {[llength $headers] > 0} {
            append log_line " (headers: $headers)"
        }
        if {[info exists body]} {
            append log_line "<pre>\n[ns_quotehtml $body]</pre>"
        }
        aa_log $log_line

        #
        # Run actual request
        #
        try {
            set location $url
            while {$depth > 0} {
                ns_log notice "acs::test:http client request (timeout $timeout): $method $location"
                incr depth -1
                set d [ns_http run \
                           -timeout $timeout \
                           -method $method \
                           {*}$extra_args \
                           $location]
                set status   [dict get $d status]
                set location [ns_set iget [dict get $d headers] location]
                if {![string match "3??" $status] || $location eq ""} {
                    break
                }
            }
        } finally {
            #
            # always reset after the request the login data nsv
            #
            nsv_unset -nocomplain aa_test logindata
        }

        #ns_log notice "run $request returns $d"
        #ns_log notice "... [ns_set array [dict get $d headers]]"

        if {$verbose_p} {
            set ms [format %.2f [expr {[ns_time format [dict get $d time]] * 1000.0}]]
            aa_log "${prefix}$method $request returns [dict get $d status] in ${ms}ms"
        }
        #aa_log "REPLY has headers [dict exists $d headers]"
        if {[dict exists $d headers]} {
            set cookies {}
            set cookie_dict {}
            if {[dict exists $last_request cookies]} {
                #
                # Merge last request cookies
                #
                foreach cookie [split [dict get $last_request cookies] ";"] {
                    lassign [split [string trim $cookie] =] name value
                    dict set cookie_dict $name $value
                    #aa_log "merge last request cookie $name $value"
                }
            } else {
                #aa_log "last_req has no cookies"
            }
            if {[dict exists $session cookies]} {
                #
                # Merge session cookies (e.g. from a called login
                # inside :acs::test::set_user)
                #
                foreach cookie [split [dict get $session cookies] ";"] {
                    lassign [split [string trim $cookie] =] name value
                    dict set cookie_dict $name $value
                    #aa_log "merge session cookie $name $value"
                }
            }
            #
            # Merge fresh cookies
            #
            foreach {tag value} [ns_set array [dict get $d headers]] {
                #aa_log "received header $tag: $value"
                if {$tag eq "set-cookie"} {
                    if {[regexp {^([^;]+);} $value . cookie]} {
                        lassign [split [string trim $cookie] =] name value
                        dict set cookie_dict $name $value
                        aa_log "merge fresh cookie $name $value"
                    } else {
                        aa_log "Cookie has invalid syntax: $value"
                    }
                }
            }
            foreach cookie_name [dict keys $cookie_dict] {
                lappend cookies $cookie_name=[dict get $cookie_dict $cookie_name]
            }
            dict set d session cookies [join $cookies ";"]
        }
        dict set d login $login
        dict set d session user_info $user_info
        #aa_log "HTTP: url $url final session_info [ns_quotehtml <[dict get $d session]>]"

        return $d
    }

    ad_proc -public ::acs::test::set_user {
        {-session ""}
        user_info
    } {

        When (login) cookies are given as member of "session", use
        these. In case the login cookie is empty (after an explicit
        logout) do NOT automatically log in.

        When (login) cookies are not given, use "user_info" for
        authentication. When we have a "user_id" and "address" in the
        "user_info", use these for direct logins. Otherwise the person
        info (name, email, ...) to log via register.

        @param session when given, use login information from there
        @param user_info dict containing user_id+session and/or
               email, last_name, username and password
    } {
        #aa_log "set_user has user_info $user_info, have cookies: [dict exists $session cookies]"

        set already_logged_in 0
        #
        # First check, if the user is already logged in via cookies
        #
        if {[dict exists $session cookies]} {
            #aa_log "session has cookies '[dict get $session cookies]'"
            foreach cookie [split [dict get $session cookies] ";"] {
                lassign [split [string trim $cookie] =] name value
                #aa_log "session has cookie $cookie // NAME '$name' VALUE '$value'"
                if {$name in {ad_user_login ad_user_login_secure} && $value ne "\"\""} {
                    aa_log "user is already logged in via cookie $name"
                    set already_logged_in 1
                    dict set session login via_cookie
                    break
                }
            }
        }
        if {!$already_logged_in} {
            #
            # The user is not logged in via cookies, check first
            # available user_id. If this dies not exist, perform login
            #
            #aa_log "not logged in, check $user_info"

            if {[dict exists $user_info user_id]
                && [dict exists $user_info address]
            } {
                set user_id [dict get $user_info user_id]
                if {$user_id ne 0} {
                    #aa_log "::acs::test::set_user set logindata via nsv"
                    nsv_set aa_test logindata \
                        [list \
                             peeraddr [dict get $user_info address] \
                             user_id [dict get $user_info user_id]]
                    dict set session login via_logindata
                } else {
                    dict set session login none
                }
            } elseif {[dict exists $session cookies]} {
                #
                # We have cookies, but are not logged in. Do NOT automatically log in.
                #
                dict set session login none
            } else {
                #
                # No cookies, log automatically in.
                #
                #aa_log "::acs::test::set_user perform login with $user_info"
                set d [::acs::test::login $user_info]
                #aa_log "::acs::test::set_user perform login returned session [dict get $d session]"
                dict set session cookies [dict get $d session cookies]
                dict set session login via_login
            }
        }
        return $session
    }


    ad_proc -public ::acs::test::login {
        user_info
    } {
        Login (register operation) in a web session

        @param user_info dict containing at least
               email, last_name, username and password
    } {
        #aa_log "acs::test::login with user_info $user_info"
        set d [acs::test::http -user_id 0 /register/]
        acs::test::reply_has_status_code $d 200

        set form [acs::test::get_form [dict get $d body ] {//form[@id='login']}]
        set fields [acs::test::form_get_fields $form]
        if {[dict exists $fields email]} {
            aa_log "login via email [dict get $user_info email]"
            dict set fields email [dict get $user_info email]
        } else {
            aa_log "login via username [dict get $user_info username]"
            dict set fields username [dict get $user_info username]
        }
        dict set fields password [dict get $user_info password]
        set form [acs::test::form_set_fields $form $fields]

        set d [::acs::test::form_reply -user_id 0 -form $form]
        acs::test::reply_has_status_code $d 302

        return $d
    }

    ad_proc -public ::acs::test::logout {
        -last_request:required
    } {
        Logout from the current web session

        @param session reply dict containing cookies
    } {
        set d [acs::test::http -last_request $last_request /register/logout]
        acs::test::reply_has_status_code $d 302
        return $d
    }

    ad_proc -public ::acs::test::confirm_email {
        -user_id:required
    } {
        Confirms user email
    } {
        # Call the confirmation URL and check response
        set token [auth::get_user_secret_token -user_id $user_id]
        set to_addr [party::get -party_id $user_id -element email]
        set confirmation_url [export_vars -base "/register/email-confirm" { token user_id }]
        set d [acs::test::http $confirmation_url]
        acs::test::reply_has_status_code $d 200
    }

    ad_proc -public ::acs::test::visualize_control_chars {lines} {
        Quotes and therefore makes visible control chars in input lines
    } {
        set output $lines
        regsub -all {\\} $output {\\\\} output
        regsub -all {\r} $output {\\r} output
        regsub -all {\n} $output "\\n\n" output
        return $output
    }

    ad_proc -public ::acs::test::dom_html {var html body} {
    } {
        upvar $var root
        dom parse -html $html doc
        $doc documentElement root
        uplevel $body
    }

    ad_proc -public get_form {body xpath} {

        Locate the HTML forms matching the XPath expression and
        retrieve its HTML attributes and the formfields in form of a
        Tcl dict. This is a convenience function, combining
        acs::test::dom_html and ::acs::test::xpath::get_form.

        @return Tcl dict with form attributes (starting with "@" and fields)
        @see acs::test::dom_html ::acs::test::xpath::get_form

        @author Gustaf Neumann
    } {
        acs::test::dom_html root $body {
            set form_data [::acs::test::xpath::get_form $root $xpath]
        }
        return $form_data
    }

    ad_proc -public form_get_fields {form} {

        Get the fields from a form.

        @form form dict
        @see acs::test::get_form

        @author Gustaf Neumann
    } {
        return [dict get $form fields]
    }

    ad_proc -public form_set_fields {form fields} {

        Set the fields in a form.

        @form form dict
        @fields fields in form of attribute/value pairs

        @see acs::test::get_form

        @author Gustaf Neumann
    } {
        dict set form fields $fields
        return $form
    }

    ad_proc -public form_is_empty {form} {

        Check, if the form is empty

        @form form dict

        @see acs::test::get_form

        @author Gustaf Neumann
    } {
        return [expr {[llength $form] == 0}]
    }


    ad_proc -public follow_link {
        -last_request:required
        {-user_id 0}
        {-base /}
        {-label ""}
    } {

        Follow the first provided label and return the page info.
        Probably, we want as well other mechanisms to locate the
        anchor element later.

        @author Gustaf Neumann
    } {
        set href ""
        set html [dict get $last_request body]
        acs::test::dom_html root $html {
            foreach a [$root selectNodes //a] {
                set link_label [string trim [$a text]]
                if {$label eq $link_label} {
                    set href [$a getAttribute href]
                    break
                }
                #
                # There is something weird in tDOM: without the
                # "string trim" we see something like
                #
                #       a TEXT 'DD25C9878' = 'DD25C9878' eq 0 77 9
                #
                # from the statements below.
                # set eq [expr {$label eq $link_label}]
                # aa_log "a TEXT '$link_label' = '$label' eq $eq [string length $link_label] [string length $label]"
                # aa_log "a TEXT '[$a asHTML]'"
            }
        }
        aa_true "href '$href' of link with label '$label' is not empty (<a href='[detail_link $last_request]'>Details</a>)" \
            {$href ne ""}
        if {![string match "/*" $href]} {
            set href $base/$href
        }
        return [http -last_request $last_request -user_id $user_id $href]
    }


    ad_proc -private detail_link {dict} {

        Create a detail link, which is useful for web-requests, to
        inspect the result in case a test fails.

        Missing: cleanup, e.g. after a couple of days, or when the
        testcase is executed again (for that we would need testcase_id
        and package_key, that we do not want to pass around)

    } {
        set nonce REPLY-[clock clicks -microseconds].html
        set F [open $::acs::rootdir/packages/acs-automated-testing/www/$nonce w]
        puts $F [dict get $dict body]
        close $F
        return /test/$nonce
    }

    ad_proc -public reply_contains {{-prefix ""} dict string} {

        Convenience function for test cases to check, whether the
        resulting page contains the given string.

        @param prefix  prefix for logging
        @param dict    request reply dict, containing at least the request body
        @param string  string to be checked on the page
    } {
        set result [string match *$string* [dict get $dict body]]
        if {$result} {
            aa_true "${prefix}Reply contains $string" $result
        } else {
            aa_true "${prefix}Reply contains $string (<a href='[detail_link $dict]'>Details</a>)" $result
        }
        return $result
    }

    ad_proc -public reply_contains_no {{-prefix ""} dict string} {

        Convenience function for test cases to check, whether the
        resulting page does not contain the given string.

        @param prefix  prefix for logging
        @param dict    request reply dict, containing at least the request body
        @param string  string to be checked on the page
    } {
        set result [string match *$string* [dict get $dict body]]
        if {$result} {
            aa_false "${prefix}Reply contains no $string (<a href='[detail_link $dict]'>Details</a>)" $result
        } else {
            aa_false "${prefix}Reply contains no $string" $result
        }
        return [expr {!$result}]
    }

    ad_proc -public reply_has_status_code {{-prefix ""} dict status_code} {

        Convenience function for test cases to check, whether the
        reply has the given status code.

        @param prefix       prefix for logging
        @param dict         request reply dict, containing at least the request status
        @param status_code  expected HTTP status codes

    } {
        set result [expr {[dict get $dict status] == $status_code}]
        if {$result} {
            aa_true "${prefix}Reply has status code $status_code" $result
        } else {
            aa_true "${prefix}Reply expected status code $status_code but got [dict get $dict status] (<a href='[detail_link $dict]'>Details</a>)" $result
        }
        return $result
    }

}

namespace eval ::acs::test::xpath {

    #
    # All procs in this namespace have the signature
    #   root xpath
    # where root is a dom-node and xpath a an XPath expression.
    #
    ad_proc -public get_text {root xpath} {
        Get a text element from tdom via XPath expression.
        If the XPath expression matches multiple nodes,
        return a list.
    } {
        set nodes [$root selectNodes $xpath]
        switch [llength $nodes] {
            0 {set result ""}
            1 {set result [$nodes asText]}
            default {
                set result ""
                foreach n $nodes {
                    lappend result [$n asText]
                }
            }
        }
        return $result
    }


    ad_proc -public non_empty {node selectors} {

        Test if provided selectors return non-empty results

    } {
        #
        # if we have no node, use as default the root in the parent
        # environment
        #
        if {$node eq ""} {
            set node [uplevel {set root}]
        }
        foreach q $selectors {
            try {
                set value [get_text $node $q]
            } on error {errorMsg} {
                aa_true "XPAth exception during evaluation of selector '$q': $errorMsg" 0
                throw {XPATH {xpath triggered exception}} $errorMsg
            }
            aa_true "XPath $q <$value>:" {$value ne ""}
        }
    }

    ad_proc -public equals {node pairs} {

        Test whether provided selectors (first element of the pair)
        return the specified results (second element of the pair).

    } {
        foreach {q value} $pairs {
            try {
                set result [get_text $node $q]
            } on error {errorMsg} {
                aa_true "XPAth exception during evaluation of selector '$q': $errorMsg" 0
                throw {XPATH {xpath triggered exception}} $errorMsg
            }

            aa_equals "XPath $q:" $result $value
        }
    }

    ad_proc -public get_form {node xpath} {

        Locate the HTML forms matching the XPath expression and
        retrieve its HTML attributes and the formfields in form of a
        Tcl dict.

        @return Tcl dict with form attributes (keys starting with "@", and entry "fields")

        @author Gustaf Neumann
    } {
        set d {}
        set form [$node selectNodes $xpath]
        if {[llength $form] > 1} {
            error "XPath expression must point to at most one HTML form"
        } else {
            foreach form [$node selectNodes $xpath] {
                foreach att [$node selectNodes $xpath/@*] {
                    dict set d @[lindex $att 0] [lindex $att 1]
                }
                dict set d fields [::acs::test::xpath::get_form_values $node $xpath]
            }
        }
        return $d
    }


    ad_proc -public get_form_values {node xpath} {

        Obtain form values (input fields and textareas) in form of a
        dict (attribute value pairs). The provided XPath expression
        must point to the HTML form containing the values to be
        extracted.

    } {
        set values {}
        foreach n [$node selectNodes $xpath//input] {
            set name  [$n getAttribute name]
            #ns_log notice "aa_xpath::get_form_values from $className input node $n name $name:"
            if {[$n hasAttribute value]} {
                set value [$n getAttribute value]
            } else {
                set value ""
            }
            lappend values $name $value
        }
        foreach n [$node selectNodes $xpath//textarea] {
            set name  [$n getAttribute name]
            #ns_log notice "aa_xpath::get_form_values from $className textarea node $n name $name:"
            set value [$n text]
            lappend values $name $value
        }
        foreach n [$node selectNodes $xpath//select/option\[@selected='selected'\]] {
            set name  [[$n parentNode] getAttribute name]
            set value [$n getAttribute value]
            lappend values $name $value
        }

        return $values
    }
}

namespace eval acs::test::user {

    ad_proc ::acs::test::user::create {
        {-admin:boolean}
        {-email ""}
        {-locale en_US}
        {-password ""}
        {-user_id ""}
    } {
        Create a test user with random email and password for testing.
        If an email is passed in and the party identified by the
        password exists, the user_id of this party is returned in the
        dict.

        @param user_id  user_id for the user to be created
        @param email    email for the user to be created
        @param password password for the user to be created
        @param admin    provide this switch to make the user site-wide admin
        @param locale   locale for the user to be created

        @return The user_info dict returned by auth::create_user. Contains
                the additional keys email and password.
    } {
        if {$email ne ""} {
            set party_info [party::get -email $email]
            if {[llength $party_info] > 0} {
                #
                # We have such a party already. For the time being,
                # just pick the party_id for the result.
                #
                dict set user_info user_id [dict get $party_info party_id]
                return $user_info
            }
        }
        if {$password eq ""} {
            set password    [ad_generate_random_string]
        }
        set username    "__test_user_[ad_generate_random_string]"
        set email       "$username@test.test"
        set first_names [ad_generate_random_string]
        set last_name   [ad_generate_random_string]

        set user_info [auth::create_user \
                           -user_id $user_id \
                           -username $username \
                           -email $email \
                           -first_names $first_names \
                           -last_name $last_name \
                           -password $password \
                           -secret_question [ad_generate_random_string] \
                           -secret_answer [ad_generate_random_string] \
                           -authority_id [auth::authority::get_id -short_name "acs_testing"]]

        lang::user::set_locale -user_id [dict get $user_info user_id] $locale
        if { [dict get $user_info creation_status] ne "ok" } {
            # Could not create user
            error "Could not create test user with username=$username user_info=[array get user_info]"
        }

        dict set user_info password $password
        dict set user_info email $email
        dict set user_info first_names $first_names
        dict set user_info last_name $last_name

        #aa_log "Created user with email='$email' and password='$password'"
        aa_log "Created user with email='$email'"

        if { $admin_p } {
            aa_log "Making user site-wide admin"
            permission::grant -object_id \
                [acs_magic_object "security_context_root"] \
                -party_id [dict get $user_info user_id] \
                -privilege "admin"
        }

        return $user_info
    }

    ad_proc ::acs::test::user::delete {
        {-user_id:required}
    } {
        Remove a test user.
    } {
        acs_user::delete \
            -user_id $user_id \
            -permanent
    }

}




namespace eval aa_test {}

ad_proc -public aa_test::xml_report_dir {} {
    Retrieves the XMLReportDir parameter.

    @return Returns the value for the XMLReportDir parameter.
} {
    return [parameter::get -parameter XMLReportDir]
}

ad_proc -private aa_test::test_file_path {
    {-install_file_path:required}
} {
    set filename [file tail $install_file_path]
    regexp {^(.+)-(.+)-(.+)\.xml$} $filename match hostname server
    set test_path [file dirname $install_file_path]/${hostname}-${server}-testreport.xml

    return $test_path
}

ad_proc -public aa_test::parse_install_file {
    {-path:required}
    {-array:required}
} {
    Processes the xml report outputted from install.sh for display.
} {
    upvar 1 $array service

    set tree [xml_parse -persist [template::util::read_file $path]]

    set root_node [xml_doc_get_first_node $tree]

    foreach entry {
        name os dbtype dbversion webserver openacs_cvs_flag adminemail adminpassword
        install_begin_epoch install_end_epoch install_end_timestamp num_errors
        install_duration install_duration_pretty script_path description
    } {
        set service($entry) "n/a"
    }
    set service(path) $path
    set service(filename) [file tail $path]
    set service(parse_errors) {}

    set service(name) [xml_node_get_attribute $root_node "name"]
    if { $service(name) eq "" } {
        append service(parse_error) "No service name attribute;"
    }

    foreach child [xml_node_get_children $root_node] {
        set info_type [xml_node_get_attribute $child "type"]
        if { $info_type eq "" } {
            append service(parse_error) "No type on info tag;"
            continue
        }
        set info_type [string map {- _} $info_type]
        set info_value [xml_node_get_content $child]
        set service($info_type) $info_value
    }

    if { [string is integer -strict $service(install_begin_epoch)] && [string is integer -strict $service(install_end_epoch)] } {
        set service(install_duration) [expr {$service(install_end_epoch) - $service(install_begin_epoch)}]
        set service(install_duration_pretty) [util::interval_pretty -seconds $service(install_duration)]
    }

    # TODO: Not working
    set service(admin_login_url) [export_vars -base $service(url)register/ {
        { email $service(adminemail) }
        { password $service(adminpassword) }
    }]
    set service(auto_test_url) "$service(url)test/admin"
    set service(rebuild_cmd) "sh [file join $service(script_path) recreate.sh]"
}

ad_proc -private aa_test::get_test_doc {} {
    Returns an XML doc with statistics for the most recent test results
    on the server.

    @author Peter Marklund
} {
    # Open XML document
    set xml_doc "<?xml version=\"1.0\"?>
    <test_report>\n"

    set testcase_count [llength [nsv_get aa_test cases]]
    append xml_doc "    <testcase_count>$testcase_count</testcase_count>\n"

    db_foreach result_counts {
        select result,
        count(*) as result_count
        from aa_test_results
        group by result
    } {
        set result_counts($result) $result_count
    }

    foreach result [array names result_counts] {
        append xml_doc "    <result_count result=\"$result\">$result_counts($result)</result_count>\n"
    }

    db_foreach failure_counts {
        select testcase_id,
        count(*) as failure_count
        from aa_test_results
        where result = 'fail'
        group by testcase_id
    } {
        set failure_counts($testcase_id) $failure_count
    }

    foreach testcase_id [array names failure_counts] {
        append xml_doc "    <testcase_failure testcase_id=\"$testcase_id\">$failure_counts($testcase_id)</testcase_failure>\n"
    }

    # Close XML document
    append xml_doc "</test_report>\n"

    return $xml_doc
}

ad_proc -private aa_test::write_test_file {} {
    Writes an XML file with statistics for the most recent test results
    on the server.

    @author Peter Marklund

} {
    set xml_doc ""

    set report_dir [aa_test::xml_report_dir]
    if { [file isdirectory $report_dir] } {

        set hostname [exec hostname]
        set server [ns_info server]
        set file_path "$report_dir/${hostname}-${server}-testreport.xml"

        set xml_doc [get_test_doc]

        if { [catch {template::util::write_file $file_path $xml_doc} errmsg] } {
            ns_log Error "Failed to write xml test report to path $file_path - $errmsg"
        }
    }

    return $xml_doc
}

ad_proc -public aa_test::parse_test_file {
    {-path:required}
    {-array:required}
} {
    Processes the xml report with test result data for display.
} {
    upvar 1 $array test

    set tree [xml_parse -persist [template::util::read_file $path]]

    set root_node [xml_doc_get_first_node $tree]

    # Get the total test case count
    set testcase_count_node [xml_node_get_children_by_name $root_node testcase_count]
    set test(testcase_count) [xml_node_get_content $testcase_count_node]

    # Get the result counts by result type
    foreach result_count_node [xml_node_get_children_by_name $root_node result_count] {
        set result [xml_node_get_attribute $result_count_node result]
        set count [xml_node_get_content $result_count_node]
        set result_count($result) $count
    }
    set test(result_count) [array get result_count]

    # Get counts for failing test cases
    foreach testcase_failure_node [xml_node_get_children_by_name $root_node testcase_failure] {
        set testcase_id [xml_node_get_attribute $testcase_failure_node testcase_id]
        set count [xml_node_get_content $testcase_failure_node]
        set testcase_failure($testcase_id) $count
    }
    set test(testcase_failure) [array get testcase_failure]
}

ad_proc aa_test::proc_coverage {
    {-package_key ""}
} {
    Calculates the test proc coverage of a particular package.

    If no 'package_key' is passed, then the system wide test proc coverage is
    returned.

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2019-08-28

    @param package_key  The 'package_key' of the package to check.

    @return Dict with the number of procs (procs), covered procs (covered) and
            the coverage percentage (coverage).

} {
    set procs 0
    set procs_covered 0
    set proc_names [list]
    #
    # Get proc list to check
    #
    if { $package_key ne "" } {
        foreach path [nsv_array names api_proc_doc_scripts] {
            if { [regexp "^packages/$package_key" $path] } {
                lappend proc_names {*}[nsv_get api_proc_doc_scripts $path]
            }
        }
    } else {
        set proc_names [nsv_array names api_proc_doc]
    }
    #
    # Check if the proc is public, not deprecated, and have tests
    #
    foreach proc_name $proc_names {
        array set proc_doc [nsv_get api_proc_doc $proc_name]
        if { [info exists proc_doc(protection)]
            && "public" in $proc_doc(protection)
            && !($proc_doc(deprecated_p) || $proc_doc(warn_p))
        } {
            incr procs
            if { [info exists proc_doc(testcase)] } {
                incr procs_covered
            }
        }
        array unset proc_doc
    }
    #
    # Return the coverage precentage
    #
    if { $procs eq 0 } {
        set coverage 0.0
    } else {
        set coverage [expr {($procs_covered / ($procs + 0.0)) * 100}]
    }
    return "procs $procs covered $procs_covered coverage [lc_numeric [format {%0.2f} $coverage]]%"
}

ad_proc -public aa_get_first_url {
    {-package_key:required}
} {
    Procedure for getting the url of a mounted package with the
    package_key. It uses the first instance that it founds. This is
    useful for tclwebtest tests.
} {
    set url [site_node::get_package_url -package_key $package_key]
    if {$url eq ""} {
        site_node::instantiate_and_mount -package_key $package_key
        set url [site_node::get_package_url -package_key $package_key]
    }

    return $url
}

ad_proc -public aa_display_result {
    {-response:required}
    {-explanation:required}
} {
    Displays either a pass or fail result with specified explanation
    depending on the given response.

    @param response A boolean value where true (or 1, etc) corresponds
    to a pass result, otherwise the result is a fail.
    @param explanation An explanation accompanying the response.
} {
    if {$response} {
        aa_log_result "pass" "[aa_indent] $explanation"
    } else {
        aa_log_result "fail" "[aa_indent] $explanation"
    }
}

ad_proc -public aa_selenium_init {} {
    Setup a global Selenium RC server connection

    @return true is everything is ok, false if there was any error
} {
    # check if the global selenium connection already exists
    global _acs_automated_testing_selenium_init
    if {[info exists _acs_automated_testing_selenium_init]} {
        # if we already initialized Selenium RC this will be true if
        # we already failed to initialize Selenium RC this will be
        # false. We don't want to try to initialize Selenium RC more
        # than once per request thread in any case so just return the
        # previous status. This is a global and is reset on every
        # request.
        return $_acs_automated_testing_selenium_init
    }

    set server_url [parameter::get_from_package_key \
                        -package_key acs-automated-testing \
                        -parameter "SeleniumRcServer" \
                        -default ""]
    if {$server_url eq ""} {
        # no server configured so don't try to initialize
        return 0
    }
    set server_port [parameter::get_from_package_key \
                         -package_key acs-automated-testing \
                         -parameter "SeleniumRcPort" \
                         -default "4444"]
    set browsers [parameter::get_from_package_key \
                      -package_key acs-automated-testing \
                      -parameter "SeleniumRcBrowsers" \
                      -default "*firefox"]
    set success_p [expr {![catch {Se init $server_url $server_port ${browsers} [ad_url]} errmsg]}]
    if {!$success_p} {
        ns_log error [ad_log_stack_trace]
    }
    set _acs_automated_testing_selenium_init $success_p
    return $success_p
}

aa_register_init_class \
    "selenium" \
    "Init Class for Selenium Remote Control" \
    {aa_selenium_init} \
    {catch {Se stop} errmsg}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
