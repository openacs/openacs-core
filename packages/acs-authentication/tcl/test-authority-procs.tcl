ad_library {

    Provide a simply authority named "acs_testing" for creating test
    users during runs of the regression test. This is needed, when a
    site/sub-site runs a registry which does e.g. a synchronized
    registry, where no additional accounts can be created.

    @author Gustaf Neumann
    @creation-date 2018-10-04
}

namespace eval acs::test::auth {}
namespace eval acs::test::auth::registration {}

#####
#
# acs::test::auth
#
#####

ad_proc -private acs::test::auth::install {} {

    Register the service contract implementations for the acs_testing
    authority and update the authority accordingly. Do nothing, when
    the registry exists already.

} {
    set authority_name acs_testing

    if {[auth::authority::get_id -short_name $authority_name] eq ""} {
        ns_log notice "create authority $authority_name"

        set register_impl_id [acs_sc::impl::get_id \
                                  -owner acs-authentication \
                                  -name acs_testing \
                                  -contract auth_registration]
        if {$register_impl_id eq ""} {
            acs::test::auth::registration::register_impl
            set register_impl_id  [acs_sc::impl::get_id \
                                       -owner acs-authentication \
                                       -name acs_testing \
                                       -contract auth_registration]
            ns_log notice "create authority $authority_name => register_impl_id $register_impl_id"
        }

        set auth_impl_id      [acs_sc::impl::get_id -owner acs-authentication -name local -contract auth_authentication]
        set pwd_impl_id       [acs_sc::impl::get_id -owner acs-authentication -name local -contract auth_password]
        set user_info_impl_id [acs_sc::impl::get_id -owner acs-authentication -name local -contract auth_user_info]

        db_transaction {
            array set row [list \
                               short_name        $authority_name \
                               pretty_name       "ACS Automated Testing" \
                               auth_impl_id      $auth_impl_id \
                               pwd_impl_id       $pwd_impl_id \
                               register_impl_id  $register_impl_id \
                               user_info_impl_id $user_info_impl_id \
                              ]
            auth::authority::create -array row
        }
    }
}

ad_proc -private acs::test::auth::registration::register_impl {} {

    Register the 'acs_testing' implementation of the
    'auth_registration' service contract.  We just implement
    "Register" new and reuse the implementations for "GetElements" and
    "GetParameters"

    @return impl_id of the newly created implementation.
} {
    ns_log notice "create registration::register_impl sc"

    set spec {
        contract_name "auth_registration"
        owner "acs-authentication"
        name "acs_testing"
        pretty_name "ACS Automated Testing"
        aliases {
            GetElements   auth::local::registration::GetElements
            Register      acs::test::auth::registration::Register
            GetParameters auth::local::registration::GetParameters
        }
    }
    return [acs_sc::impl::new_from_spec -spec $spec]
}


ad_proc -private acs::test::auth::registration::Register {
    parameters
    username
    authority_id
    first_names
    last_name
    screen_name
    email
    url
    password
    secret_question
    secret_answer
} {

    Implements the "Register" operation of the auth_registration
    service contract for the acs testing authority. This is in essence
    a simplified version of the "local" authority without the
    notifications and confirmation options.

} {
    set result {
        creation_status "ok"
        creation_message {}
        element_messages {}
        account_status "ok"
        account_message {}
        generated_pwd_p 0
    }
    dict set result password $password

    #
    # Set user's password
    #
    set user_id [acs_user::get_by_username -authority_id $authority_id -username $username]
    ad_change_password $user_id $password

    return $result
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
