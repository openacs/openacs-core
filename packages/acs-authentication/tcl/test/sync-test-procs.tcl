ad_library {
    Automated tests for synchronization API

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 05 September 2003
    @cvs-id $Id$
}

aa_register_case job_start_end {
    Test batch job basics: Starting, getting document, adding entries, ending.
} {    
    aa_run_with_teardown \
        -rollback \
        -test_code {
            
            # Start non-interactive job
            
            set job_id [auth::sync::job::start \
                            -authority_id [auth::authority::local]]
                            
            aa_true "Returns a job_id" [exists_and_not_null job_id]


            # Get doc
            auth::sync::job::start_get_document -job_id $job_id

            auth::sync::job::end_get_document \
                -job_id $job_id \
                -doc_status "ok" \
                -doc_message "" \
                -document {<enterprise><person recstatus="1"></person></enterprise>}

            # Valid successful log entry
            auth::sync::job::create_entry \
                -job_id $job_id \
                -operation "insert" \
                -authority_id [auth::authority::local] \
                -username "foobar" \
                -user_id [ad_conn user_id] \
                -success

            # Valid unsuccessful log entry
            auth::sync::job::create_entry \
                -job_id $job_id \
                -operation "insert" \
                -authority_id [auth::authority::local] \
                -username "foobar" \
                -user_id [ad_conn user_id] \
                -message "A problem" \
                -element_messages ""


            # End job
            array set job [auth::sync::job::end -job_id $job_id]
            
            aa_true "Elapsed time less than 30 seconds" [expr $job(run_time_seconds) < 30]

            aa_log "Elapsed time: $job(run_time_seconds) seconds"

            aa_false "Not interactive" [template::util::is_true $job(interactive_p)]

            aa_equals "Number of actions" $job(num_actions) 2

            aa_equals "Number of problems" $job(num_problems) 1
            
            aa_false "Log URL non-empty" [empty_string_p $job(log_url)]
            
            
        }
}

