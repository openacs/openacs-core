ad_library {

    Tests for procs in tcl/local-procs.tcl

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        auth::local::authentication::MergeUser
        membership_rel::change_state
        acs_user::get
        acs_user::update
        party::update
    } \
    auth_authentication_implementations {
        Test implementations of the auth_authentication contract
    } {
        aa_run_with_teardown -rollback -test_code {
            set user1 [acs::test::user::create]
            set user2 [acs::test::user::create]

            set user_id1 [dict get $user1 user_id]
            set username1 [dict get $user1 username]
            set email1 [dict get $user1 email]

            set user_id2 [dict get $user2 user_id]
            set username2 [dict get $user2 username]
            set email2 [dict get $user2 email]

            acs_sc::invoke \
                -contract auth_authentication \
                -operation MergeUser \
                -impl local \
                -call_args [list $user_id1 $user_id2 ""]

            set user1_after [acs_user::get -user_id $user_id1]

            aa_equals "Username for user '$user_id1' is as expected" \
                [dict get $user1_after username] merged_${user_id1}_${user_id2}
            aa_equals "Email for user '$user_id1' is as expected" \
                [dict get $user1_after email] merged_${user_id1}_${user_id2}
            aa_equals "Screen name for user '$user_id1' is as expected" \
                [dict get $user1_after screen_name] merged_${user_id1}_${user_id2}
            aa_equals "Member state for user '$user_id1' is as expected" \
                [dict get $user1_after member_state] merged
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        auth::local::password::CanChangePassword
        auth::local::password::CanResetPassword
        auth::local::password::CanRetrievePassword
        auth::local::password::GetParameters
        auth::local::password::ChangePassword
        auth::local::password::ResetPassword
        auth::local::password::RetrievePassword
        ad_check_password
    } \
    auth_password_implementations {
        Test implementations of the auth_password contract
    } {
        aa_stub acs_mail_lite::send {
            set ::auth_password_implementations_to_addr $to_addr
            set ::auth_password_implementations_body $body
        }

        aa_true "CanChangePassword is always true" [acs_sc::invoke \
                                                        -contract auth_password \
                                                        -operation CanChangePassword \
                                                        -impl local \
                                                        -call_args [list ""]]
        aa_true "CanResetPassword is always true" [acs_sc::invoke \
                                                       -contract auth_password \
                                                       -operation CanResetPassword \
                                                       -impl local \
                                                       -call_args [list ""]]
        aa_true "CanRetrievePassword is always true" [acs_sc::invoke \
                                                          -contract auth_password \
                                                          -operation CanRetrievePassword \
                                                          -impl local \
                                                          -call_args [list ""]]

        aa_equals "GetParameters returns nothing" \
            [acs_sc::invoke \
                 -contract auth_password \
                 -operation GetParameters \
                 -impl local] \
            ""

        aa_run_with_teardown -rollback -test_code {
            set user [acs::test::user::create]
            set user_id [dict get $user user_id]
            set old_password [dict get $user password]
            set user [acs_user::get -user_id $user_id]

            set username [dict get $user username]
            set authority_id [dict get $user authority_id]

            aa_section "Changing password"
            set new_password 1234
            acs_sc::invoke \
                -contract auth_password \
                -operation ChangePassword \
                -impl local \
                -call_args [list \
                                $username \
                                $new_password \
                                $old_password \
                                [list] \
                                $authority_id]
            aa_true "Password was changed" [ad_check_password $user_id $new_password]

            aa_section "Resetting password"
            set result [acs_sc::invoke \
                            -contract auth_password \
                            -operation ResetPassword \
                            -impl local \
                            -call_args [list \
                                            $username \
                                            [list] \
                                            $authority_id]]
            set new_password [dict get $result password]
            aa_true "Password was reset" [ad_check_password $user_id $new_password]

            aa_section "Retrieving password"
            acs_sc::invoke \
                -contract auth_password \
                -operation RetrievePassword \
                -impl local \
                -call_args [list $username [list]]
            set email [dict get $user email]
            set password [dict get $user password]
            aa_equals "Email was sent to the user" \
                [dict get $user email] $::auth_password_implementations_to_addr
            set password [db_string query {
                select password from users where user_id = :user_id
            }]
            aa_true "Email contains a link to the password hash" \
                {[string first \
                      [ns_urlencode $password] \
                      $::auth_password_implementations_body] >= 0}
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        auth::local::registration::GetElements
        auth::local::registration::GetParameters
        auth::local::registration::Register
        acs::test::auth::registration::Register
        auth::UseEmailForLoginP
        ad_outgoing_sender
    } \
    auth_registration_implementations {
        Test implementations of the auth_registration contract
    } {
        aa_section auth::local::registration::GetElements

        set kernel_id [ad_acs_kernel_id]
        set subsite_id [subsite::main_site_id]

        set UseEmailForLoginP [parameter::get -boolean -parameter UseEmailForLoginP -package_id $kernel_id -default 1]
        set RegistrationProvidesRandomPasswordP [parameter::get -package_id $subsite_id -parameter RegistrationProvidesRandomPasswordP -default 0]
        set RequireQuestionForPasswordResetP [parameter::get -package_id $kernel_id -parameter RequireQuestionForPasswordResetP -default 0]
        set UseCustomQuestionForPasswordReset [parameter::get -package_id $kernel_id -parameter UseCustomQuestionForPasswordReset -default 0]

        try {
            foreach {use_email_p random_password_p require_question_p use_question_p expected_elements} {
                true true true true {required {email first_names last_name secret_question secret_answer} optional {url}}

                false false true true {required {username email first_names last_name secret_question secret_answer} optional {url password}}

                false false false true {required {username email first_names last_name} optional {url password}}

                false false true false {required {username email first_names last_name} optional {url password}}
            } {
                aa_log "UseEmailForLoginP = $use_email_p"
                parameter::set_value -parameter UseEmailForLoginP -package_id $kernel_id -value $use_email_p
                aa_log "RegistrationProvidesRandomPasswordP = $random_password_p"
                parameter::set_value -package_id $subsite_id -parameter RegistrationProvidesRandomPasswordP -value $random_password_p
                aa_log "RequireQuestionForPasswordResetP = $require_question_p"
                parameter::set_value -package_id $kernel_id -parameter RequireQuestionForPasswordResetP -value $require_question_p
                aa_log "UseCustomQuestionForPasswordReset = $use_question_p"
                parameter::set_value -package_id $kernel_id -parameter UseCustomQuestionForPasswordReset -value $use_question_p

                set elements [acs_sc::invoke \
                                  -contract auth_registration \
                                  -operation GetElements \
                                  -impl local \
                                  -call_args [list [list]]]
                aa_equals "GetElements returns correct required fields" \
                    [lsort [dict get $elements required]] [lsort [dict get $expected_elements required]]
                aa_equals "GetElements returns correct optional fields" \
                    [lsort [dict get $elements optional]] [lsort [dict get $expected_elements optional]]

                set elements [acs_sc::invoke \
                                  -contract auth_registration \
                                  -operation GetElements \
                                  -impl acs_testing \
                                  -call_args [list [list]]]
                aa_equals "GetElements returns correct required fields" \
                    [lsort [dict get $elements required]] [lsort [dict get $expected_elements required]]
                aa_equals "GetElements returns correct optional fields" \
                    [lsort [dict get $elements optional]] [lsort [dict get $expected_elements optional]]

            }
        } finally {
            aa_log "Resetting parameters"
            parameter::set_value -parameter UseEmailForLoginP -package_id $kernel_id -value $UseEmailForLoginP
            parameter::set_value -package_id $subsite_id -parameter RegistrationProvidesRandomPasswordP -value $RegistrationProvidesRandomPasswordP
            parameter::set_value -package_id $kernel_id -parameter RequireQuestionForPasswordResetP -value $RequireQuestionForPasswordResetP
            parameter::set_value -package_id $kernel_id -parameter UseCustomQuestionForPasswordReset -value $UseCustomQuestionForPasswordReset
        }

        aa_section auth::local::registration::GetParameters

        aa_stub acs_mail_lite::send {
            lappend ::auth_registration_implementations_from_addr $from_addr
            lappend ::auth_registration_implementations_to_addr $to_addr
        }

        aa_equals "GetParameters returns nothing" \
            [acs_sc::invoke \
                 -contract auth_registration \
                 -operation GetParameters \
                 -impl local] \
            ""
        aa_equals "GetParameters returns nothing" \
            [acs_sc::invoke \
                 -contract auth_registration \
                 -operation GetParameters \
                 -impl acs_testing] \
            ""

        aa_section auth::local::registration::Register

        set EmailRegistrationConfirmationToUserP [parameter::get -parameter EmailRegistrationConfirmationToUserP -package_id $subsite_id -default 1]
        set NotifyAdminOfNewRegistrationsP [parameter::get -parameter NotifyAdminOfNewRegistrationsP -package_id $subsite_id -default 0]

        set mail_package_id [apm_package_id_from_key acs-mail-lite]
        set fixed_sender [parameter::get -parameter "FixedSenderEmail" -package_id $mail_package_id]
        if { $fixed_sender ne ""} {
            set NewRegistrationEmailAddress $fixed_sender
        } else {
            set NewRegistrationEmailAddress [parameter::get -parameter NewRegistrationEmailAddress -package_id $subsite_id -default [ad_system_owner]]
        }

        set AdminNotificationEmailAddress [parameter::get -parameter NewRegistrationEmailAddress -package_id $subsite_id -default [ad_system_owner]]

        set user [acs::test::user::create]
        set user_id [dict get $user user_id]
        set user [acs_user::get -user_id $user_id]
        set parameters ""
        set username [dict get $user username]
        set authority_id [dict get $user authority_id]
        set first_names [dict get $user first_names]
        set last_name [dict get $user last_name]
        set screen_name [dict get $user screen_name]
        set email [dict get $user email]
        set url ""
        set secret_question "What are you testing here?"
        set secret_answer "...the service contracts..."

        try {
            aa_log "Password is nonempty"
            aa_log "EmailRegistrationConfirmationToUserP = 0"
            aa_log "RegistrationProvidesRandomPasswordP = 0"
            aa_log "NotifyAdminOfNewRegistrationsP = 0"

            set password [dict get $user password]
            parameter::set_value -package_id $subsite_id -parameter EmailRegistrationConfirmationToUserP -value 0
            parameter::set_value -package_id $subsite_id -parameter RegistrationProvidesRandomPasswordP -value 0
            parameter::set_value -package_id $subsite_id -parameter NotifyAdminOfNewRegistrationsP -value 0

            set ::auth_registration_implementations_from_addr [list]
            set ::auth_registration_implementations_to_addr [list]
            acs_sc::invoke \
                -contract auth_registration \
                -operation Register \
                -impl local \
                -call_args [list \
                                $parameters \
                                $username \
                                $authority_id \
                                $first_names \
                                $last_name \
                                $screen_name \
                                $email \
                                $url \
                                $password \
                                $secret_question \
                                $secret_answer]

            aa_true "Password was not changed" [ad_check_password $user_id $password]
            aa_equals "No emails were sent" $::auth_registration_implementations_to_addr ""

            aa_log "Password is empty"
            aa_log "EmailRegistrationConfirmationToUserP = 0"
            aa_log "RegistrationProvidesRandomPasswordP = 0"
            aa_log "NotifyAdminOfNewRegistrationsP = 0"

            set old_password $password
            set password ""
            parameter::set_value -package_id $subsite_id -parameter EmailRegistrationConfirmationToUserP -value 0
            parameter::set_value -package_id $subsite_id -parameter RegistrationProvidesRandomPasswordP -value 0
            parameter::set_value -package_id $subsite_id -parameter NotifyAdminOfNewRegistrationsP -value 0

            set ::auth_registration_implementations_from_addr [list]
            set ::auth_registration_implementations_to_addr [list]
            set result [acs_sc::invoke \
                            -contract auth_registration \
                            -operation Register \
                            -impl local \
                            -call_args [list \
                                            $parameters \
                                            $username \
                                            $authority_id \
                                            $first_names \
                                            $last_name \
                                            $screen_name \
                                            $email \
                                            $url \
                                            $password \
                                            $secret_question \
                                            $secret_answer]]

            set new_password [dict get $result password]
            aa_true "Password was generated" [dict get $result generated_pwd_p]
            aa_true "Password was changed" {$old_password ne $new_password}
            aa_true "Password works" [ad_check_password $user_id $new_password]
            aa_equals "No emails were sent" $::auth_registration_implementations_to_addr ""

            aa_log "Password is nonempty"
            aa_log "EmailRegistrationConfirmationToUserP = 1"
            aa_log "RegistrationProvidesRandomPasswordP = 0"
            aa_log "NotifyAdminOfNewRegistrationsP = 0"

            set password $new_password
            parameter::set_value -package_id $subsite_id -parameter EmailRegistrationConfirmationToUserP -value 1
            parameter::set_value -package_id $subsite_id -parameter RegistrationProvidesRandomPasswordP -value 0
            parameter::set_value -package_id $subsite_id -parameter NotifyAdminOfNewRegistrationsP -value 0

            set ::auth_registration_implementations_from_addr [list]
            set ::auth_registration_implementations_to_addr [list]
            acs_sc::invoke \
                -contract auth_registration \
                -operation Register \
                -impl local \
                -call_args [list \
                                $parameters \
                                $username \
                                $authority_id \
                                $first_names \
                                $last_name \
                                $screen_name \
                                $email \
                                $url \
                                $password \
                                $secret_question \
                                $secret_answer]

            aa_true "Password was not changed" [ad_check_password $user_id $password]
            aa_equals "One confirmation email was sent by the configured addressed" \
                $::auth_registration_implementations_from_addr [list $NewRegistrationEmailAddress]
            aa_equals "One confirmation email was sent to the user" \
                $::auth_registration_implementations_to_addr [list $email]

            aa_log "Password is nonempty"
            aa_log "EmailRegistrationConfirmationToUserP = 1"
            aa_log "RegistrationProvidesRandomPasswordP = 1"
            aa_log "NotifyAdminOfNewRegistrationsP = 1"

            parameter::set_value -package_id $subsite_id -parameter EmailRegistrationConfirmationToUserP -value 1
            parameter::set_value -package_id $subsite_id -parameter RegistrationProvidesRandomPasswordP -value 1
            parameter::set_value -package_id $subsite_id -parameter NotifyAdminOfNewRegistrationsP -value 1

            set ::auth_registration_implementations_from_addr [list]
            set ::auth_registration_implementations_to_addr [list]
            set result [acs_sc::invoke \
                            -contract auth_registration \
                            -operation Register \
                            -impl local \
                            -call_args [list \
                                            $parameters \
                                            $username \
                                            $authority_id \
                                            $first_names \
                                            $last_name \
                                            $screen_name \
                                            $email \
                                            $url \
                                            $password \
                                            $secret_question \
                                            $secret_answer]]

            set new_password [dict get $result password]
            aa_true "Password was generated" [dict get $result generated_pwd_p]
            aa_true "Password was changed" {$password ne $new_password}
            aa_true "Password works" [ad_check_password $user_id $new_password]

            aa_equals "Two emails were sent" \
                [llength $::auth_registration_implementations_from_addr] 2
            aa_true "One confirmation email was sent by the configured addressed" \
                {$NewRegistrationEmailAddress in $::auth_registration_implementations_from_addr}
            aa_true "One confirmation email was sent to the user" \
                {$email in $::auth_registration_implementations_to_addr}
            aa_true "One notification email was sent by the configured outgoing sender" \
                {[ad_outgoing_sender] in $::auth_registration_implementations_from_addr}
            aa_true "One notification email was sent to the system administrator" \
                {$AdminNotificationEmailAddress in $::auth_registration_implementations_to_addr}

        } finally {
            parameter::set_value -package_id $subsite_id -parameter EmailRegistrationConfirmationToUserP -value $EmailRegistrationConfirmationToUserP
            parameter::set_value -package_id $subsite_id -parameter RegistrationProvidesRandomPasswordP -value $RegistrationProvidesRandomPasswordP
            parameter::set_value -package_id $subsite_id -parameter NotifyAdminOfNewRegistrationsP -value $NotifyAdminOfNewRegistrationsP
        }


        aa_section acs::test::auth::registration::Register

        aa_log "Password is nonempty"

        set password $new_password

        set ::auth_registration_implementations_from_addr [list]
        set ::auth_registration_implementations_to_addr [list]
        acs_sc::invoke \
            -contract auth_registration \
            -operation Register \
            -impl acs_testing \
            -call_args [list \
                            $parameters \
                            $username \
                            $authority_id \
                            $first_names \
                            $last_name \
                            $screen_name \
                            $email \
                            $url \
                            $password \
                            $secret_question \
                            $secret_answer]

        aa_true "Password was not changed" [ad_check_password $user_id $password]
        aa_equals "No emails were sent" $::auth_registration_implementations_to_addr ""

    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        auth::local::user_info::GetParameters
        auth::local::user_info::GetUserInfo
    } \
    auth_user_info_implementations {
        Test implementations of the auth_user_info contract
    } {
        aa_equals "GetParameters returns nothing" \
            [acs_sc::invoke \
                 -contract auth_user_info \
                 -operation GetParameters \
                 -impl local] \
            ""

        set authority_id [auth::authority::get]
        if {![db_0or1row get_any_user {
            select user_id, first_names, last_name, username, email
            from cc_users
            where authority_id = :authority_id
            fetch first 1 rows only
        } -column_array user_info]} {
            aa_log "No user in the default authority. Exit immediately."
            return
        }

        set result(info_status) [auth::get_local_account_status -user_id $user_info(user_id)]
        set result(info_message) ""
        set result(user_info) [array get user_info]

        set sc_result [acs_sc::invoke \
                           -contract auth_user_info \
                           -operation GetUserInfo \
                           -impl local \
                           -call_args [list $user_info(username) [list]]]
        foreach key {info_status info_message} {
            aa_equals "'$key' is correct" [dict get $sc_result $key] $result($key)
        }

        foreach key [dict keys $result(user_info)] {
            aa_equals "'$key' is correct" \
                [dict get $sc_result user_info $key] \
                [dict get $result(user_info) $key]
        }
    }
