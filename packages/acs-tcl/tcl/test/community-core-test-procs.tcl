ad_library {
    Test cases for community core procs.

    @author byron Haroldo Linares Roman (bhlr@galileo.edu)
    @creation-date 2006-07-28
    @cvs-id $Id$
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        party::email
        party::get_by_email
        acs::test::user::create

        db_1row
    } \
    community_cc_procs \
    {
        test community core procs returned values
    } {
        aa_run_with_teardown -rollback -test_code {
            set user_id [db_nextval acs_object_id_seq]
            set username [ad_generate_random_string]
            set password [ad_generate_random_string]

            array set user_info [acs::test::user::create -user_id $user_id]
            set user_id_p [party::get_by_email -email $user_info(email)]
            aa_true "User ID CORRECTO" \
                [string match $user_id_p $user_info(user_id)]
            set email_p [party::email -party_id $user_info(user_id)]
            aa_log "returns:  $email_p ,  creation:  $user_info(email)"
            aa_true "Email correcto" \
                [string match $email_p [string tolower $user_info(email)]]
        }

    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        auth::authority::get_id
        auth::create_user
        party::email
        person::delete
        person::get
        person::get_bio
        person::name
        person::new
        person::person_p
        person::update

        db_1row
    } \
    person_procs_test \
    {
        Test whether the values returned by the person procs are correct.
    } {

        set user_id [db_nextval acs_object_id_seq]
        set username "[ad_generate_random_string]"
        set email "${username}@test.test"
        set password [ad_generate_random_string]
        set first_names [ad_generate_random_string]
        set last_name [ad_generate_random_string]

        array set user_info [auth::create_user  -user_id $user_id  -username $username \
                                 -email $email  -first_names $first_names  -last_name $last_name \
                                 -password $password  -secret_question [ad_generate_random_string] \
                                 -authority_id [auth::authority::get_id -short_name "acs_testing"] \
                                 -secret_answer [ad_generate_random_string]]

        if { $user_info(creation_status) ne "ok" } {
            # Could not create user
            error "Could not create test user with username=$username user_info=[array get user_info]"
        }

        set user_info(password) $password
        set user_info(email) $email

        aa_log "Created user with email=\"$email\" and password=\"$password\" user_id=$user_info(user_id)"

        aa_run_with_teardown -rollback \
            -test_code {

                aa_true "party is a person" [person::person_p -party_id $user_id]

                array set user_inf [person::get -person_id $user_info(user_id)]

                aa_true "first_names correct" [string match $user_inf(first_names) $first_names]
                aa_true "last_name correct" [string match $user_inf(last_name) $last_name]
                aa_true "person_id correct" [string match $user_inf(person_id) $user_id]
                aa_true "correct name" [string match [person::name -person_id $user_info(user_id)] "$first_names $last_name"]

                set prs_id [person::new -first_names $first_names -last_name $last_name -email "${email}s"]
                set email_p [party::email -party_id $prs_id]
                aa_true "New person pass" [string match $email_p [string tolower "${email}s"]]

                aa_log "New Person has user_id=$prs_id email_p=$email_p"
                aa_log "Is this ID in persons ? [db_list _ {select * from persons where person_id=:prs_id}]"
                aa_log "Is this ID in users   ? [db_list _ {select * from cc_users where user_id=:prs_id}]"

                person::update -person_id $prs_id -first_names "hh$first_names" -last_name "hh$last_name"
                aa_true "name changed" [string match [person::name -person_id $prs_id] "hh$first_names hh$last_name"]

                set bio "bio :: [ad_generate_random_string] :: bio"
                person::update -person_id $prs_id -bio $bio

                aa_true "bio(graphy) ok" [string match $bio [person::get_bio -person_id $prs_id -exists_var bio_p]]

                person::delete -person_id $prs_id
                aa_true "person deleted" ![person::person_p -party_id $prs_id]

            }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        auth::authority::get_id
        auth::create_user
        party::get_by_email
        party::update

        db_1row
    } \
    party_procs_test \
    {
        test if the values returned by the party procs are correct
    } {

        set user_id [db_nextval acs_object_id_seq]
        set username "[ad_generate_random_string]"
        set email "${username}@test.test"
        set password [ad_generate_random_string]
        set first_names [ad_generate_random_string]
        set last_name [ad_generate_random_string]
        set url "url[ad_generate_random_string]"

        array set user_info [auth::create_user  \
                                 -user_id $user_id  \
                                 -authority_id [auth::authority::get_id -short_name "acs_testing"] \
                                 -username $username  \
                                 -email $email  \
                                 -first_names $first_names \
                                 -last_name $last_name  \
                                 -password $password \
                                 -secret_question [ad_generate_random_string] \
                                 -secret_answer [ad_generate_random_string]]

        if { $user_info(creation_status) ne "ok" } {
            # Could not create user
            error "Could not create test user with username=$username user_info=[array get user_info]"
        }

        set user_info(password) $password
        set user_info(email) $email

        aa_log "Created user with email=\"$email\" and password=\"$password\""
        aa_run_with_teardown -rollback \
            -test_code {

                aa_true "correct party_id" [string match [party::get_by_email -email $email] $user_info(user_id)]
                set updated_email [string toupper "${email}2"]
                party::update -party_id $user_info(user_id) -email $updated_email -url $url
                aa_equals "Email case is lower" [party::get -party_id $user_info(user_id) -element email] [string tolower "${email}2"]
                aa_true "correct party with new mail" [string match [party::get_by_email -email "${email}2"] $user_info(user_id)]
            }
    }