aa_register_case job_actions {
    Test job actions: insert, update, 
} {    
    aa_run_with_teardown \
        -rollback \
        -test_code {

            # Start non-interactive job
            
            set job_id [auth::sync::job::start \
                            -authority_id [auth::authority::local]]
                            
            aa_true "Returns a job_id" [exists_and_not_null job_id]

            #####
            #
            # Valid insert action
            #
            #####

            set username1 [ad_generate_random_string]
            set email1 "[ad_generate_random_string]@foo.bar"
            set first_names1 [ad_generate_random_string]
            set last_name1 [ad_generate_random_string]
            set url1 "http://[ad_generate_random_string].com"
            aa_log "--- Valid insert --- auth::sync::job::action -opration insert -username $username1 -email $email1"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "insert" \
                              -authority_id [auth::authority::local] \
                              -username $username1 \
                              -first_names $first_names1 \
                              -last_name $last_name1 \
                              -email $email1 \
                              -url $url1]

            array unset entry
            auth::sync::job::get_entry \
                -entry_id $entry_id \
                -array entry

            aa_equals "entry.success_p" $entry(success_p) "t"
            aa_equals "entry.message" $entry(message) {} 
            aa_equals "entry.element_messages" $entry(element_messages) {}
            aa_log "entry.user_id = '$entry(user_id)'"
            aa_log "entry.message = '$entry(message)'"
            aa_log "entry.element_messages = '$entry(element_messages)'"

            if { [aa_true "Entry has user_id set" [exists_and_not_null entry(user_id)]] } {
                array unset user
                acs_user::get -user_id $entry(user_id) -array user
                
                aa_equals "user.first_names" $user(first_names) $first_names1
                aa_equals "user.last_name" $user(last_name) $last_name1
                aa_equals "user.email" $user(email) [string tolower $email1]
                aa_equals "user.authority_id" $user(authority_id) [auth::authority::local]
                aa_equals "user.username" $user(username) $username1
                aa_equals "user.url" $user(url) $url1
            }
            
            #####
            #
            # Invalid insert action: Reusing username, email
            #
            #####

            aa_log "--- Invalid insert: reusing username, email --- auth::sync::job::action -opration insert -username $username1 -email $email1"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "insert" \
                              -authority_id [auth::authority::local] \
                              -username $username1 \
                              -first_names [ad_generate_random_string] \
                              -last_name [ad_generate_random_string] \
                              -email $email1 \
                              -url "http://"]

            array unset entry
            auth::sync::job::get_entry \
                -entry_id $entry_id \
                -array entry

            aa_equals "entry.success_p" $entry(success_p) "f"

            if { [aa_true "entry.element_messages not empty" [exists_and_not_null entry(element_messages)]] } {
                array unset elm_msgs
                array set elm_msgs $entry(element_messages)
                aa_true "username, email have problems" [util_sets_equal_p { username email } [array names elm_msgs]]
            }

            aa_log "entry.user_id = '$entry(user_id)'"
            aa_log "entry.message = '$entry(message)'"
            aa_log "entry.element_messages = '$entry(element_messages)'"
            
            #####
            #
            # Valid update action
            #
            #####

            set email2 "[ad_generate_random_string]@foo.bar"
            set first_names2 [ad_generate_random_string]
            set last_name2 [ad_generate_random_string]
            set url2 "http://[ad_generate_random_string].com"
            aa_log "--- Valid update --- auth::sync::job::action -opration update -username $username1"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "update" \
                              -authority_id [auth::authority::local] \
                              -username $username1 \
                              -first_names $first_names2 \
                              -last_name $last_name2 \
                              -email $email2 \
                              -url $url2]

            array unset entry
            auth::sync::job::get_entry \
                -entry_id $entry_id \
                -array entry

            aa_equals "entry.success_p" $entry(success_p) "t"
            aa_equals "entry.message" $entry(message) {}
            aa_equals "entry.element_messages" $entry(element_messages) {}
            aa_log "entry.user_id = '$entry(user_id)'"
            aa_log "entry.message = '$entry(message)'"
            aa_log "entry.element_messages = '$entry(element_messages)'"

            if { [aa_true "Entry has user_id set" [exists_and_not_null entry(user_id)]] } {
                array unset user
                acs_user::get -user_id $entry(user_id) -array user
                
                aa_equals "user.first_names" $user(first_names) $first_names2
                aa_equals "user.last_name" $user(last_name) $last_name2
                aa_equals "user.email" $user(email) [string tolower $email2]
                aa_equals "user.authority_id" $user(authority_id) [auth::authority::local]
                aa_equals "user.username" $user(username) $username1
                aa_equals "user.url" $user(url) $url2
            }

            #####
            #
            # Invalid insert action: Missing first_names, last_name invalid, email, url invalid
            #
            #####

            set username2 [ad_generate_random_string]
            aa_log "--- Invalid insert --- auth::sync::job::action -opration update -username $username2"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "insert" \
                              -authority_id [auth::authority::local] \
                              -username $username2 \
                              -first_names {} \
                              -last_name {<b>Foobar</b>} \
                              -email "not_an_email" \
                              -url "NotAURL"]

            array unset entry
            auth::sync::job::get_entry \
                -entry_id $entry_id \
                -array entry

            aa_equals "entry.success_p" $entry(success_p) "f"
            aa_log "entry.message = '$entry(message)'"
            if { [aa_true "entry.element_messages not empty" [exists_and_not_null entry(element_messages)]] } {
                aa_log "entry.element_messages = '$entry(element_messages)'"
                array unset elm_msgs
                array set elm_msgs $entry(element_messages)
                aa_log "array names elm_msgs = '[array names elm_msgs]'"
                aa_true "first_names, last_name, email, url have problems" [util_sets_equal_p { first_names last_name email url } [array names elm_msgs]]
            }

            #####
            #
            # Valid delete action
            #
            #####

            aa_log "--- Valid delete --- auth::sync::job::action -opration delete -username $username1"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "delete" \
                              -authority_id [auth::authority::local] \
                              -username $username1]
            
            array unset entry
            auth::sync::job::get_entry \
                -entry_id $entry_id \
                -array entry

            aa_equals "entry.success_p" $entry(success_p) "t"
            aa_log "entry.message = '$entry(message)'"

            if { [aa_true "Entry has user_id set" [exists_and_not_null entry(user_id)]] } {
                array unset user
                acs_user::get -user_id $entry(user_id) -array user
                aa_equals "User member state is banned" $user(member_state) "banned"
            }
            

            #####
            #
            # End job
            #
            #####

            array set job [auth::sync::job::end -job_id $job_id]
            
            aa_true "Elapsed time less than 30 seconds" [expr $job(run_time_seconds) < 30]

            aa_false "Not interactive" [template::util::is_true $job(interactive_p)]

            aa_equals "Number of actions" $job(num_actions) 5

            aa_equals "Number of problems" $job(num_problems) 2
           
            aa_false "Log URL non-empty" [empty_string_p $job(log_url)]
            
        }
}

