<?xml version="1.0"?>
<queryset>

<fullquery name="db_api_acceptance_tests_drop_footest">      
      <querytext>
      drop table footest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_tests_drop_bartest">      
      <querytext>
      drop table bartest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_tests_drop_footest_seq">      
      <querytext>
      drop sequence footest_seq
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_create_footest_seq">      
      <querytext>
      create sequence footest_seq
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_create_footest">      
      <querytext>
      create table footest (asdf integer unique)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_create_bartest_blah">      
      <querytext>
      create table bartest (asdf varchar(10) unique)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_delete_footest">      
      <querytext>
      delete from footest
      </querytext>
</fullquery>

 
<fullquery name="">      
      <querytext>
      
    }
    incr count
}

if { $count != 1 } { report_error "db_transaction did not continue processing with db_continue_transaction present." }

set count 0
db_dml db_api_acceptance_test_delete_footest "delete from footest"

db_transaction {
    db_dml db_api_acceptance_test_insert_into_footest "insert into footest values (0)"
    error "db_transaction error"
} on_error {
    db_continue_transaction
}

if [db_string db_api_acceptance_test_select_from_footest "select asdf from footest" -default 1] { report_error "db_transaction did not commit with db_continue_transaction present." }

db_dml db_api_acceptance_test_delete_from_footest "delete from footest"

set count 0
db_transaction {
    db_transaction {
	db_abort_transaction
    } on_error {
	incr count
    }
    report_error "db_transaction running code after abort"
} on_error {
    incr count
}

if { $count != 2 } { report_error "db_transaction did not propagate error with on_error block present" }

db_dml db_api_acceptance_test_delete_from_footest_again  "delete from footest"

set count 0
db_transaction {
    db_dml test "nonsense"
} on_error {
    incr count 
}

if { $count != 1 } { report_error "db_transaction did not execute on_error block." }

proc ::replace_the_foo { col } {
    db_transaction {
        db_dml test "delete from footest"
        db_dml test "insert into footest values (:col)"
    }
}

proc ::print_the_foo {} {
     return [db_string db_api_acceptance_test_print_food_test "select asdf from footest" -default 0]
}

replace_the_foo 8
if { [string compare "8" [print_the_foo]] } { report_error "db_transaction did not succeed."}

db_transaction {
    replace_the_foo 14
    if { [string compare "14" [print_the_foo]] } { report_error "db_transaction did not succeed 2."}
    db_abort_transaction
} on_error {
}
if { [string compare "8" [print_the_foo]] } { report_error "db_transaction did not succeed 3."}

set count 0
db_dml db_api_acceptance_test_delete_from_footest_once_again "delete from footest"
db_transaction {
    db_dml db_api_acceptance_test_insert_into_footest_val_1 {insert into footest values(1)}
    incr count
    nonsense
    db_dml db_api_acceptance_test_insert_into_footes_val_2 {insert into footest values(2)}
    incr count
} on_error {

}
if { $count != 1 || [string compare [db_string test "select asdf from footest" -default 0] 0]} { 
    report_error "db_transaction did not succeed: $count, [db_string test "select asdf from footest" -default 0]" 
}


