ad_page_contract {
    ACID must be tested db_transaction (concurrency testing?) (A and D work, C and I harder to test)
    nested calls (foreach/1row foreach/foreach foreach/0or1row)
    binding needs to be better tested

    @creation-date 2000-05-24
    @return "success"
    @cvs-id $Id$
} 

ad_proc ::let {bindings code} {
    Scheme fun.
} {
     eval "
foreach binding \$bindings {
    set \[lindex \$binding 0] \[lindex \$binding 1]
    unset binding
}
unset bindings code
$code
"
}

set setId [ns_set new]
ns_set put $setId asdf 1
ns_set put $setId foo 2
ns_set put $setId bar 3
ns_set put $setId type set

set val [list asdf 1 foo 2 bar 3 type val]

proc ::report_error {str} {
    doc_return  500 text/plain "ERROR: $str"
    ad_script_abort
}

# throw away remainders from previous test if it didn't finish cleanly
catch { db_dml db_api_acceptance_tests_drop_footest "drop table footest" }
catch { db_dml db_api_acceptance_tests_drop_bartest "drop table bartest" }
catch { db_dml db_api_acceptance_tests_drop_footest_seq "drop sequence footest_seq" }

# sequence test
db_dml db_api_acceptance_test_create_footest_seq "create sequence footest_seq"

set start [db_nextval footest_seq]
set next [db_nextval footest_seq]

if { ![expr $next > $start] } {
    report_error "db_nextval did not correctly increment sequence"
}

# db quoting test
set teststr {a&^%$&*sdf jkl 39 dkk39""$$}
if { [db_quote $teststr] != $teststr } {
    report_error "db_quote messed with a clean string"
}

