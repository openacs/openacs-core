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
  nsv_set aa_test categories {config db script web}
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
    if {[lsearch -exact $aa_stub_names $proc_name] == -1} {
      lappend aa_stub_names $proc_name
      proc ${proc_name}_unstubbed [info args $proc_name] [info body $proc_name]
    }
    set aa_stub_sequence($proc_name) 1
    
    set args [list]
    set counter 0
    foreach arg [info args $proc_name] {
        if { [info default $proc_name $arg default_value] } {
            lappend args [list $arg $default_value]
        } else {
            lappend args $arg
        }
    }

    proc $proc_name $args "
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
      nsv_set aa_file_wide_stubs "[info script]" {}
    }
    nsv_lappend aa_file_wide_stubs "[info script]" [list $proc_name $new_body]
  }
}

ad_proc aa_unstub {
  proc_name
} {
  @author Peter Harper
  @creation-date 24 July 2001
} {
    set args [list]
    set counter 0
    foreach arg [info args $proc_name] {
        if { [info default $proc_name $arg default_value] } {
            lappend args [list $arg $default_value]
        } else {
            lappend args $arg
        }
    }

  proc $proc_name $args [info body ${proc_name}_unstubbed]
  return
}

ad_proc -public aa_register_init_class {
  init_class_id
  init_class_desc
  constructor
  destructor
} {
  Registers a initialisation class to be used by one or more testcases.  An
  initialisation class can be assigned to a testcase via the
  aa_register_case proc.<p>
  <p>
  An initialisation constructor is called <strong>once</strong> before
  running a set of testcases, and the descructor called <strong>once</strong>
  upon completion of running a set of testcases.<p>
  The idea behind this is that it could be used to perform data intensive
  operations that shared amoungst a set if testcases.  For example, mounting
  an instance of a package.  This could be performed by each testcase
  individually, but this would be highly inefficient if there are any
  significant number of them.
  <p>
  Better to let the acs-automated-testing infrastructure call
  the init_class code to set the package up, run all the tests, then call
  the descructor to unmount the package.
  @author Peter Harper
  @creation-date 04 November 2001
} {
  #
  # Work out the package key
  #
  set package_root [file join [acs_root_dir] packages]
  set package_rel [string replace [info script] \
                       0 [string length $package_root]]
  set package_key [lindex [file split $package_rel] 0]
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
    aa_log \"Running \\\"$init_class_id\\\" initialisation class constructor\"
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
  set package_root [file join [acs_root_dir] packages]
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
  ad_proc _${package_key}__c_$component_id {} $body
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
  if {$body != ""} {
    aa_log "Running component $component_id"
    uplevel 1 "_${aa_package_key}__c_$component_id"
    return
  } else {
    error "Unknown component $component_id, package $aa_package_key"
  }
}

