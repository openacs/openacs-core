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
        party::email
        person::delete
        person::get
        person::get_bio
        person::name
        person::new
        person::person_p
        person::update
        person::update_bio
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
		person::update_bio -person_id $prs_id -bio $bio
		
		aa_true "bio(graphy) ok" [string match $bio [person::get_bio -person_id $prs_id -exists_var bio_p]]
		
		person::delete -person_id $prs_id
                aa_true "person deleted" ![person::person_p -party_id $prs_id]

	    }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        party::get_by_email
        party::update
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
		party::update -party_id $user_info(user_id) -email "${email}2" -url $url
		aa_true "correct party with new mail" [string match [party::get_by_email -email "${email}2"] $user_info(user_id)]
	    }
    }


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
