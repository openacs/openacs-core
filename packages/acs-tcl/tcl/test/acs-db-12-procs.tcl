ad_library {

    Tests for SQL function stub discovery.

}

aa_register_case \
    -cats {api smoke} \
    -procs {::acs::db::postgresql get_all_package_functions} \
    acs_db__postgresql_stub_arity {
        Only the overload with the arity recorded in acs_function_args
        can supply a PostgreSQL function stub.
    } {
        if {[db_driverkey ""] ne "postgresql"} {
            aa_log "PostgreSQL test"
            return
        }

        try {
            ::acs::dc transaction {
                ::acs::dc get_value dbqd..NULL {
                    select define_function_args('aa_stub_arity__probe','value')
                }
                ::acs::dc dml dbqd..NULL {
                    create function pg_temp.aa_stub_arity__probe(value integer, extra integer)
                    returns integer language sql as 'select $1'
                }
                ::acs::dc dml dbqd..NULL {
                    create function pg_temp.aa_stub_arity__probe()
                    returns integer language sql as 'select 0'
                }

                set matches {}
                foreach entry [::acs::dc get_all_package_functions] {
                    if {[lrange $entry 0 1] eq {AA_STUB_ARITY PROBE}} {
                        lappend matches [dict get [lindex $entry 2] types]
                    }
                }
                aa_equals "Other arities cannot supply a stub" $matches {}

                ::acs::dc dml dbqd..NULL {
                    create function pg_temp.aa_stub_arity__probe(value text)
                    returns text language sql as 'select $1'
                }
                set matches {}
                foreach entry [::acs::dc get_all_package_functions] {
                    if {[lrange $entry 0 1] eq {AA_STUB_ARITY PROBE}} {
                        lappend matches [dict get [lindex $entry 2] types]
                    }
                }
                aa_equals "The exact arity supplies the stub" $matches {text}

                error "Rollback test fixtures" "" {OPENACS TEST ROLLBACK}
            }
        } trap {OPENACS TEST ROLLBACK} {} {
            # Expected rollback.
        }
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
