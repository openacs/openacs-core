ad_library {
    Tests for the procs in tcl-documentation-procs.tcl

    @author Lars Pind (lars@pinds.com)
    @creation-date 26 July 2000
    @cvs-id $Id$
}

test_case proc ad_page_contract integer_filter {
    Makes sure the :integer filter works as advertised.
} -setup {
    test_set_form { 
	int_empty ""
	int_alpha "a1"
	int_ok 1
    } 
} -invoke {
    ad_page_contract {} {
	int_undef:integer
	int_empty:integer
	int_alpha:integer
	int_ok:integer
    } -errors {
	int_undef "int_undef"
	int_empty:integer "int_empty"
	int_alpha:integer "int_alpha"
	int_ok:integer    "int_ok"
    }
} -check {
    test_assert_ad_script_abort
    
    test_assert_elm [ad_complaints_get_list] int_undef {We shouldn't allow a missing value to pass}
    test_assert_elm [ad_complaints_get_list] int_alpha {The integer filter shouldn't allow a string containing non-digits to pass}
    test_assert_elm_not [ad_complaints_get_list] int_ok {This is a valid integer, so it should pass}
    test_assert_elm_not [ad_complaints_get_list] int_empty {Since we haven't said :notnull, the empty string should pass}
    
    test_assert_int [ad_complaints_count] 2 "Too many complaints: Only expected [list int_undef int_alpha int_empty] but got [ad_complaints_get_list]"
}



test_case proc ad_page_contract notnull_flag {
    Checks the new functionality of the :notnull-filter
} -setup {
    test_set_form {
	empty {}
	normal {abc}
	empty_default {}
	empty_optional {}
	normal_optional {abc}
    }
} -invoke {
    ad_page_contract {} {
	unset:notnull
	empty:notnull
	normal:notnull
	{unset_default:notnull ok}
	{normal_default:notnull ok}
	unset_optional:notnull,optional
	empty_optional:notnull,optional
	normal_optional:notnull,optional
    } -errors {
        unset {unset}
	empty {empty}
	empty:notnull {empty:notnull}
	normal {normal}
	unset_default {unset_default}
	empty_default {empty_default}
	empty_default:notnull {empty_default:notnull}
	normal_deafault {normal_default}
	unset_optional {unset_optional}
	empty_optional {empty_optional}
	normal_optional {normal_optional}
    }
} -check {
    test_assert_ad_script_abort
    
    test_assert_elm [ad_complaints_get_list] unset {We shold get an error for a variable that's not set}
    test_assert_elm [ad_complaints_get_list] empty:notnull {We should get a notnull error for a variable that's empty}
    test_assert_elm_not [ad_complaints_get_list] normal

    test_assert_elm_not [ad_complaints_get_list] unset_default
    test_assert_elm_not [ad_complaints_get_list] empty_default

    test_assert_elm_not [ad_complaints_get_list] unset_optional
    test_assert_elm_not [ad_complaints_get_list] empty_optional
    test_assert_elm_not [ad_complaints_get_list] normal_optional

    test_assert_int [info exists unset] 0 {The variable "unset" shouldn't be set}
    test_assert_int [info exists empty] 0 {The variable "empty" shouldn't be set}
    test_assert $normal abc
    
    test_assert $unset_default ok
    test_assert $normal_default ok
    
    test_assert_int [info exists undef_optional] 0
    test_assert_int [info exists empty_optional] 0
    test_assert $normal_optional abc
}


test_case proc ad_page_contract default_values {
    Tests that default values work
} -invoke {
    ad_page_contract {} {
	{unset_1 {foo}}
	{unset_2 {$unset_1}}
    }
} -check {
    test_assert_error_not
    
    test_assert_int [ad_complaints_count] 0

    test_assert $unset_1 foo
    test_assert $unset_2 foo
}


test_case proc ad_page_contract documentation_example {
    Makes sure the example from the ad_page_contract documentation actually works.
} -setup {
    test_set_form {
	foo baz
	bar 1
	bar 10
    }
} -invoke {
    ad_page_contract {} {
	foo
	bar:integer,notnull,multiple,trim
	{greble:integer {[expr [lindex $bar 0]+ 1]}}
    }
} -check {
    test_assert_ad_script_abort_not "Expected no complaints, but got [ad_complaints_get_list]"
    test_assert_error_not

    test_assert_elm $bar 1
    test_assert_elm $bar 10
    test_assert_int $greble 2
}
