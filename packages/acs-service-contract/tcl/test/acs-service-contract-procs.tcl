ad_library {
  Register acs-automated-testing test cases for acs-service-contract
  package on server startup.

  @author Simon Carstensen
  @creation-date 2003-09-10
  @cvs-id $Id$
}

aa_register_case \
    -procs {
        acs_sc::contract::new
        acs_sc::contract::new_from_spec
        acs_sc::contract::get_operations
        acs_sc::contract::delete

        acs_sc::contract::operation::new
        acs_sc::contract::operation::delete

        acs_sc::impl::get
        acs_sc::impl::new_from_spec
        acs_sc::impl::new
        acs_sc::impl::delete
        acs_sc::impl::get_options

        acs_sc::impl::binding::new

        acs_sc::impl::alias::new

        acs_sc::msg_type::new
        acs_sc::msg_type::delete

        acs_sc_binding_exists_p

        auth::local::authentication::Authenticate
        auth::local::authentication::GetParameters

        apm_mark_files_for_reload
    } \
    acs_sc_impl_new_from_spec {
    Test the acs_sc::impl::new_from_spec proc.
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {

            set spec {
                name "foo_contract"
                description "Blah blah blah blah"
                operations {
                    Authenticate {
                        description {
                            Validate this username/password combination, and return the result.
                            Valid auth_status codes are 'ok', 'no_account', 'bad_password', 'auth_error', 'failed_to_connect'.
                            The last, 'failed_to_connect', is reserved for communications or implementation errors.
                            auth_message is a human-readable explanation of what went wrong, may contain HTML.
                            Only checked if auth_status is not ok.
                            Valid account_status codes are 'ok' and 'closed'.
                            account_message may be supplied regardless of account_status, and may contain HTML.
                        }
                        input {
                            username:string
                            password:string
                            parameters:string,multiple
                        }
                        output {
                            auth_status:string
                            auth_message:string
                            account_status:string
                            account_message:string
                        }
                    }
                    GetParameters {
                        description {
                            Get an arraay-list of the parameters required by this service contract implementation.
                        }
                        output {
                            parameters:string,multiple
                        }
                    }
                }
            }

            set contract_id [acs_sc::contract::new_from_spec -spec $spec]

            set spec {
                contract_name "foo_contract"
                owner "acs-service-contract"
                name "foo"
                pretty_name "Foo Driver"
                aliases {
                    Authenticate auth::local::authentication::Authenticate
                    GetParameters auth::local::authentication::GetParameters
                }
            }

            set impl_id [acs_sc::impl::new_from_spec -spec $spec]

            acs_sc::impl::get -impl_id $impl_id -array impl

            aa_equals "pretty_name did not get inserted correctly" $impl(impl_pretty_name) "Foo Driver"

            aa_equals "acs_sc::contract::get_operations returns expected" \
                [lsort [acs_sc::contract::get_operations -contract_name "foo_contract"]] \
                {Authenticate GetParameters}

            aa_log "Delete Authenticate operation"
            acs_sc::contract::operation::delete \
                -contract_name foo_contract \
                -operation_name Authenticate

            aa_equals "acs_sc::contract::get_operations returns expected" \
                [acs_sc::contract::get_operations -contract_name "foo_contract"] \
                {GetParameters}

            aa_log "Recreate Authenticate operation"
            acs_sc::contract::operation::new \
                -contract_name foo_contract \
                -operation Authenticate \
                -description {
                    Validate this username/password combination, and return the result.
                    Valid auth_status codes are 'ok', 'no_account', 'bad_password', 'auth_error', 'failed_to_connect'.
                    The last, 'failed_to_connect', is reserved for communications or implementation errors.
                    auth_message is a human-readable explanation of what went wrong, may contain HTML.
                    Only checked if auth_status is not ok.
                    Valid account_status codes are 'ok' and 'closed'.
                    account_message may be supplied regardless of account_status, and may contain HTML.
                } \
                -input {
                    username:string
                    password:string
                    parameters:string,multiple
                } \
                -output {
                    auth_status:string
                    auth_message:string
                    account_status:string
                    account_message:string
                }
            aa_equals "acs_sc::contract::get_operations returns expected" \
                [lsort [acs_sc::contract::get_operations -contract_name "foo_contract"]] \
                {Authenticate GetParameters}

            aa_log "Create Authenticate2 operation"
            acs_sc::contract::operation::new \
                -contract_name foo_contract \
                -operation Authenticate2 \
                -description {
                    Validate this username/password combination, and return the result.
                    Valid auth_status codes are 'ok', 'no_account', 'bad_password', 'auth_error', 'failed_to_connect'.
                    The last, 'failed_to_connect', is reserved for communications or implementation errors.
                    auth_message is a human-readable explanation of what went wrong, may contain HTML.
                    Only checked if auth_status is not ok.
                    Valid account_status codes are 'ok' and 'closed'.
                    account_message may be supplied regardless of account_status, and may contain HTML.
                } \
                -input {
                    username:string
                    password:string
                    parameters:string,multiple
                } \
                -output {
                    auth_status:string
                    auth_message:string
                    account_status:string
                    account_message:string
                }
            aa_equals "acs_sc::contract::get_operations returns expected" \
                [lsort [acs_sc::contract::get_operations -contract_name "foo_contract"]] \
                {Authenticate Authenticate2 GetParameters}

            aa_equals "Getting the implementation options returns expected" \
                [lsort [acs_sc::impl::get_options \
                            -contract_name foo_contract \
                            -empty_label AAA]] \
                [list [list "AAA" ""] [list "Foo Driver" $impl_id]]

            aa_equals "Getting the implementation options returns expected (excluded)" \
                [acs_sc::impl::get_options \
                     -contract_name foo_contract \
                     -empty_label AAA \
                     -exclude_names [list "Foo Driver"]] \
                [list [list "AAA" ""]]

            aa_true "acs_sc_binding_exists_p is true" [acs_sc_binding_exists_p foo_contract foo]

            aa_log "Delete implementation '$impl_id'"
            acs_sc::impl::delete -contract_name foo_contract -impl_name foo
            aa_false "Deletion succeeded" [db_0or1row check {
                select 1 from acs_sc_impls where impl_id = :impl_id
            }]

            aa_false "acs_sc_binding_exists_p is false" [acs_sc_binding_exists_p foo_contract foo]

            aa_log "Delete contract"
            acs_sc::contract::delete -name foo_contract
            aa_false "Contract was deleted" [db_0or1row check {
                select 1 from acs_sc_contracts
                where contract_id = :contract_id
            }]

        }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
