ad_library {

    test db_* procs
    @author Keith Paskett
    @creation-date 2020-04-25

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
            # Create a multirow woth 0 entries and append a row "manually"
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
    set val1 \x00
    set queries {
       variable {
           select :val1;
       }
    }
    switch [db_type] {
       postgresql {
           lappend queries literal {
               select '\x00'::bytea;
           }
       }
    }
    foreach {type query} $queries {
       set status [catch {
           db_string noxql $query
       } value copts]
       aa_equals [list $type {SQL executed successfully?}] $status 0
        aa_true [list $type {Value is the null character?}] {$value eq "\x00"}
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
