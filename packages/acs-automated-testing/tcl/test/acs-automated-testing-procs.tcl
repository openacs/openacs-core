##############################################################################
#
#   Copyright 2001, OpenMSG Ltd, Peter Harper.
#
#   This file is part of acs-automated-testing.
#
##############################################################################

aa_register_init_class "my_init" {
  An example chunk of initialisation code.
} {
  # Constructor
  aa_export_vars {my_var1 my_var2}
  
  set my_var1 "Variable 1"
  set my_var2 "Variable 2"
  aa_equals "Do a dummy test on my_var1" $my_var1 "Variable 1"
  aa_log "Do a test log message"
} {
  # Descructor
  # aa_log, aa_equals, aa_true and aa_false all ignored here.
  set _my_var1 $my_var1
  set _my_var2 $my_var2
  aa_log "Do a log message that should be ignored"
}


aa_register_init_class "my_init2" {
  An second example chunk of initialisation code.
} {
  # Constructor
  aa_log "The second constructor"
} {
  # Descructor
  aa_log "The second destructor"
}


aa_register_component "my_component" {
  An example chunk of component code.
} {
  aa_export_vars {an_example_value}
  set an_example_value 1000
  aa_log "Log message from the example component my_component"
}

aa_register_case -cats {
  tcl
} -init_classes {
  my_init
} "aa_example-000" {
  Tests successful audit writing.
} {
  aa_call_component "my_component"
} {
  set test_value 1056

  aa_stub aa_example_write_audit_entry {
    switch $sequence_id {
      1 {
        aa_equals "aa_example_write_audit_entry" $name "name1"
        aa_equals "aa_example_write_audit_entry" $value "value1"
        return 1
      }
      2 {
        aa_equals "aa_example_write_audit_entry" $name "name2"
        aa_equals "aa_example_write_audit_entry" $value "value2"
        return 1
      }
    }
  }

  set entries {{"name1" "value1"} {"name2" "value2"}}
  set entries_ex $entries

  set result [aa_example_write_audit_entries $entries]

  aa_log "This is a test log message"
  aa_true "return value true" $result
  aa_equals "entries parameter not currupted" $entries $entries_ex
} {
  aa_equals "Check that test_value is visible here" $test_value "1056"
  aa_equals "Check that my_component set value is visible here" $an_example_value "1000"
}

aa_register_case -cats {
  tcl
} -init_classes {
  my_init my_init2
} "aa-example-001" {
  Tests un-successful audit writing.
  First call succeeds, second fails
} {
  aa_stub aa_example_write_audit_entry {
    switch $sequence_id {
      1 {
        aa_equals "aa_example_write_audit_entry, name" $name "name1"
        aa_equals "aa_example_write_audit_entry, value" $value "value1"
        return 1
      }
      2 {
        aa_equals "aa_example_write_audit_entry, name" $name "name2"
        aa_equals "aa_example_write_audit_entry, value" $value "value2"
        return 0
      }
    }
  }

  set entries {{"name1" "value1"} {"name2" "value2"}}
  set entries_ex $entries

  set result [aa_example_write_audit_entries $entries]

  aa_false "return value false" $result
  aa_equals "entries parameter not currupted" $entries $entries_ex
}

aa_register_case -cats {
  tcl
} "aa_example-002" {
  Tests un-successful audit writing.
  First call fails.
} {
  aa_stub aa_example_write_audit_entry {
    switch $sequence_id {
      1 {
        aa_equals "aa_example_write_audit_entry, name" $name "name1"
        aa_equals "aa_example_write_audit_entry, value" $value "value1"
        return 0
      }
    }
  }

  set entries {{"name1" "value1"} {"name2" "value2"}}
  set entries_ex $entries

  set result [aa_example_write_audit_entries $entries]

  aa_false "return value false" $result
  aa_equals "entries parameter not corrupted" $entries $entries_ex
}

aa_register_case -cats {
    security_risk
} "aa_example-exclusion-security-risk" {
    If security-risk is not checked, this test shouldn't run
} {
    aa_log "Unless security-risk is was checked, you shouldn't see this test."
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_example {
    A simple test case demonstrating the use of tclwebtest (HTTP level testing).

    @author Peter Marklund
} {
    set user_id [db_nextval acs_object_id_seq]

    aa_run_with_teardown \
        -test_code {
            # Create test user
            array set user_info [twt::user::create -user_id $user_id]

            twt::user::login $user_info(email) $user_info(password)

            twt::do_request "/acs-lang"

        } -teardown_code {
            # TODO: delete test user
            twt::user::delete -user_id $user_id
        }
}