ad_proc -public aa_register_case {
  {-cats {}}
  {-init_classes {}}
  {-on_error {}}
  testcase_id
  testcase_desc
  args
} {
  Registers a testcase with the acs-automated-testing system.  The testcase may be
  associated with one or more categories using the -cats flag, eg:<br>
  aa_register_case -cats {<br>
    ...category1...<br>
    ...category2...<br>
  } -init_classes {<br>
    ...init_class1...<br>
    ...init_class2...<br>
  } -on_error {<br>
    ...on-error message...<br>
  } my_test_id {<br>
    ...code block one...<br>
  } {<br>
    ...code block two...<br>
  }
  <p>
  An optional message to display on if the test fails can be provided (see above).
  <p>
  Specify a testcase_id, and description.  All other arguments are assumed
  to be one or more bodys to be executed.
  @author Peter Harper
  @creation-date 24 July 2001
} {

  #
  # Work out the package_key.
  #
  set package_root [file join [acs_root_dir] packages]
  set package_rel [string replace [info script] \
                       0 [string length $package_root]]
  set package_key [lindex [file split $package_rel] 0]

  #
  # Print warnings for any unknown categories.
  #
  set filtered_cats {}
  foreach category $cats {
    if {[string trim $category] != ""} {
      if {[lsearch [nsv_get aa_test categories] $category] == -1} {
        ns_log warning "aa_register_case: Unknown testcase category $category"
      }
      lappend filtered_cats $category
    }
  }
  set cats $filtered_cats

  #
  # Print warnings for any unknown init_classes.  We actually mask out
  # any unknown init_classes here, so we don't get any script errors later.
  #
  set filtered_inits {}
  foreach init_class $init_classes {
    if {[string trim $init_class] != ""} {
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

  #
  # First, search the current list of test cases. If an old version already
  # exists, replace it with the new version.
  #
  set lpos 0
  set found_pos -1
  foreach case [nsv_get aa_test cases] {
    if {[lindex $case 0] == $testcase_id &&
        [lindex $case 3] == $package_key} {
      nsv_set aa_test cases [lreplace [nsv_get aa_test cases] $lpos $lpos \
                                 [list $testcase_id $testcase_desc \
                                      [info script] $package_key \
                                      $cats $init_classes $on_error $args]]
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
    nsv_lappend aa_test cases [list $testcase_id $testcase_desc \
                                   [info script] $package_key \
                                   $cats $init_classes $on_error $args]
  }

  if {[llength $init_classes] == 0} {
    set init_class_code ""
  } else {
    set init_class_code "
    global aa_init_class_logs
    upvar 2 _aa_exports _aa_exports
    foreach init_class \[list $init_classes\] {
      foreach v \$_aa_exports(\[list $package_key \$init_class\]) {
        upvar 2 \$v \$v
      }
      foreach logpair \$aa_init_class_logs(\[list $package_key \$init_class\]) {
        aa_log_result \[lindex \$logpair 0\] \[lindex \$logpair 1\]
      }
    }
    "
  }
  ad_proc _${package_key}__$testcase_id {} "
    $init_class_code
    set _aa_export {}
    set body_count 0
    foreach testcase_body \[list $args\] {
      aa_log \"Running testcase body \$body_count\"
      set catch_val \[catch \"eval \[list \$testcase_body\]\" msg\]
      if {\$catch_val != 0 && \$catch_val != 2} {
        global errorInfo
          aa_log_result \"fail\" \"$testcase_id (body \$body_count): Error during execution: \${msg}, stack trace: \n\$errorInfo\"
      }
      incr body_count
    }
  "
  ns_log Debug "aa_register_case: Registered test case $testcase_id in package $package_key"
}

ad_proc -public aa_export_vars {
  args
} {
  Called from a initialisation class constructor or a component to
  explicitly export the specified variables to the current testcase.
} {
  uplevel "
    foreach v $args {
      upvar \$v \$v
      uplevel 1 \"lappend _aa_export \$v\"
    }
  "
}

ad_proc aa_runseries {
  -quiet:boolean
  {-testcase_id ""}
  by_package_key
  by_category
} {
  Runs a series of testcases. <p>
  Runs all cases if both package_key and
  category are blank, otherwise it uses the package and/or category to
  select which testcases to run.
  @author Peter Harper
  @creation-date 24 July 2001
} {
  global aa_run_quietly_p
  global aa_init_class_logs
  global aa_in_init_class

  set aa_run_quietly_p $quiet_p
  #
  # Work out the list of initialisation classes.
  #
  set testcase_ids {}
  if {$testcase_id != ""} {
    lappend testcase_ids $testcase_id
    foreach testcase [nsv_get aa_test cases] {
      if {$testcase_id == [lindex $testcase 0]} {
        set package_key    [lindex $testcase 3]
        set init_classes   [lindex $testcase 5]
        foreach init_class $init_classes {
          set classes([list $package_key $init_class]) 1
        }
      }
    }
  } else {
    foreach testcase [nsv_get aa_test cases] {
      set testcase_id    [lindex $testcase 0]
      set package_key    [lindex $testcase 3]
      set categories     [lindex $testcase 4]
      set init_classes   [lindex $testcase 5]
      if {($by_package_key == "" || ($by_package_key == $package_key)) && \
              ($by_category == "" || ([lsearch $categories $by_category] != -1))} {
        lappend testcase_ids $testcase_id
        foreach init_class $init_classes {
          set classes([list $package_key $init_class]) 1
        }
      }
    }
  }
  #
  # Run each initialisation script.  Keep a list of the exported variables
  # by each initialisation script so each testcase (and destructor) can
  # correctly upvar to gain visibility of them.
  #
  if {[info exists classes]} {
    foreach initpair [array names classes] {
      set package_key [lindex $initpair 0]
      set init_class  [lindex $initpair 1]
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
  # Run each initialisation destructor script.
  #
  if {[info exists classes]} {
    foreach initpair [array names classes] {
      set package_key [lindex $initpair 0]
      set init_class  [lindex $initpair 1]
      set aa_in_init_class [list $package_key $init_class]
      _${package_key}__d_$init_class
    }
  }
  set aa_in_init_class ""
}


ad_proc aa_run_testcase {
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
      set testcase_file     [lindex $testcase 2]
      set package_key       [lindex $testcase 3]
      set aa_package_key    $package_key
      set testcase_cats     [lindex $testcase 4]
      set testcase_inits    [lindex $testcase 5]
      set testcase_on_error [lindex $testcase 6]
      set testcase_bodys    [lindex $testcase 7]
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

  if { [string equal $affirm_actual $affirm_value] } {
    aa_log_result "pass" "$affirm_name Affirm PASSED, actual = \"$affirm_actual\""
    return 1
  } else {
    aa_log_result "fail" "$affirm_name Affirm FAILED, actual = \"$affirm_actual\", expected = \"$affirm_value\""
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
  global aa_testcase_id
  global aa_package_key
  
  set result [uplevel 1 [list expr $affirm_expr]]
  if { $result } {
    aa_log_result "pass" "$affirm_name Affirm PASSED, \"$affirm_expr\" true"
    return 1
  } else {
    aa_log_result "fail" "$affirm_name Affirm FAILED, \"$affirm_expr\" false"
    return 0
  }
}

ad_proc -public aa_false {
  affirm_name
  affirm_expr
} {
  Tests that affirm_expr is false.<br>
  Call this function within a testcase, stub or component.
  
  @return True if the affirmation passed, false otherwise.
  
  @author Peter Harper
  @creation-date 24 July 2001
} {
  global aa_testcase_id
  global aa_package_key

  set result [uplevel 1 [list expr $affirm_expr]]
  if {!$result} {
    aa_log_result "pass" "$affirm_name Affirm PASSED, \"$affirm_expr\" false"
    return 1
  } else {
    aa_log_result "fail" "$affirm_name Affirm FAILED, \"$affirm_expr\" true"
    return 0
  }
}

ad_proc -public aa_log {
  log_notes
} {
  Writes a log message to the testcase log.<p>
  Call this function within a testcase, stub or component.
  @author Peter Harper
  @creation-date 24 July 2001
} {
  global aa_testcase_id
  global aa_package_key
  global aa_run_quietly_p

  if {$aa_run_quietly_p} {
    return
  }

  aa_log_result "log" $log_notes
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

ad_proc aa_log_result {
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

  #
  # If logging is happened whilst in a initialisation class, store the log
  # entry, but don't write it to the database.  Individual testcase will make
  # their own copies of these log entries.
  #
  if {$aa_in_init_class != ""} {
    lappend aa_init_class_logs($aa_in_init_class) \
        [list $test_result $test_notes]
    return
  }

  incr aa_testcase_test_id
  if {$test_result == "pass"} {
    ns_log Debug "aa_log_result: PASSED: $aa_testcase_id, $test_notes"
    incr aa_testcase_passes
  } elseif {$test_result == "fail"} {
    ns_log Error "aa_log_result: FAILED: $aa_testcase_id, $test_notes"
    incr aa_testcase_fails
  } else {
    ns_log Debug "aa_log_result: LOG: $aa_testcase_id, $test_notes"
    set test_result "log"
  }
  # Notes in database can only hold so many characters
  if { [string length $test_notes] > 2000 } {
    set test_notes "[string range $test_notes 0 1996]..."
  }

  db_dml test_result_insert {}
}

ad_proc aa_log_final {
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
    ns_log Error "aa_log_final: FAILED: $aa_testcase_id, $test_fails tests failed"
  }

  db_dml testcase_result_insert {
    insert into aa_test_final_results
    (testcase_id, package_key, timestamp, passes, fails)
    values (:aa_testcase_id, :aa_package_key, sysdate, :test_passes, :test_fails)
  }
}

ad_proc aa_run_with_teardown {
  {-test_code:required}
  {-teardown_code ""}
  -rollback:boolean
} {
  Execute code in test_code and guarantee that code in 
  teardown_code will be executed even if error is thrown. Will catch
  errors in teardown_code as well and provide stack traces for both code blocks.

  @param test_code Tcl code that sets up the test case and executes tests
  @param teardown_code Tcl code that tears down database data etc. that needs to execute
  after testing even if error is thrown.
  @param rollback If specified, any db transactions in test_code will be rolled back.

  @author Peter Marklund
} {
  if { $rollback_p } {
    set test_code "
            set errmsg {}
            db_transaction {
               aa_start_rollback_block
 
               $test_code

                aa_end_rollback_block
                error \"rollback tests\"
            } on_error {
                aa_end_rollback_block
            }

            aa_execute_rollback_tests

            if { !\[empty_string_p \$errmsg\] && !\[string equal \$errmsg \"rollback tests\"\] } {
                global errorInfo
                error \"\$errmsg \n\n \$errorInfo\"
            }
        "
  }

  # Testing
  set setup_error_p [catch {uplevel $test_code} setup_error]
  global errorInfo
  set setup_error_stack $errorInfo

  # Teardown
  set teardown_error_p 0
  if { ![empty_string_p $teardown_code] } {
    set teardown_error_p [catch {uplevel $teardown_code} teardown_error]
    global errorInfo
    set teardown_error_stack $errorInfo
  }

  # Provide complete error message and stack trace
  set error_text ""
  if { $setup_error_p } {
    append error_text "Setup failed with error $setup_error\n\n$setup_error_stack"
  }
  if { $teardown_error_p } {
    append error_text "\n\nTeardown failed with error $teardown_error\n\n$teardown_error_stack"
  }
  if { ![empty_string_p $error_text] } {
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