set teststr {a&^%$&*sdf'' jkl 39 dkk39""'$'$'}
if { [db_quote $teststr] != {a&^%$&*sdf'''' jkl 39 dkk39""''$''$''} } {
    report_error "db_quote messed with a clean string"
}

# real db stuff from here on out
db_dml db_api_acceptance_test_create_footest "create table footest (asdf integer unique)"
db_dml db_api_acceptance_test_create_bartest_blah "create table bartest (asdf varchar(10) unique)"

## db_dml
# nobind/env/val/arg
# blobs, clobs, clob_files, blob_files

## db_write_clob

## db_write_blob

## db_blob_get_file


## db_transaction
## db_abort_transaction
db_dml db_api_acceptance_test_delete_footest "delete from footest"

# control flow, on_error code block
db_transaction {
    expr 1 + 1
} on_error { report_error "db_transcation ran on_error code without error" }

set count 0
catch {
    db_transaction {
	db_transaction {
	    error "db_transaction inside transactions 1"
	} on_error {
	    incr count
	}
	report_error "db_transaction running code after error"
    } on_error {
	incr count
    }
} err

if { $count != 2 } { report_error "db_transaction did not propagate error with on_error block present" }

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
	db_dml db_api_acceptance_test_insert_into_footest_again_with_val_2 {insert into footest values(2) }
	db_abort_transaction
    }
    db_dml db_api_acceptance_test_insert_into_footest_with_val_3 {insert into footest values(3) }
} on_error {
    db_continue_transaction
}
if { ![string compare [db_string test "select asdf from footest where asdf=3" -default 0] 3] } {
    report_error "db_continue_transaction is not functioning."
}
db_dml unused "delete from footest"

# aborting
proc ::abort_transaction_in_proc {} {
    db_dml db_api_acceptance_test_insert_into_footest_with_val_4 "insert into footest values (4)"
    db_abort_transaction
}

proc ::error_in_proc {} {
    db_dml db_api_acceptance_test_insert_into_footest_again_with_val_4 "insert into footest values (4)"
    error "HELLO"
}

let {} {
    db_transaction {
	db_dml db_api_acceptance_test_insert_into_footest_once_again_with_val_1 "insert into footest values (1)"
	db_transaction {
	    db_dml db_api_acceptance_test_insert_into_footest_once_again_with_val_1 "insert into footest values (2)"
	    db_transaction {
		abort_transaction_in_proc
# This is now legal according to new spec.
#		report_error "db_abort_transaction continued executing 3a"
	    }
#	    report_error "db_abort_transaction continued executing 2a"
	}
#	report_error "db_abort_transaction continued executing 1a"
    } on_error {

    }

    if { [llength [db_list unused "select * from footest"]] != "0" } {
	report_error "db_abort_transaction did not rollback on abort"
    }

    catch {
	db_transaction {
	    db_dml db_api_acceptance_test_insert_into_footest_yet_again_with_val_1 "insert into footest values (1)"
	    db_transaction {
		db_dml db_api_acceptance_test_insert_into_footest_yet_again_with_val_2 "insert into footest values (2)"
		db_transaction {
		    error_in_proc
		    report_error "db_abort_transaction continued executing 3b"
		}
		report_error "db_abort_transaction continued executing 2b"
	    }
	    report_error "db_abort_transaction continued executing 1b"
	}
    } err

    if { [llength [db_list unused "select * from footest"]] != "0" } {
	report_error "db_abort_transaction did not rollback on error in transaction"
    }

    set correct_p 0
    db_transaction {
	catch {
	    db_dml foo_insert "insert into footest values (1)"
	    db_transaction {
		db_dml db_api_acceptance_test_insert_into_footest_yet_once_again_with_val_2 "insert into footest values (2)"
		db_transaction {
		    db_dml db_api_acceptance_test_insert_into_footest_yet_twice_again_with_val_2 "insert into footest values (2)"
		    report_error "db_abort_transaction continued executing 3c"
		}
		report_error "db_abort_transaction continued executing 2c"
	    }
	    report_error "db_abort_transaction continued executing 1c"
	} correct_p

        db_abort_transaction
        if { $correct_p == "0" } {
	    report_error "db_abort_transaction did not raise error on SQL exception"
	}
    } on_error {

    }

    if { [llength [db_list unused "select * from footest"]] != "0" } {
	report_error "db_abort_transaction did not rollback SQL error"
    }
}


## db_resultrows
let {} {
    db_transaction {
	db_dml db_api_acceptance_test_insert_into_footest_again_again_with_val_1 "insert into footest values(1)"
	db_dml db_api_acceptance_test_insert_into_footest_again_again_with_val_2 "insert into footest values(2)"
	db_dml db_api_acceptance_test_insert_into_footest_again_again_with_val_3 "insert into footest values(3)"
	if { [db_resultrows] != 1 } { report_error "db_resultrows did not work" }
	db_dml db_api_acceptance_test_delete_from_footest_another_time "delete from footest"
	if { [db_resultrows] != 3 } { report_error "db_resultrows did not work" }
	db_dml unused "delete from footest"
	if { [db_resultrows] != 0 } { report_error "db_resultrows did not work" }
	db_abort_transaction 
    } on_error {
    }
}

## db_foreach
let [list [list val $val] [list setId $setId]] {
    db_transaction {
	db_dml db_api_acceptance_test_insert_into_footest_another_again_with_val_1 "insert into footest values(1)"
	db_dml db_api_acceptance_test_insert_into_footest_another_again_with_val_2 "insert into footest values(2)"
	db_dml db_api_acceptance_test_insert_into_footest_another_again_with_val_3 "insert into footest values(3)"

	# looping, variable setting
	let {} {
	    set counti 0
	    set countj 0
	    db_foreach db_api_acceptance_test_get_asdf_from_footest {
		select asdf as i, sysdate as datestr from footest
	    } {
		# should be counti, countj, i, datestr
		if { [llength [info locals]] != 4 } { report_error "db_foreach too many locals [info locals]" }
		incr counti
		if { $i != $counti } { report_error "db_foreach looped incorrectly 2; i $i; counti $counti" }

		set countj 0
		db_foreach  db_api_acceptance_test_get_asdf_from_footest_again  {
		    select asdf as j, sysdate as datestr2 from footest
		} {
		    # vars from above, j, datestr2
		    if { [llength [info locals]] != 6 } { report_error "db_foreach too many locals" }

		    incr countj
		    if { $j != $countj } { report_error "db_foreach looped incorrectly 3" }
		    if { ![info exists datestr2] || ![info exists datestr]} {
			report_error "db_foreach variables not set"
		    }
		}
	    }
	}

	# control flow (break, continue)
	let {{count 0}} {
	    db_foreach  db_api_acceptance_select_date { select sysdate from dual } {
		break
		incr count
	    }
	    if { $count != 0 } { report_error "db_foreach executed past break $count" }

	    set count 0
	    db_foreach  db_api_acceptance_select_stuff_from_asdf_from_footest { select asdf from footest } {
		if { $count == 1 } { continue } else { incr count }
	    }

	    if { $count != 1 } { report_error "db_foreach bad continue" }
	}

	# if no rows
	let {} {
	    set correct_p 0
	    db_foreach  db_api_acceptance_test_get_everything_from_footest_based_on_asdf  "select * from footest where asdf = 0" {
		report_error "inside loop without select succeeding" 
	    } if_no_rows { set correct_p 1 }

	    if { !$correct_p } { report_error "db_foreach if_no_rows did not execute" }

	    set correct_p 1
	    set count 0
	    db_foreach unused "select * from footest" {
		incr count
	    } if_no_rows { set correct_p 0 }

	    if { !$correct_p } { report_error "db_foreach if_no_rows executed incorrectly" }
	    if { $count != 3 } { report_error "db_foreach didn't loop correctly with if no rows" }
	}

	# binding options, locals
	let [list [list val $val] [list setId $setId]] {
	    set count 0
	    set asdf 3
	    db_foreach  db_api_acceptance_test_get_asdf_from_footest_for_some_more_time {
		select asdf as i from footest where asdf < :asdf
	    } {
		if { [llength [info locals]] != 5 } { report_error "db_foreach wrong locals [info locals]" }
		incr count $i
	    }
	    if { $count != 3 } { report_error "db_foreach did not work correctly" }

	    set count 0
	    db_foreach  db_api_acceptance_test_get_asdf_from_footest_for_another_time {
		select asdf as i from footest where asdf < :asdf
	    } -bind {asdf 2} {
		if { [llength [info locals]] != 5 } { report_error "db_foreach wrong locals [info locals]" }
		incr count $i
	    }
	    if { $count != 1 } { report_error "db_foreach did not work correctly" }

	    set count 0
	    db_foreach  db_api_acceptance_test_get_asdf_from_footest_as_i_for_another_time {
		select asdf as i from footest where asdf > :asdf
	    } -bind $setId {
		if { [llength [info locals]] != 5 } { report_error "db_foreach wrong locals [info locals]" }
		incr count $i
	    }
	    if { $count != 5 } { report_error "db_foreach did not work correctly" }
	}

	# array return values, locals
	let [list [list val $val] [list setId $setId]] {
	    set count 0
	    set datestrtrue [db_string unused "select sysdate from dual"]
	    db_foreach unused {
		select asdf from footest
	    } -column_array arr {
		if { [llength [info locals]] != 5 } { report_error "db_foreach wrong locals [info locals]" }
		incr count
		if { [llength [array names arr]] != 1 } { report_error "db_foreach long array" }
		if { $arr(asdf) != $count } { report_error "db_foreach incorrect value 1; $arr(asdf) $count" }
	    }

	    set count 0
	    db_foreach  db_api_acceptance_test_get_asdf_and_date_from_footest {
		select asdf, sysdate as datestr from footest
	    } -column_array arr {
		if { [llength [info locals]] != 5 } { report_error "db_foreach wrong locals [info locals]" }
		incr count
		if { [llength [array names arr]] != 2 } { report_error "db_foreach wrong array" }
		if { $arr(asdf) != $count } { report_error "db_foreach incorrect value" }
		if { $arr(datestr) != $datestrtrue } { report_error "db_foreach incorrect value" }
	    }

	    set count 0
	    db_foreach  db_api_acceptance_test_get_asdf_sysdate_42_from_footest {
		select asdf, sysdate as datestr, 42 as jkl from footest
	    } -column_array arr {
		if { [llength [info locals]] != 5 } { report_error "db_foreach wrong locals [info locals]" }
		incr count
		if { [llength [array names arr]] != 3 } { report_error "db_foreach wrong array" }
		if { $arr(asdf) != $count } { report_error "db_foreach incorrect value" }
		if { $arr(datestr) != $datestrtrue } { report_error "db_foreach incorrect value" }
		if { $arr(jkl) != 42 } { report_error "db_foreach incorrect value" }
	    }
	}

	# ns_set return values
	let [list [list val $val] [list setId $setId]] {
	    set valset [ns_set new]
	    set count 0
	    set datestrtrue [db_string unused "select sysdate from dual"]
	    db_foreach  db_api_acceptance_test_get_just_asdf_from_footest {
		select asdf from footest
	    } -column_set valset {
		if { [llength [info locals]] != 5 } { report_error "db_foreach wrong locals [info locals]" }
		incr count
		if { [ns_set size $valset] != 1 } { report_error "db_foreach long array" }
		if { [ns_set get $valset asdf] != $count } { report_error "db_foreach incorrect value" }
	    }

	    set valset [ns_set new]
	    set count 0
	    db_foreach  db_api_acceptance_test_get_just_asfd_and_sysdate_from_footest {
		select asdf, sysdate as datestr from footest
	    } -column_set valset {
		if { [llength [info locals]] != 5 } { report_error "db_foreach wrong locals [info locals]" }
		incr count
		if { [ns_set size $valset] != 2 } { report_error "db_foreach wrong array" }
		if { [ns_set get $valset asdf] != $count } { report_error "db_foreach incorrect value" }
		if { [ns_set get $valset datestr] != $datestrtrue } { report_error "db_foreach incorrect value" }
	    }

	    set valset [ns_set new]
	    set count 0
	    db_foreach  db_api_acceptance_test_get_simply_asdf_sysdate_and_42_from_footest {
		select asdf, sysdate as datestr, 42 as jkl from footest
	    } -column_set valset {
		if { [llength [info locals]] != 5 } { report_error "db_foreach wrong locals [info locals]" }
		incr count
		if { [ns_set size $valset] != 3 } { report_error "db_foreach wrong array" }
		if { [ns_set get $valset asdf] != $count } { report_error "db_foreach incorrect value" }
		if { [ns_set get $valset datestr] != $datestrtrue } { report_error "db_foreach incorrect value" }
		if { [ns_set get $valset jkl] != 42 } { report_error "db_foreach incorrect value" }
	    }
	}
	db_abort_transaction
    } on_error {

    } 
}

## db_1row

db_transaction {
    db_dml  db_api_acceptance_test_insert_into_footest_using_values_1 "insert into footest values(1)"
    db_dml  db_api_acceptance_test_insert_into_footest_using_values_2 "insert into footest values(2)"
    db_dml  db_api_acceptance_test_insert_into_footest_using_values_3 "insert into footest values(3)"

    # 3 bind styles
    # 5 returns: normal return, column_array return, column_set return, no rows error, multi rows error
    # 15 tests

    # environment bind
    let {} {
	set asdf 1
	db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_1 "select asdf, sysdate as datestr from footest where asdf = :asdf"
	if { [llength [info locals]] != 2 } { report_error "db_1row too many locals" }
    }

    let {} {
	set asdf 1
	if { ![catch { db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_2 "select asdf, sysdate as datestr from footest where asdf > :asdf" }] } {
	    report_error "db_1row did not error on multiple returned rows"
	}
	if { [llength [info locals]] != 1 } { report_error "db_1row too many locals" }
    }

    let {} {
	set asdf 1
	if { ![catch { db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_3 "select asdf, sysdate as datestr from footest where asdf < :asdf" }] } {
	    report_error "db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_3 did not error on no returned rows"
	}
	if { [llength [info locals]] != 1 } { report_error "db_1row too many locals" }
    }

    let {} {
	set asdf 1
	db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_4 "select asdf, sysdate as datestr from footest where asdf = :asdf" -column_array arr
	if { [llength [info locals]] != 2 } { report_error "db_1row too many locals"  }
	if { [llength [array names arr]] != 2 } { report_error "db_1row bad output array" }
    }

    let {} {
	set asdf 1
	set myset [ns_set new]
	db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_5 "select asdf, sysdate as datestr from footest where asdf = :asdf" -column_set myset
	if { [llength [info locals]] != 2 } { report_error "db_1row too many locals [info locals]" }
	if { [ns_set size $myset] != 2 } { report_error "db_1row bad output ns_set" }
    }

    # values bind
    let {} {
        db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_6 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind {asdf 1}
	if { [llength [info locals]] != 2 } { report_error "db_1row too many locals" }
    }

    let {} {
	if { ![catch { db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_7 "select asdf, sysdate as datestr from footest where asdf > :asdf" -bind {asdf 1}}] } {
	    report_error "db_1row did not error on multiple returned rows"
	}
	if { [llength [info locals]] != 0 } { report_error "db_1row too many locals" }
    }

    let {} {
	if { ![catch { db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_8 "select asdf, sysdate as datestr from footest where asdf < :asdf" -bind {asdf 1}}] } {
	    report_error "db_1row unused did not error on no returned rows"
	}
	if { [llength [info locals]] != 0 } { report_error "db_1row too many locals" }
    }

    let {} {
	db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_9 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind {asdf 1} -column_array arr
	if { [llength [info locals]] != 1 } { report_error "db_1row too many locals"  }
	if { [llength [array names arr]] != 2 } { report_error "db_1row bad output array" }
    }

    let {} {
	set myset [ns_set new]
	db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_10 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind {asdf 1} -column_set myset
	if { [llength [info locals]] != 1 } { report_error "db_1row too many locals [info locals]" }
	if { [ns_set size $myset] != 2 } { report_error "db_1row bad output ns_set" }
    }

    # set bind
    let [list [list setId $setId]] {
	db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_11 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind $setId
	if { [llength [info locals]] != 3 } { report_error "db_1row too many locals" }
    }

    let [list [list setId $setId]] {
	if { ![catch { db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_12 "select asdf, sysdate as datestr from footest where asdf > :asdf" -bind $setId}] } {
	    report_error "db_1row did not error on multiple returned rows"
	}
	if { [llength [info locals]] != 1 } { report_error "db_1row too many locals" }
    }

    let [list [list setId $setId]] {
	if { ![catch { db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_13 "select asdf, sysdate as datestr from footest where asdf < :asdf" -bind $setId}] } {
	    report_error "db_1row unused did not error on no returned rows"
	}
	if { [llength [info locals]] != 1 } { report_error "db_1row too many locals" }
    }

    let [list [list setId $setId]] {
	db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_14 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind $setId -column_array arr
	if { [llength [info locals]] != 2 } { report_error "db_1row too many locals"  }
	if { [llength [array names arr]] != 2 } { report_error "db_1row bad output array" }
    }

    let [list [list setId $setId]] {
	set myset [ns_set new]
	db_1row  db_api_acceptance_test_select_asdf_sysdate_from_food_15 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind $setId -column_set myset
	if { [llength [info locals]] != 2 } { report_error "db_1row too many locals [info locals]" }
	if { [ns_set size $myset] != 2 } { report_error "db_1row bad output ns_set" }
    }

    db_abort_transaction
} on_error {
}

## db_0or1row

db_transaction {
    db_dml db_api_acceptance_insert_into_footest_using_the_value_1 "insert into footest values(1)"
    db_dml db_api_acceptance_insert_into_footest_using_the_value_2 "insert into footest values(2)"
    db_dml db_api_acceptance_insert_into_footest_using_the_value_3 "insert into footest values(3)"

    # 3 bind styles
    # 5 returns: normal return, column_array return, column_set return, no rows return 0, multi rows error
    # 15 tests

    # environment bind
    let {} {
	set asdf 1
	db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_0 "select asdf, sysdate as datestr from footest where asdf = :asdf"
	if { [llength [info locals]] != 2 } { report_error "db_0or1row too many locals" }
    }

    let {} {
	set asdf 1
	if { ![catch {db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_1 "select asdf, sysdate as datestr from footest where asdf > :asdf"}] } {
	    report_error "db_0or1row did not error on multiple returned rows"
	}
	if { [llength [info locals]] != 1 } { report_error "db_0or1row too many locals" }
    }

    let {} {
	set asdf 1
	if { [db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_2 "select asdf, sysdate as datestr from footest where asdf < :asdf" ] } {
	    report_error "db_0or1row unused did not error on no returned rows"
	}
	if { [llength [info locals]] != 1 } { report_error "db_0or1row too many locals" }
    }

    let {} {
	set asdf 1
	db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_3 "select asdf, sysdate as datestr from footest where asdf = :asdf" -column_array arr
	if { [llength [info locals]] != 2 } { report_error "db_0or1row too many locals"  }
	if { [llength [array names arr]] != 2 } { report_error "db_0or1row bad output array" }
    }

    let {} {
	set asdf 1
	set myset [ns_set new]
	db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_4 "select asdf, sysdate as datestr from footest where asdf = :asdf" -column_set myset
	if { [llength [info locals]] != 2 } { report_error "db_0or1row too many locals [info locals]" }
	if { [ns_set size $myset] != 2 } { report_error "db_0or1row bad output ns_set" }
    }

    # values bind
    let {} {
        db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_5 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind {asdf 1}
	if { [llength [info locals]] != 2 } { report_error "db_0or1row too many locals" }
    }

    let {} {
	if { ![catch {db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_6 "select asdf, sysdate as datestr from footest where asdf > :asdf" -bind {asdf 1}}] } {
	    report_error "db_0or1row did not error on multiple returned rows"
	}
	if { [llength [info locals]] != 0 } { report_error "db_0or1row too many locals" }
    }

    let {} {
	if { [db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_7 "select asdf, sysdate as datestr from footest where asdf < :asdf" -bind {asdf 1}] } {
	    report_error "db_0or1row unused did not error on no returned rows"
	}
	if { [llength [info locals]] != 0 } { report_error "db_0or1row too many locals" }
    }

    let {} {
	db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_8 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind {asdf 1} -column_array arr
	if { [llength [info locals]] != 1 } { report_error "db_0or1row too many locals"  }
	if { [llength [array names arr]] != 2 } { report_error "db_0or1row bad output array" }
    }

    let {} {
	set myset [ns_set new]
	db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_9 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind {asdf 1} -column_set myset
	if { [llength [info locals]] != 1 } { report_error "db_0or1row too many locals [info locals]" }
	if { [ns_set size $myset] != 2 } { report_error "db_0or1row bad output ns_set" }
    }

    # set bind
    let [list [list setId $setId]] {
	db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_10 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind $setId
	if { [llength [info locals]] != 3 } { report_error "db_0or1row too many locals" }
    }

    let [list [list setId $setId]] {
	if { ![catch {db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_11 "select asdf, sysdate as datestr from footest where asdf > :asdf" -bind $setId}] } {
	    report_error "db_0or1row did not error on multiple returned rows"
	}
	if { [llength [info locals]] != 1 } { report_error "db_0or1row too many locals" }
    }

    let [list [list setId $setId]] {
	if { [db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_12 "select asdf, sysdate as datestr from footest where asdf < :asdf" -bind $setId] } {
	    report_error "db_0or1row unused did not error on no returned rows"
	}
	if { [llength [info locals]] != 1 } { report_error "db_0or1row too many locals" }
    }

    let [list [list setId $setId]] {
	db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_13 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind $setId -column_array arr
	if { [llength [info locals]] != 2 } { report_error "db_0or1row too many locals"  }
	if { [llength [array names arr]] != 2 } { report_error "db_0or1row bad output array" }
    }

    let [list [list setId $setId]] {
	set myset [ns_set new]
	db_0or1row db-api-acceptance-test_select_asdf_and_system_date_from_footest_14 "select asdf, sysdate as datestr from footest where asdf = :asdf" -bind $setId -column_set myset
	if { [llength [info locals]] != 2 } { report_error "db_0or1row too many locals [info locals]" }
	if { [ns_set size $myset] != 2 } { report_error "db_0or1row bad output ns_set" }
    }

    db_abort_transaction
} on_error {
}

## db_string

db_transaction {
    # raise error on empty select
    set count 0
    set asdf 1
    incr count [catch { db_string db-api-acceptance-test_select_asdf_from_footest_again_and_again "select asdf from footest" }]
    incr count [catch { db_string db-api-acceptance-test_select_asdf_from_footest_again_and_again_depending_on_asdf "select asdf from footest where asdf = :asdf" }]
    incr count [catch { db_string db-api-acceptance-test_select_asdf_from_footest_again_and_again_and_again "select asdf from footest where asdf = :asdf" -bind {asdf 1}}]
    incr count [catch { db_string unused "select asdf from footest where asdf = :asdf" -bind $setId}]

    if { $count != 4 } { report_error "db_string did not raise exception on empty select" }

    # default value
    set count 0
    incr count [db_string db-api-acceptance-test_select_asdf_from_footest_default_value "select asdf from footest" -default 2]
    incr count [db_string db-api-acceptance-test_select_asdf_from_footest_default_value_2 "select asdf from footest where asdf = :asdf" -default 2]
    incr count [db_string db-api-acceptance-test_select_asdf_from_footest_default_bind "select asdf from footest where asdf = :asdf" -default 2 -bind {asdf 1}]
    incr count [db_string db-api-acceptance-test_select_asdf_from_footest_default_asdf_1 "select asdf from footest where asdf = :asdf" -bind {asdf 1} -default 2]
    incr count [db_string db-api-acceptance-test_select_asdf_from_footest_default_setId "select asdf from footest where asdf = :asdf" -bind $setId -default 2]
    incr count [db_string db-api-acceptance-test_select_asdf_from_footest_default_bind_and_setId "select asdf from footest where asdf = :asdf" -default 2 -bind $setId]

    if { $count != 12 } { report_error "db_string did not set default correctly" }

    db_dml db-api-acceptance-test_insert_into_footest_by_using_values_of_values_1 "insert into footest values(1)"
    db_dml db-api-acceptance-test_insert_into_footest_by_using_values_of_values_2 "insert into footest values(2)"
    db_dml db-api-acceptance-test_insert_into_footest_by_using_values_of_values_3 "insert into footest values(3)"

    # raise error on multirow select
    set count 0
    set asdf 1
    incr count [catch { db_string db-api-acceptance-test_select_asdf_from_foottest_rasie_error_on_mutlirow_select "select asdf from footest" }]
    incr count [catch { db_string db-api-acceptance-test_select_asdf_from_foottest_rasie_error_on_mutlirow_select_where_asdf_bigger "select asdf from footest where asdf > :asdf" }]
    incr count [catch { db_string db-api-acceptance-test_select_asdf_from_foottest_rasie_error_on_mutlirow_select_where_asdf_bigger_with_bind "select asdf from footest where asdf > :asdf" -bind {asdf 1}}]
    incr count [catch { db_string db-api-acceptance-test_select_asdf_from_foottest_rasie_error_on_mutlirow_select_where_asdf_bigger_with_set_id "select asdf from footest where asdf > :asdf" -bind $setId}]

    if { $count != 4 } { report_error "db_string did not raise exception on multirow select select" }

    # work normally
    set count 0
    set asdf 1
    incr count [db_string db-api-acceptance-test_select_asdf_from_footest_where_asdf_is_1 "select asdf from footest where asdf = 1"]
    incr count [db_string db-api-acceptance-test_select_asdf_from_footest_work_normally "select asdf from footest where asdf = :asdf"]
    incr count [db_string db-api-acceptance-test_select_asdf_from_footest_work_normally_with_bind "select asdf from footest where asdf = :asdf" -bind {asdf 1}]
    incr count [db_string db-api-acceptance-test_select_asdf_from_footest_work_normally_with_setId "select asdf from footest where asdf = :asdf" -bind $setId]

    if { $count != 4 } { report_error "db_string did not correctly get value" }

    # work normally while selecting multiple columns
    set count 0
    set asdf 1
    incr count [db_string dp_api_acceptance_test_select_2_from_footest_where_asdf_is_1 "select 2 as jkl, asdf from footest where asdf = 1"]
    incr count [db_string dp_api_acceptance_test_select_2_from_footest_where_asdf_is_something "select 2 as jkl, asdf from footest where asdf = :asdf"]
    incr count [db_string db_api_acceptance_test_select_2_from_footest_where_bind "select 2 as jkl, asdf from footest where asdf = :asdf" -bind {asdf 1}]
    incr count [db_string db_api_acceptance_test_select_2_from_footest_wehre_setId "select 2 as jkl, asdf from footest where asdf = :asdf" -bind $setId]

    if { $count != 8 } { report_error "db_string did grab first column for returned value" }

    db_abort_transaction
} on_error {

}


## db_list

db_transaction {

    db_abort_transaction
} on_error {
}

## db_list_of_lists

db_transaction {

    db_abort_transaction
} on_error {
}


## db_exec_plsql
db_transaction {
    db_dml db_api_acceptance_test_insert_into_footest_value_of_number_1 "insert into footest values(1)"
    db_dml db_api_acceptance_test_insert_into_footest_value_of_number_2 "insert into footest values(2)"
    db_dml db_api_acceptance_test_insert_into_footest_value_of_number_3 "insert into footest values(3)"
    set count [db_exec_plsql unused "BEGIN select count(*) into :1 from footest; END;"]
    if { $count != "3" } { report_error "db_exec_plsql did not return returned value" }
    db_abort_transaction
} on_error {

}

set correct_p 0
catch { [db_exec_plsql db_api_acceptance_test_plsql_exec "BEGIN select * into :1 from footest; END;"] } correct_p

if { $correct_p == "0" } {
    report_error "db_exec_plsql did not propagate error correctly"
}



## db_release_unused_handles
db_transaction {
    db_dml db_api_acceptance_test_insert_into_footest_values_of_1_yet_again "insert into footest values(1)"
    db_dml db_api_acceptance_test_insert_into_footest_values_of_2_yet_again "insert into footest values(2)"
    db_dml db_api_acceptance_test_insert_into_footest_values_of_3_yet_again "insert into footest values(3)"

    db_foreach db_api_acceptance_test_get_everything_from_footest {
	select * from footest
    } {
	if { $asdf == 2 } {
	    db_foreach db_api_test_get_everything_from_footest_get_just_asdf {
		select asdf as jkl from footest
	    } {
		if {$jkl == 2} {
		    db_release_unused_handles
		    break
		}
	    }
	}
	db_release_unused_handles
    }
    db_abort_transaction
} on_error {
}

    
## db_null
db_transaction {
    db_dml db_api_acceptance_test_delete_from_footest_without_anything_else "delete from footest"
    db_dml db_api_acceptance_test_insert_into_footest_values_of_asdf_with_bind_and_some_other_stuff "insert into footest values (:asdf)" -bind [list asdf [db_null]]
    if { [db_string db_api_acceptance_test_select_count_from_footest "select count(*) from footest where asdf is null"] != 1} {
	report_error "db_null failed to insert null"
    }
    db_abort_transaction
} on_error {
}

## db_nullify_empty_string
db_transaction {
    db_dml dp_api_acceptance_test_delete_from_bartest "delete from bartest"
    db_dml dp_api_acceptance_test_insert_into_bartest_with_asdf "insert into bartest values (:asdf)" -bind [list asdf [db_nullify_empty_string a]]
    if { [db_string db_api_acceptance_test_select_count_from_bartest_where_asdf_is_a "select count(*) from bartest where asdf = 'a'"] != 1} {
	report_error "db_nullify_empty_string failed to insert null when given null input"
    }
    db_dml dp_api_acceptance_test_insert_into_bartest_with_values_entered_through_asdf "insert into bartest values (:asdf)" -bind [list asdf [db_nullify_empty_string ""]]
    if { [db_string dp_api_acceptance_test_get_count_from_bartest "select count(*) from bartest where asdf is null"] != 1} {
	report_error "db_nullify_empty_string inserted null inappropriately"
    }
} on_error {
}

## db_with_handle
db_with_handle db {
    db_dml  db_api_acceptance_remove_from_footest "delete from footest"
    db_1row db_api_acceptance_obtain_sysdate "select sysdate from dual"
}

doc_return 200 text/plain "success"