db_transaction {
    db_dml db_api_acceptance_test_insert_into_footest_again_with_val_1 {insert into footest values(1)}
    db_transaction {
	db_dml db_api_acceptance_test_insert_into_footest_again_with_val_2 
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_delete_footest">      
      <querytext>
      delete from footest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest">      
      <querytext>
      insert into footest values (0)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_from_footest">      
      <querytext>
      select asdf from footest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_delete_from_footest">      
      <querytext>
      delete from footest
      </querytext>
</fullquery>

 
<fullquery name="">      
      <querytext>
       on_error 
      </querytext>
</fullquery>

 
<fullquery name="">      
      <querytext>
      delete from footest
      </querytext>
</fullquery>

 
<fullquery name="test">      
      <querytext>
      nonsense
      </querytext>
</fullquery>

 
<fullquery name="test">      
      <querytext>
      nonsense
      </querytext>
</fullquery>

 
<fullquery name="test">      
      <querytext>
      nonsense
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_print_food_test">      
      <querytext>
      select asdf from footest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_delete_from_footest_once_again">      
      <querytext>
      delete from footest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_val_1">      
      <querytext>
      insert into footest values(1)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footes_val_2">      
      <querytext>
      insert into footest values(2)
      </querytext>
</fullquery>

 
<fullquery name="test">      
      <querytext>
      select asdf from footest
      </querytext>
</fullquery>

 
<fullquery name="test">      
      <querytext>
      select asdf from footest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_again_with_val_1">      
      <querytext>
      insert into footest values(1)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_again_with_val_2">      
      <querytext>
      insert into footest values(2) 
      </querytext>
</fullquery>

 
<fullquery name="">      
      <querytext>
       on_error 
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_with_val_3">      
      <querytext>
      insert into footest values(3) 
      </querytext>
</fullquery>

 
<fullquery name="test">      
      <querytext>
      select asdf from footest
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      delete from footest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_with_val_4">      
      <querytext>
      insert into footest values (4)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_again_with_val_4">      
      <querytext>
      insert into footest values (4)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_once_again_with_val_1">      
      <querytext>
      insert into footest values (1)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_once_again_with_val_1">      
      <querytext>
      insert into footest values (2)
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      select * from footest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_yet_again_with_val_1">      
      <querytext>
      insert into footest values (1)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_yet_again_with_val_2">      
      <querytext>
      insert into footest values (2)
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      select * from footest
      </querytext>
</fullquery>

 
<fullquery name="foo_insert">      
      <querytext>
      insert into footest values (1)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_yet_once_again_with_val_2">      
      <querytext>
      insert into footest values (2)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_yet_twice_again_with_val_2">      
      <querytext>
      insert into footest values (2)
      </querytext>
</fullquery>

 
<fullquery name="if">      
      <querytext>
       $correct_p == "0" 
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      select * from footest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_again_again_with_val_1">      
      <querytext>
      insert into footest values(1)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_again_again_with_val_2">      
      <querytext>
      insert into footest values(2)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_again_again_with_val_3">      
      <querytext>
      insert into footest values(3)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_delete_from_footest_another_time">      
      <querytext>
      delete from footest
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      delete from footest
      </querytext>
</fullquery>

 
<fullquery name="">      
      <querytext>
       on_error 
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_another_again_with_val_1">      
      <querytext>
      insert into footest values(1)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_another_again_with_val_2">      
      <querytext>
      insert into footest values(2)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_another_again_with_val_3">      
      <querytext>
      insert into footest values(3)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_select_stuff_from_asdf_from_footest">      
      <querytext>
       select asdf from footest 
      </querytext>
</fullquery>

 
<fullquery name="">      
      <querytext>
      select * from footest where asdf = 0
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      select * from footest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_get_asdf_from_footest_for_some_more_time">      
      <querytext>
      
		select asdf as i from footest where asdf < :asdf
	    
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_get_asdf_from_footest_for_another_time">      
      <querytext>
      
		select asdf as i from footest where asdf < :asdf
	    
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_get_asdf_from_footest_as_i_for_another_time">      
      <querytext>
      
		select asdf as i from footest where asdf > :asdf
	    
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      
		select asdf from footest
	    
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_get_just_asdf_from_footest">      
      <querytext>
      
		select asdf from footest
	    
      </querytext>
</fullquery>

 
<fullquery name="">      
      <querytext>
       on_error 
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_using_values_1">      
      <querytext>
      insert into footest values(1)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_using_values_2">      
      <querytext>
      insert into footest values(2)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_using_values_3">      
      <querytext>
      insert into footest values(3)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_insert_into_footest_using_the_value_1">      
      <querytext>
      insert into footest values(1)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_insert_into_footest_using_the_value_2">      
      <querytext>
      insert into footest values(2)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_insert_into_footest_using_the_value_3">      
      <querytext>
      insert into footest values(3)
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      select asdf from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="dp_api_acceptance_test_select_2_from_footest_where_asdf_is_1">      
      <querytext>
      select 2 as jkl, asdf from footest where asdf = 1
      </querytext>
</fullquery>

 
<fullquery name="dp_api_acceptance_test_select_2_from_footest_where_asdf_is_something">      
      <querytext>
      select 2 as jkl, asdf from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_2_from_footest_where_bind">      
      <querytext>
      select 2 as jkl, asdf from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_2_from_footest_wehre_setId">      
      <querytext>
      select 2 as jkl, asdf from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_value_of_number_1">      
      <querytext>
      insert into footest values(1)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_value_of_number_2">      
      <querytext>
      insert into footest values(2)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_value_of_number_3">      
      <querytext>
      insert into footest values(3)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_values_of_1_yet_again">      
      <querytext>
      insert into footest values(1)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_values_of_2_yet_again">      
      <querytext>
      insert into footest values(2)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_values_of_3_yet_again">      
      <querytext>
      insert into footest values(3)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_get_everything_from_footest">      
      <querytext>
      
	select * from footest
    
      </querytext>
</fullquery>

 
<fullquery name="db_api_test_get_everything_from_footest_get_just_asdf">      
      <querytext>
      
		select asdf as jkl from footest
	    
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_delete_from_footest_without_anything_else">      
      <querytext>
      delete from footest
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_insert_into_footest_values_of_asdf_with_bind_and_some_other_stuff">      
      <querytext>
      insert into footest values (:asdf)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_count_from_footest">      
      <querytext>
      select count(*) from footest where asdf is null
      </querytext>
</fullquery>

 
<fullquery name="dp_api_acceptance_test_delete_from_bartest">      
      <querytext>
      delete from bartest
      </querytext>
</fullquery>

 
<fullquery name="dp_api_acceptance_test_insert_into_bartest_with_asdf">      
      <querytext>
      insert into bartest values (:asdf)
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_count_from_bartest_where_asdf_is_a">      
      <querytext>
      select count(*) from bartest where asdf = 'a'
      </querytext>
</fullquery>

 
<fullquery name="dp_api_acceptance_test_insert_into_bartest_with_values_entered_through_asdf">      
      <querytext>
      insert into bartest values (:asdf)
      </querytext>
</fullquery>

 
<fullquery name="dp_api_acceptance_test_get_count_from_bartest">      
      <querytext>
      select count(*) from bartest where asdf is null
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_remove_from_footest">      
      <querytext>
      delete from footest
      </querytext>
</fullquery>

 
</queryset>