aa_register_case \
    -cats {smoke} \
    party_emails_are_lowercase \
    {
        Make sure all party emails are stored as lowercase
    } {
        aa_false "All emails are lowercase" [db_0or1row get_wrong_case {
            select 1 from dual where exists
            (select 1 from parties where email <> lower(email))
        }]
    }

aa_register_case \
    -procs {
        acs_user::ScreenName
    } \
    -cats {smoke api} \
    user_screen_name_conf \
    {
        Test acs_user::ScreenName api
    } {
        set screen_name [parameter::get \
                             -parameter ScreenName \
                             -package_id $::acs::kernel_id \
                             -default "solicit"]
        try {
            aa_section "Valid values"
            foreach v {"none" "solicit" "require"} {
                parameter::set_value \
                    -parameter ScreenName \
                    -package_id $::acs::kernel_id \
                    -value $v
                aa_equals "Value is correct" \
                    [acs_user::ScreenName] $v
            }
            aa_section "Invalid values"
            foreach v {"balooney" "gorbige" 10000} {
                parameter::set_value \
                    -parameter ScreenName \
                    -package_id $::acs::kernel_id \
                    -value $v
                aa_equals "Value is correct" \
                    [acs_user::ScreenName] solicit
            }
        } finally {
            # Cleanup
            parameter::set_value \
                -parameter ScreenName \
                -package_id $::acs::kernel_id \
                -value $screen_name
        }
    }

aa_register_case \
    -procs {
        acs_user::site_wide_admin_p
        acs::test::user::create
        acs_user::get_user_info
        acs_user::demote_user
        acs_user::erase_portrait
        acs_user::flush_cache
        acs_user::flush_user_info
        acs_user::flush_portrait
        person::flush_cache
        acs_user::create_portrait
        acs_user::promote_person_to_user
        person::get_person_info
        acs_user::update
        acs_user::get_user_id_by_screen_name
        acs_user::reject
        acs_user::unapprove
    } \
    -cats {
        smoke api
    } demote_promote_a_user {
        Test demoting of a user to a party/person and then promoting
        it again to user. Take the chance to test some other api as
        well.
    } {
        aa_run_with_teardown -rollback -test_code {
            aa_section "Create user"
            set user [acs::test::user::create -admin]
            set user_id [dict get $user user_id]

            aa_true "User '$user_id' exists" \
                [llength [acs_user::get_user_info -user_id $user_id]]
            aa_true "User '$user_id' is an SWA" \
                [acs_user::site_wide_admin_p -user_id $user_id]

            aa_section "Update the user's screen name"
            set screen_name "___A crazy screen name"
            acs_user::update -user_id $user_id \
                -screen_name $screen_name
            aa_equals "We can find the user by its screen name" \
                [acs_user::get_user_id_by_screen_name \
                     -screen_name $screen_name] $user_id
            aa_equals "Screen name is consistent between apis" \
                [dict get [acs_user::get_user_info -user_id $user_id] screen_name] \
                $screen_name

            aa_section "Reject user"
            acs_user::reject -user_id $user_id
            aa_equals "User was rejected" \
                [dict get [acs_user::get_user_info -user_id $user_id] member_state] rejected
            aa_section "Unapprove user"
            acs_user::unapprove -user_id $user_id
            aa_equals "User was rejected" \
                [dict get [acs_user::get_user_info -user_id $user_id] member_state] "needs approval"

            aa_section "Demote user"
            acs_user::demote_user -user_id $user_id

            aa_false "User '$user_id' does not exist" \
                [llength [acs_user::get_user_info -user_id $user_id]]
            aa_false "User '$user_id' is not an SWA" \
                [acs_user::site_wide_admin_p -user_id $user_id]
            aa_true "'$user_id' is still a person" \
                [llength [person::get_person_info -person_id $user_id]]

            aa_section "Promote user"
            acs_user::promote_person_to_user -person_id $user_id

            aa_true "User '$user_id' exists" \
                [llength [acs_user::get_user_info -user_id $user_id]]
            aa_false "User '$user_id' is still not an SWA" \
                [acs_user::site_wide_admin_p -user_id $user_id]

            aa_section "Add portrait, then demote again"
            set F [ad_opentmpfile tmpfile]
            puts $F abcd
            close $F
            set portrait_id [acs_user::create_portrait -user_id $user_id \
                                 -description "Some test portrait" \
                                 -filename test.png \
                                 -mime_type image/png \
                                 -file $tmpfile]
            
            aa_equals "We can retrieve the portrait" \
                [acs_user::get_portrait_id -user_id $user_id] $portrait_id

            acs_user::demote_user -user_id $user_id -delete_portrait

            aa_false "User '$user_id' does not exist" \
                [llength [acs_user::get_user_info -user_id $user_id]]
            aa_false "User '$user_id' is not an SWA" \
                [acs_user::site_wide_admin_p -user_id $user_id]
            aa_true "'$user_id' is still a person" \
                [llength [person::get_person_info -person_id $user_id]]
            aa_equals "Portrait is gone" \
                [acs_user::get_portrait_id -user_id $user_id] 0

            ad_file delete $tmpfile
        }
    }



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