aa_register_case job_snapshot {
    Test a snapshot job
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {

            # Start non-interactive job
            
            set job_id [auth::sync::job::start \
                            -authority_id [auth::authority::local]]
                            
            aa_true "Returns a job_id" [exists_and_not_null job_id]

            #####
            #
            # Valid insert action
            #
            #####

            set username1 [ad_generate_random_string]
            set email1 "[ad_generate_random_string]@foo.bar"
            set first_names1 [ad_generate_random_string]
            set last_name1 [ad_generate_random_string]
            set url1 "http://[ad_generate_random_string].com"
            aa_log "--- Valid insert --- auth::sync::job::action -opration insert -username $username1 -email $email1"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "snapshot" \
                              -authority_id [auth::authority::local] \
                              -username $username1 \
                              -first_names $first_names1 \
                              -last_name $last_name1 \
                              -email $email1 \
                              -url $url1]

            array unset entry
            auth::sync::job::get_entry \
                -entry_id $entry_id \
                -array entry

            aa_equals "entry.success_p" $entry(success_p) "t"
            aa_equals "entry.message" $entry(message) {} 
            aa_equals "entry.element_messages" $entry(element_messages) {}
            aa_equals "entry.operation" $entry(operation) "insert"
            aa_log "entry.user_id = '$entry(user_id)'"
            aa_log "entry.message = '$entry(message)'"
            aa_log "entry.element_messages = '$entry(element_messages)'"

            if { [aa_true "Entry has user_id set" [exists_and_not_null entry(user_id)]] } {
                array unset user
                acs_user::get -user_id $entry(user_id) -array user
                
                aa_equals "user.first_names" $user(first_names) $first_names1
                aa_equals "user.last_name" $user(last_name) $last_name1
                aa_equals "user.email" $user(email) [string tolower $email1]
                aa_equals "user.authority_id" $user(authority_id) [auth::authority::local]
                aa_equals "user.username" $user(username) $username1
                aa_equals "user.url" $user(url) $url1
            }
            
            #####
            #
            # Valid update action
            #
            #####

            set email2 "[ad_generate_random_string]@foo.bar"
            set first_names2 [ad_generate_random_string]
            set last_name2 [ad_generate_random_string]
            set url2 "http://[ad_generate_random_string].com"
            aa_log "--- Valid update --- auth::sync::job::action -opration update -username $username1"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "snapshot" \
                              -authority_id [auth::authority::local] \
                              -username $username1 \
                              -first_names $first_names2 \
                              -last_name $last_name2 \
                              -email $email2 \
                              -url $url2]

            array unset entry
            auth::sync::job::get_entry \
                -entry_id $entry_id \
                -array entry

            aa_equals "entry.success_p" $entry(success_p) "t"
            aa_equals "entry.message" $entry(message) {}
            aa_equals "entry.element_messages" $entry(element_messages) {}
            aa_equals "entry.operation" $entry(operation) "update"
            aa_log "entry.user_id = '$entry(user_id)'"
            aa_log "entry.message = '$entry(message)'"
            aa_log "entry.element_messages = '$entry(element_messages)'"

            if { [aa_true "Entry has user_id set" [exists_and_not_null entry(user_id)]] } {
                array unset user
                acs_user::get -user_id $entry(user_id) -array user
                
                aa_equals "user.first_names" $user(first_names) $first_names2
                aa_equals "user.last_name" $user(last_name) $last_name2
                aa_equals "user.email" $user(email) [string tolower $email2]
                aa_equals "user.authority_id" $user(authority_id) [auth::authority::local]
                aa_equals "user.username" $user(username) $username1
                aa_equals "user.url" $user(url) $url2
            }

            
            #####
            #
            # Wrap up batch sync job
            #
            #####

            # We need this number to check the counts below
            set authority_id [auth::authority::local]
            set num_users_not_banned [db_string select_num { 
                select count(*) 
                from   cc_users 
                where  authority_id = :authority_id 
                and    member_state != 'banned' 
            }]
            
            auth::sync::job::snapshot_delete_remaining \
                -job_id $job_id \
                -authority_id [auth::authority::local]

            #####
            #
            # End job
            #
            #####

            array set job [auth::sync::job::end -job_id $job_id]
            
            aa_true "Elapsed time less than 30 seconds" [expr $job(run_time_seconds) < 30]

            aa_false "Not interactive" [template::util::is_true $job(interactive_p)]

            aa_equals "Number of actions" $job(num_actions) [expr $num_users_not_banned + 1]

            aa_equals "Number of problems" $job(num_problems) 0
           
            aa_false "Log URL non-empty" [empty_string_p $job(log_url)]
            
        }    
}
