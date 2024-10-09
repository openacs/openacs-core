ad_library {

    test db_* procs
    @author Keith Paskett
    @creation-date 2020-04-25

}

aa_register_case \
    -procs db_get_quote_indices \
    -cats {api} \
    db_get_quote_indices {
        Test the proc db_get_quote_indices.

        @author Peter Marklund
} {
    aa_equals "" [db_get_quote_indices {'a'}] {0 2}
    aa_equals "" [db_get_quote_indices {'a''}] {}
    aa_equals "" [db_get_quote_indices {'a'a'a'}] {0 2 4 6}
    aa_equals "" [db_get_quote_indices {a'b'c'd''s'}] {1 3 5 10}
    aa_equals "" [db_get_quote_indices {'}] {}
    aa_equals "" [db_get_quote_indices {''}] {}
    aa_equals "" [db_get_quote_indices {a''a}] {}
    aa_equals "" [db_get_quote_indices {a'b'a}] {1 3}
    aa_equals "" [db_get_quote_indices {'a''b'}] {0 5}
}

aa_register_case \
    -cats {smoke} \
    db_quoting {
        Try to break the db quoting by feeding weird stuff to it.
    } {

        #
        # Checking base essentials: PostgreSQL does not allow embedded
        # NUL character.
        #
        set data "a\x00b"
        aa_true "Attempting to sneak-in invalid data via bind values [ns_urlencode $data]" [catch {
            db_string via_bindvar {select :data from dual}
        }]

        aa_true "Attempting to sneak-in invalid data via quoted value data [ns_urlencode $data]" [catch {
            db_string via_dbquote [subst {select [ns_dbquotevalue $data] from dual}]
        }]

        #
        # The following checks do not introduce anything new, but come
        # from real-world intrusion detection ... although the tests
        # look silly to me, since PostgreSQL ignores everything after
        # the NUL character.
        #
        set strings {
            "I contain the null \u0000character"
            "\u0000"
            "\u0000',(select 1 from dual)"
            "\u0000'',(select 1 from dual)"
            "\u0000''',(select 1 from dual)"
            "\u0000''',(select 1 from dual)'"
        }

        foreach data $strings {
            set error_p [catch {
                db_string q {select :data from dual}
            } errmsg]
            aa_true "Quoting the test data should fail: $errmsg" $error_p
        }
    }

aa_register_case \
    -cats {db smoke production_safe} \
    -procs {
        db_foreach

        db_list_of_ns_sets
        db_release_unused_handles
        db_qd_replace_sql
    } \
    db__db_foreach {
        Checks that db_foreach works as expected
    } {
        set results [list]
        db_foreach query {SELECT a FROM (VALUES (1), (2), (3), (4), (5), (6), (7)) AS X(a)} {
            lappend results $a
        }
        aa_equals "db_foreach collects correct values from query" \
            [list 1 2 3 4 5 6 7] \
            $results

        set results ""
        db_foreach query {select 1 from dual where 1 = 2} {
            set results "found"
        } else {
            set results "not found"
        }
        aa_equals "db_foreach executes the 'no row' code block using the 'else' syntax" \
            "not found" \
            $results

        set results ""
        db_foreach query {select 1 from dual where 1 = 2} {
            set results "found"
        } if_no_rows {
            set results "not found"
        }
        aa_equals "db_foreach executes the 'no row' code block using the 'if_no_rows' syntax" \
            "not found" \
            $results

        # 3 columns
        set results ""
        db_foreach query {select * from (values ('a1','b1','c 1')) as X(a,b,c)} {
            lappend results [list a $a b $b c $c]
        }
        aa_equals "db_foreach with three columns instvars" "{a a1 b b1 c {c 1}}" $results

        set results ""
        db_foreach query {select * from (values ('a1','b1','c 1')) as X(a,b,c)} \
            -column_array things {
                lappend results [lsort [array get things]]
            }
        aa_equals "db_foreach with three columns" "{a a1 b b1 c {c 1}}" $results

        # 4 columns
        set results ""
        db_foreach query {select * from (values ('a1','b1','c 1','d1')) as X(a,b,c,d)} {
            lappend results [list a $a b $b c $c d $d]
        }
        aa_equals "db_foreach with fopur columns instvars" "{a a1 b b1 c {c 1} d d1}" $results

        set results ""
        db_foreach query {select * from (values ('a1','b1','c 1','d1')) as X(a,b,c,d)} \
            -column_array things {
                lappend results [lsort [array get things]]
            }
        aa_equals "db_foreach with four columns" "{a a1 b b1 c {c 1} d d1}" $results

        set results ""
        db_foreach query {
            select *
            from (values
                  ('a1','b1','c 1','d1'),
                  ('a2','b2','c 2','d2')
                  ) as X(a,b,c,d)
        } -column_set set_things {
            lappend results [lsort [ns_set array $set_things]]
        }
        aa_equals "db_foreach with four columns" \
            $results \
            {{a a1 b b1 c {c 1} d d1} {a a2 b b2 c {c 2} d d2}}

    }

aa_register_case \
    -cats {api db} \
    -procs {
        db_flush_cache
        db_list
        db_list_of_lists
        db_multirow
        db_0or1row
        db_string

        db_list_of_ns_sets
        db_release_unused_handles
    } \
    db__caching {
        test db_* API caching
    } {

        # Check db_string caching

        # Check that cached and non-cached calls return the same value.  We need to
        # check the caching API call twice, once to fill the cache and return the
        # value, and again to see that the call returns the proper value from the
        # cache.  This series ends by testing the flushing of db_cache_pool with an
        # exact pattern.

        set not_cached \
            [db_string test1 {select first_names from persons where person_id = 0}]
        aa_equals "Test that caching and non-caching db_string call return same result" \
            [db_string -cache_key test1 test1 {select first_names from persons where person_id = 0}] \
            $not_cached
        aa_true "Test1 cached value found." \
            ![catch {ns_cache get db_cache_pool test1} errmsg]
        aa_equals "Test that cached db_string returns the right value from the cache" \
            [db_string -cache_key test1 test1 {select first_names from persons where person_id = 0}] \
            $not_cached
        db_flush_cache -cache_key_pattern test1
        aa_true "Flush of test1 from cache using the exact key" \
            [catch {ns_cache get db_cache_pool test1} errmsg]

        # Check that cached and non-cached calls return the same default if no value
        # is returned by the query.  This series ends by testing the flushing of the
        # entire db_cache_pool cache.

        set not_cached \
            [db_string test2 {select first_names from persons where person_id=1 and person_id=2} \
                -default foo]
        aa_equals "Test that caching and non-caching db_string call return same default value" \
            [db_string -cache_key test2 test2 {select first_names from persons where person_id=1 and person_id=2} \
                -default foo] \
            $not_cached
        aa_true "Test2 cached value found." \
            ![catch {ns_cache get db_cache_pool test2} errmsg]
        aa_equals "Test that caching and non-caching db_string call return same default value" \
            [db_string -cache_key test2 test2 {select first_names from persons where person_id=1 and person_id=2} \
                -default foo] \
            $not_cached
        db_flush_cache
        aa_true "Flush of test2 by flushing entire pool" \
            [catch {ns_cache get db_cache_pool test2} errmsg]

        # Check that cached and non-cached calls return an error if the query returns
        # no data and no default is supplied.  This series ends by testing cache flushing
        # by "string match" pattern.

        aa_true "Uncached db_string call returns error if query returns no data" \
            [catch {db_string test3 "select first_names from persons where person_id=1 and person_id=2"}]
        aa_true "Cached db_string call returns error if query returns no data" \
            [catch {db_string -cache_key test3 test3 "select first_names from persons where person_id=1 and person_id=2"}]
        aa_true "db_string call returns error if caching call returned error" \
            [catch {db_string -cache_key test3 test3 "select first_names from persons where person_id=1 and person_id=2"}]
        db_flush_cache -cache_key_pattern tes*3
        aa_true "Flush of test3 from cache using pattern" \
            [catch {ns_cache get db_cache_pool test3} errmsg]

        # Check db_list caching

        set not_cached \
            [db_list test4 {select first_names from persons where person_id = 0}]
        aa_equals "Test that caching and non-caching db_list call return same result" \
            [db_list -cache_key test4 test4 {select first_names from persons where person_id = 0}] \
            $not_cached
        aa_true "Test4 cached value found." \
            ![catch {ns_cache get db_cache_pool test4} errmsg]
        aa_equals "Test that cached db_list returns the right value from the cache" \
            [db_list -cache_key test4 test4 {select first_names from persons where person_id = 0}] \
            $not_cached
        db_flush_cache

        # Check db_list_of_lists caching

        set not_cached \
            [db_list_of_lists test5 {select * from persons where person_id = 0}]
        aa_equals "Test that caching and non-caching db_list_of_lists call return same result" \
            [db_list_of_lists -cache_key test5 test5 {select * from persons where person_id = 0}] \
            $not_cached
        aa_true "Test5 cached value found." \
            ![catch {ns_cache get db_cache_pool test5} errmsg]
        aa_equals "Test that cached db_list_of_lists returns the right value from the cache" \
            [db_list_of_lists -cache_key test5 test5 {select * from persons where person_id = 0}] \
            $not_cached
        db_flush_cache

        # Check db_multirow caching

        db_multirow test6 test6 {select * from persons where person_id = 0}
        set not_cached \
            [list test6:rowcount test6:columns [array get test6:1]]
        db_multirow -cache_key test6 test6 test6 {select * from persons where person_id = 0}
        set cached \
            [list test6:rowcount test6:columns [array get test6:1]]
        aa_equals "Test that caching and non-caching db_multirow call return same result" \
            $cached $not_cached
        aa_true "Test6 cached value found." \
            ![catch {ns_cache get db_cache_pool test6} errmsg]
        db_multirow -cache_key test6 test6 test6 {select * from persons where person_id = 0}
        set cached \
            [list test6:rowcount test6:columns [array get test6:1]]
        aa_equals "Test that cached db_multirow returns the right value from the cache" \
            $cached $not_cached
        db_flush_cache

        # Check db_0or1row caching

        set not_cached \
           [db_0or1row test7 {select * from persons where person_id = 0} -column_array test7]
        lappend not_cached [array get test7]
        set cached \
            [db_0or1row -cache_key test7 test7 {select * from persons where person_id = 0} -column_array test7]
        lappend cached [array get test7]
        aa_equals "Test that caching and non-caching db_0or1row call return same result for 1 row" \
            $cached $not_cached
        aa_true "Test7 cached value found." \
            ![catch {ns_cache get db_cache_pool test7} errmsg]
        set cached \
            [db_0or1row -cache_key test7 test7 {select * from persons where person_id = 0} -column_array test7]
        lappend cached [array get test7]
        aa_equals "Test that cached db_0or1row returns the right value from the cache for 1 row" \
        $cached $not_cached
        db_flush_cache

        # Check db_0or1row caching returns 0 if query returns no values

        set not_cached \
           [db_0or1row test8 {select * from persons where person_id=1 and person_id=2} -column_array test8]
        set cached \
            [db_0or1row -cache_key test8 test8 {select * from persons where person_id=1 and person_id=2} -column_array test8]
        aa_equals "Test that caching and non-caching db_0or1row call return same result for 0 rows" \
            $cached $not_cached
        aa_true "Test8 cached value found." \
            ![catch {ns_cache get db_cache_pool test8} errmsg]
        set cached \
            [db_0or1row -cache_key test8 test8 {select * from persons where person_id=1 and person_id=2} -column_array test8]
        aa_equals "Test that cached db_0or1row returns the right value from the cache for 0 rows" \
            $cached $not_cached
        db_flush_cache

        # Won't check db_1row because it just calls db_0or1row

}

aa_register_case \
    -procs {
        db_bind_var_substitution
        db_type

        db_exec_plsql
        db_qd_replace_sql
    } \
    -cats {api} \
    db_bind_var_substitution {
        Test the proc db_bind_var_substitution.

        @author Peter Marklund
} {

    # DRB: Not all of these test cases work for Oracle (select can't be used in
    # db_exec_plsql) and bindvar substitution is done by Oracle, not the driver,
    # anyway so there's not much point in testing.   These tests really test
    # Oracle bindvar emulation, in other words...

    if { [db_type] ne "oracle" } {
        set sql {to_char(fm.posting_date, 'YYYY-MM-DD HH24:MI:SS')}
        aa_equals "don't subst bind vars in quoted date" [db_bind_var_substitution $sql {SS 3 MI 4}] $sql

        set sql {to_char(fm.posting_date, :SS)}
        aa_equals "don't subst bind vars in quoted date" [db_bind_var_substitution $sql {SS 3 MI 4}] {to_char(fm.posting_date, '3')}

        set sql {to_char(fm.posting_date, don''t subst ':SS', do subst :SS )}
        aa_equals "don't subst bind vars in quoted date" [db_bind_var_substitution $sql {SS 3 MI 4}] {to_char(fm.posting_date, don''t subst ':SS', do subst '3' )}


        set SS 3
        set db_value [db_exec_plsql test_bind {
            select ':SS'
        }]
        aa_equals "db_exec_plsql should not bind quoted var" $db_value ":SS"

        set db_value [db_exec_plsql test_bind {
            select :SS
        }]
        aa_equals "db_exec_plsql bind not quoted var" $db_value "3"
    }
}

aa_register_case \
    -cats {api db smoke} \
    -procs {
        db_abort_transaction
        db_dml
        db_transaction
        db_string
        db_qd_replace_sql
    } \
    db__transaction {
        Test db_transaction
} {

    # Create a temporary table for testing
    aa_silence_log_entries -severities {notice error} {
        catch {db_dml remove_table {drop table tmp_db_transaction_test}}
    }
    db_dml new_table {create table tmp_db_transaction_test (a integer constraint tmp_db_transaction_test_pk primary key, b integer)}

    aa_equals "Test we can insert a row in a db_transaction clause" \
        [catch {db_transaction {db_dml test1 {insert into tmp_db_transaction_test(a,b) values (1,2)}}}] 0

    aa_equals "Verify clean insert worked" \
        [db_string check1 {select a from tmp_db_transaction_test} -default missing] 1

    # verify the on_error clause is called
    set error_called 0
    aa_silence_log_entries -severities error {
        catch {db_transaction { set foo } on_error {set error_called 1}} errMsg
    }
    aa_equals "error clause invoked on Tcl error" \
        $error_called 1

    # Check that the Tcl error propagates up from the code block
    set error_p [catch {db_transaction { error "BAD CODE"}} errMsg]

    aa_equals "Tcl error propagates to errMsg from code block" \
        $errMsg "Transaction aborted: BAD CODE"

    # Check that the Tcl error propagates up from the on_error block
    set error_p [catch {db_transaction {set foo} on_error { error "BAD CODE"}} errMsg]

    aa_equals "Tcl error propagates to errMsg from on_error block" \
        $errMsg "BAD CODE"


    # Check a dup insert fails and the primary key constraint comes
    # back in the error message.
    aa_silence_log_entries -severities {notice error} {
        set error_p [catch {db_transaction {db_dml test2 {insert into tmp_db_transaction_test(a,b) values (1,2)}}} errMsg]
    }

    aa_true "error thrown inserting duplicate row" $error_p
    aa_true "error message contains constraint violated" [string match -nocase {*tmp_db_transaction_test_pk*} $errMsg]

    # check a sql error calls on_error clause
    set error_called 0
    aa_silence_log_entries -severities {notice error} {
        set error_p [catch {db_transaction {db_dml test3 {insert into tmp_db_transaction_test(a,b) values (1,2)}} on_error {set error_called 1}} errMsg]
    }

    aa_false "no error thrown with on_error clause" $error_p
    aa_equals "error message empty with on_error clause" \
        $errMsg {}

    # Check on explicit aborts
    set error_p [catch {
        db_transaction {
            db_dml test4 {
                insert into tmp_db_transaction_test(a,b) values (2,3)
            }
            db_abort_transaction
        }
    } errMsg]

    aa_true "error thrown with explicit abort" $error_p
    aa_equals "row not inserted with explicit abort" \
        [db_string check4 {select a from tmp_db_transaction_test where a = 2} -default missing] "missing"

    # Check a failed sql command can do sql in the on_error block
    set sqlok {}
    aa_silence_log_entries -severities {notice error} {
        set error_p [catch {
            db_transaction {
                db_dml test5 {
                    insert into tmp_db_transaction_test(a,b) values (1,2)
                }
            } on_error {
                set sqlok [db_string check5 {select a from tmp_db_transaction_test where a = 1}]
            }
        } errMsg]
    }

    aa_false "No error thrown doing sql in on_error block" $error_p
    aa_equals "Query succeeds in on_error block" \
        $sqlok 1


    # Check a failed transactions dml is rolled back in the on_error block
    aa_silence_log_entries -severities {error} {
        set error_p [catch {
            db_transaction {
                error "BAD CODE"
            } on_error {
                db_dml test6 {
                    insert into tmp_db_transaction_test(a,b) values (3,4)
                }
            }
        } errMsg]
    }

    aa_false "No error thrown doing insert dml in on_error block" $error_p
    aa_equals "Insert in on_error block rolled back, code error" \
        [db_string check6 {select a from tmp_db_transaction_test where a = 3} -default {missing}] missing

    # Check a failed transactions dml is rolled back in the on_error block
    aa_silence_log_entries -severities {notice error} {

        set error_p [catch {
            db_transaction {
                db_dml test7 {
                    insert into tmp_db_transaction_test(a,b) values (1,2)
                }
            } on_error {
                db_dml test8 {
                    insert into tmp_db_transaction_test(a,b) values (3,4)
                }
            }
        } errMsg]
    }

    aa_false "No error thrown doing insert dml in on_error block" $error_p
    aa_equals "Insert in on_error block rolled back, sql error" \
        [db_string check8 {select a from tmp_db_transaction_test where a = 3} -default {missing}] missing


    # check nested db_transactions work properly with clean code
    set error_p [catch {
        db_transaction {
            db_dml test9 {
                insert into tmp_db_transaction_test(a,b) values (5,6)
            }
            db_transaction {
                db_dml test10 {
                    insert into tmp_db_transaction_test(a,b) values (6,7)
                }
            }
        }
    } errMsg]

    aa_false "No error thrown doing nested db_transactions" $error_p
    aa_equals "Data inserted in  outer db_transaction" \
        [db_string check9 {select a from tmp_db_transaction_test where a = 5} -default {missing}] 5
    aa_equals "Data inserted in nested db_transaction" \
        [db_string check10 {select a from tmp_db_transaction_test where a = 6} -default {missing}] 6


    # check error in outer transaction rolls back nested transaction
    set error_p [catch {
        db_transaction {
            db_dml test11 {
                insert into tmp_db_transaction_test(a,b) values (7,8)
            }
            db_transaction {
                db_dml test12 {
                    insert into tmp_db_transaction_test(a,b) values (8,9)
                }
            }
            error "BAD CODE"
        }
    } errMsg]

    aa_true "Error thrown doing nested db_transactions" $error_p
    aa_equals "Data rolled back in outer db_transactions with error in outer" \
        [db_string check11 {select a from tmp_db_transaction_test where a = 7} -default {missing}] missing
    aa_equals "Data rolled back in nested db_transactions with error in outer" \
        [db_string check12 {select a from tmp_db_transaction_test where a = 8} -default {missing}] missing

    # check error in outer transaction rolls back nested transaction
    set error_p [catch {
        db_transaction {
            db_dml test13 {
                insert into tmp_db_transaction_test(a,b) values (9,10)
            }
            db_transaction {
                db_dml test14 {
                    insert into tmp_db_transaction_test(a,b) values (10,11)
                }
                error "BAD CODE"
            }
        }
    } errMsg]

    aa_true "Error thrown doing nested db_transactions: $errMsg" $error_p
    aa_equals "Data rolled back in outer db_transactions with error in nested" \
        [db_string check13 {select a from tmp_db_transaction_test where a = 9} -default {missing}] missing
    aa_equals "Data rolled back in nested db_transactions with error in nested" \
        [db_string check14 {select a from tmp_db_transaction_test where a = 10} -default {missing}] missing

    db_dml drop_table {drop table tmp_db_transaction_test}
}


aa_register_case \
    -cats {api db smoke} \
    -error_level "error" \
    -procs {
        db_dml
        db_foreach
        db_multirow
        db_string
        db_transaction
        template::multirow

        db_list_of_ns_sets
        db_release_unused_handles
        db_qd_replace_sql
    } \
    db__transaction_bug_3440 {

        This tests for the case when a db_ call in a db_multirow in a
        db_transaction, breaks out of the transaction.

} {
    # Not using -rollback option because we don't want to start out in a db_transaction
    aa_run_with_teardown \
        -test_code {

            aa_log "Test Begin"
            aa_log "Create fixture"

            set dml "CREATE TABLE test_tbl1 (id serial, value text)"
            db_dml noxql $dml

            aa_log "Start test section 1"

            db_transaction {
                #
                # Insert an element to the test table
                #
                set dml "INSERT INTO test_tbl1 (value) values('val1') RETURNING id;"
                set row_id [db_string noxql $dml]
                set sql_row_id "SELECT value FROM test_tbl1 where id = :row_id"

                #
                # Retrieve it once.
                #
                set sql "SELECT value FROM test_tbl1 where id = :row_id"
                set res1 [db_string noxql $sql -default "None"]
                aa_equals "New row exists before db_multirow call" $res1 "val1"

                #
                # Run a query returning more than one row in a
                # "db_foreach" loop, performing as well SQL queries
                # and try to get value inserted above after the loop.
                #
                set sql "SELECT privilege FROM acs_privileges fetch first 2 rows only"
                db_foreach noxql $sql {
                    set temp1 [db_string noxql "SELECT 1 FROM dual"]
                    aa_log "... db_foreach got '$temp1'"
                }
                set res2 [db_string noxql $sql_row_id -default "None"]
                aa_equals "New row exists after db_foreach" $res2 "val1"

                #
                # Run a query returning a single row in a
                # "db_multirow" loop, performing as well SQL queries
                # and try to get value inserted above after the loop.
                #
                set sql "SELECT max(privilege) FROM acs_privileges"
                db_multirow -local mrow noxql $sql {
                    # Code executed for each row. Set extended columns, etc.
                    set temp1 [db_string noxql "SELECT 1 FROM dual"]
                }
                set res2 [db_string noxql $sql_row_id -default "None"]
                aa_equals "New row exists after db_multirow with 1 tuple" $res2 "val1"

                #
                # Run a query returning more than a row in a
                # "db_multirow" loop, performing as well SQL queries
                # and try to get value inserted above after the loop.
                #
                set sql "SELECT privilege FROM acs_privileges fetch first 2 rows only"
                db_multirow -local mrow noxql $sql {
                    # Code executed for each row. Set extended columns, etc.
                    set temp1 [db_string noxql "SELECT 1 FROM dual"]
                }

                # Asof acs-tcl 5.10.0d31
                # If db_multirow above is limited to 1 row, the following succeeds.
                # If the db_multirow has more than 1 row, it fails.
                set res2 [db_string noxql $sql_row_id -default "None"]
                aa_equals "New row exists after db_multirow with 2 tuples" $res2 "val1"

            }
            aa_log "Start test section 2"

            #
            # Create a multirow no entries and append a row "manually"
            # For details, see # https://openacs.org/bugtracker/openacs/bug?bug_number=3441
            #
            db_multirow person_mr1 noxql {
                SELECT person_id, first_names, last_name
                FROM persons WHERE false
            }

            aa_equals "have empty multirow" [template::multirow size person_mr1] 0
            template::multirow append person_mr1 1234 “Ed” “Grooberman”
            aa_equals "have one tuple in multirow" [template::multirow size person_mr1] 1

            aa_equals "columns empty" [template::multirow columns person_mr1] \
                "person_id first_names last_name"

            set user_id [ad_conn user_id]
            db_multirow person_mr2 noxql {
                SELECT person_id, first_names, last_name
                FROM persons where person_id = :user_id
            }
            aa_equals "columns nonempty" [template::multirow columns person_mr2] \
                "person_id first_names last_name"

            aa_log "Test End"

    } -teardown_code {
        set dml "DROP TABLE test_tbl1"
        db_dml noxql $dml
        # this is an optional parameter if there is code that should run to clean things up.
        # It will run whether or not the -test_code succeeds, and runs after the DB transaction has been rolled back.
    }
}; # db_transaction_bug_3440

aa_register_case -error_level warning -cats {
        db
        production_safe
    } -procs {
        db_type
        db_string
    } nullchar {
        Null character is properly translated in a round trip through the
        database engine.

        PostgreSQL only.

        @author Nathan Coulter
        @creation-date 2020-08-20
} {
    set queries {}
    #
    # The NUL character is not allowed in plain data for PostgreSQL.
    #
    #set val1 \x00
    #set queries {
    #    variable {sql {select :val1} status 1}
    #}
    switch [db_type] {
       postgresql {
           lappend queries literal {sql {select '\x00'::bytea} status 0}
       }
    }
    foreach {type query} $queries {
        set status [catch { db_string noxql [dict get $query sql]} value copts]
        aa_equals [list $type {SQL executed successfully?}] $status [dict get $query status]
        aa_true [list $type {Value is the null character?} $value] {$value eq {\x00}}
    }
}

aa_register_case \
    -cats {api db smoke} \
    -error_level "error" \
    -procs {
        db_string
    } \
    db__string {

        This tests db_string with various arguments.

    } {
        set r [db_string x {select object_id from acs_objects where object_id = -1}]
        aa_true "constant query" {$r == -1}

        set x -1
        set r [db_string x {select object_id from acs_objects where object_id = :x}]
        aa_true "query with bind variable from environment" {$r == -1}

        set r [db_string x {select object_id from acs_objects where object_id = :a} -bind {a -1}]
        aa_true "query with provided bind variable from var list" {$r == -1}

        set s [ns_set create binds b -1]
        set r [db_string x {select object_id from acs_objects where object_id = :b} -bind $s]
        aa_true "query with provided bind variable from ns_set" {$r == -1}

        set r [db_string x {select object_id from acs_objects where object_id = -4711} -default -1]
        aa_true "failing query with default" {$r == -1}
    }

aa_register_case \
    -cats {api db smoke} \
    -error_level "error" \
    -procs {
        db_list
        db_list_of_lists

        db_list_of_ns_sets
    } \
    db__list_variants {

        This tests db_list-variants with various arguments.

    } {
        foreach cmd {db_list db_list_of_lists} {
            set r [$cmd x {select object_id from acs_objects where object_id = -1}]
            aa_true "$cmd constant query" {$r == -1}

            set x -1
            set r [$cmd x {select object_id from acs_objects where object_id = :x}]
            aa_true "$cmd query with bind variable from environment" {$r == -1}

            set r [$cmd x {select object_id from acs_objects where object_id = :a} -bind {a -1}]
            aa_true "$cmd query with provided bind variable from var list" {$r == -1}

            set s [ns_set create binds b -1]
            set r [$cmd x {select object_id from acs_objects where object_id = :b} -bind $s]
            aa_true "$cmd query with provided bind variable from ns_set" {$r == -1}
        }
        #
        # Test combinations of "-columns_var" and "-with_headers" of db_list_of_lists
        #
        foreach {optionSet expected} {
            {}                                  {1 0}
            {-columns_var __cols}               {1 1}
            {-with_headers}                     {2 0}
            {-columns_var __cols -with_headers} {2 1}
        } {
            set r [db_list_of_lists {*}$optionSet ..x {
                select object_id, package_id from acs_objects where object_id = -1
            }]
            aa_equals "db_list_of_lists $optionSet" \
                [list [llength $r] [info exists __cols]] \
                $expected
            unset -nocomplain __cols
        }
    }

aa_register_case \
    -cats {api db smoke} \
    -error_level "error" \
    -procs {
        db_0or1row

        db_with_handle
        db_exec
    } \
    db__0or1row {

        This tests db_0or1row with various arguments.

    } {
        set cmd db_0or1row

        set r [$cmd x {select object_id from acs_objects where object_id = -1}]
        aa_true "$cmd constant query" {$r == 1}
        aa_true "$cmd returns variable" {[info exists object_id]}
        unset object_id

        set r [$cmd x {select object_id from acs_objects where object_id = -4711}]
        aa_true "$cmd constant query" {$r == 0}
        aa_false "$cmd returns variable" {[info exists object_id]}

        set x -1
        set r [$cmd x {select object_id from acs_objects where object_id = :x}]
        aa_true "$cmd query with bind variable from environment" {$r == 1}
        unset object_id

        set r [$cmd x {select object_id from acs_objects where object_id = :a} -bind {a -1}]
        aa_true "$cmd query with provided bind variable from var list" {$r == 1}
        unset object_id

        set s [ns_set create binds b -1]
        set r [$cmd x {select object_id from acs_objects where object_id = :b} -bind $s]
        aa_true "$cmd query with provided bind variable from ns_set" {$r == 1}
        unset object_id

        set s [ns_set create binds b -1]
        set r [$cmd x {select object_id from acs_objects where object_id = :b} -bind $s -column_array arr]
        aa_true "$cmd query with provided bind variable from ns_set" {$r == 1}
        aa_true "$cmd returns column_array" {[array exists arr]}
        aa_equals "$cmd returns column_array value" [array get arr] "object_id -1"
        aa_false "$cmd returns variable" {[info exists object_id]}
        unset -nocomplain arr

        set s [ns_set create binds b -1]
        set r [$cmd x {select object_id from acs_objects where object_id = :b} -bind $s -column_set n]
        aa_true "$cmd query with provided bind variable from ns_set" {$r == 1}
        aa_equals "$cmd returns column_ns_set value" [ns_set array $n] "object_id -1"
        aa_false "$cmd returns variable" {[info exists object_id]}
    }

aa_register_case \
    -cats {api db smoke} \
    -error_level "error" \
    -procs {
        db_1row

        db_0or1row
        db_with_handle
        db_exec
    } \
    db__1row {

        This tests db_1row with various arguments.

    } {
        set cmd db_1row

        set r [$cmd x {select object_id from acs_objects where object_id = -1}]
        aa_true "$cmd returns variable" {[info exists object_id]}
        unset object_id

        set x -1
        set r [$cmd x {select object_id from acs_objects where object_id = :x}]
        aa_true "$cmd returns variable bind variable from environment" {[info exists object_id]}
        unset object_id

        set r [$cmd x {select object_id from acs_objects where object_id = :a} -bind {a -1}]
        aa_true "$cmd with bind variable from var list returns variable" {[info exists object_id]}
        unset object_id

        set s [ns_set create binds b -1]
        set r [$cmd x {select object_id from acs_objects where object_id = :b} -bind $s]
        aa_true "$cmd with provided bind variable from ns_set returns variable" {[info exists object_id]}
        unset object_id

        set s [ns_set create binds b -1]
        set r [$cmd x {select object_id from acs_objects where object_id = :b} -bind $s -column_array arr]
        aa_true "$cmd returns column_array" {[array exists arr]}
        aa_equals "$cmd returns column_array value" [array get arr] "object_id -1"
        aa_false "$cmd returns variable" {[info exists object_id]}
        unset -nocomplain arr

        set s [ns_set create binds b -1]
        set r [$cmd x {select object_id from acs_objects where object_id = :b} -bind $s -column_set n]
        aa_equals "$cmd returns column_ns_set value" [ns_set array $n] "object_id -1"
        aa_false "$cmd returns variable" {[info exists object_id]}
    }

aa_register_case -cats {
    api
    production_safe
} -procs {
    db_boolean
} db_boolean {
    Test the db_boolean proc.
} {
    set bool_true {t 1 -1 true 1234 yes TRUE YES on ON}
    set bool_false {f 0 false no FALSE NO off OFF Off}
    foreach value $bool_true {
        aa_equals "Is $value true?" [db_boolean $value] "t"
    }
    foreach value $bool_false {
        aa_equals "Is $value false?" [db_boolean $value] "f"
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
