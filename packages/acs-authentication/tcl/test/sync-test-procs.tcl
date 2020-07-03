ad_library {
    Automated tests for synchronization API

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 05 September 2003
    @cvs-id $Id$
}

aa_register_case \
    -cats {api db} \
    -procs {
        auth::authority::local
        auth::sync::job::create_entry
        auth::sync::job::end
        auth::sync::job::end_get_document
        auth::sync::job::start
        auth::sync::job::start_get_document
        auth::sync::purge_jobs
    } \
    sync_start_end {
    Test batch job basics: Starting, getting document, adding entries, ending.
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {

            # Start noninteractive job

            set job_id [auth::sync::job::start \
                            -authority_id [auth::authority::local]]

            aa_true "Returns a job_id" {$job_id ne ""}


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
                -username "foobar" \
                -user_id [ad_conn user_id] \
                -success

            # Valid unsuccessful log entry
            auth::sync::job::create_entry \
                -job_id $job_id \
                -operation "insert" \
                -username "foobar" \
                -user_id [ad_conn user_id] \
                -message "A problem" \
                -element_messages ""


            # End job
            array set job [auth::sync::job::end -job_id $job_id]

            aa_true "Elapsed time less than 30 seconds" {$job(run_time_seconds) < 30}

            aa_log "Elapsed time: $job(run_time_seconds) seconds"

            aa_false "Not interactive" [template::util::is_true $job(interactive_p)]

            aa_equals "Number of actions" $job(num_actions) 2

            aa_equals "Number of problems" $job(num_problems) 1

            aa_false "Log URL nonempty" {$job(log_url) eq ""}

            # Purge not deleting the job
            auth::sync::purge_jobs \
                -num_days 1

            aa_equals "Job still exists" [db_string job_exists_p { select count(*) from auth_batch_job_entries where job_id = :job_id }] 2

            # Tricking it into deleting the job
            aa_log "Updating the job end time"
            db_dml update_job { update auth_batch_jobs set job_end_time = to_date('1974-03-27', 'YYYY-MM-DD') where job_id = :job_id }
            auth::sync::purge_jobs \
                -num_days 1

            aa_equals "Job has been purged" [db_string job_exists_p { select count(*) from auth_batch_job_entries where job_id = :job_id }] 0

        }
}

aa_register_case \
    -cats {api} \
    -procs {
        acs_user::get
        acs_user::get_user_info
        ad_generate_random_string
        auth::authority::local
        auth::sync::job::action
        auth::sync::job::end
        auth::sync::job::get_entry
        auth::sync::job::start
        util_sets_equal_p
    } \
    sync_actions {
    Test job actions: insert, update, delete.
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {

            # Start noninteractive job

            set job_id [auth::sync::job::start -authority_id [auth::authority::local]]

            aa_true "Returns a job_id" {[info exists job_id]}

            #####
            #
            # Valid insert action
            #
            #####

            array unset user_info
            set username1 [ad_generate_random_string]
            set email1 "[ad_generate_random_string]@foo.bar"
            set screen_name1 [ad_generate_random_string]
            set user_info(email) $email1
            set user_info(first_names) [ad_generate_random_string]
            set user_info(last_name) [ad_generate_random_string]
            set user_info(url) "http://[ad_generate_random_string].com"
            set user_info(screen_name) $screen_name1
            aa_log "--- Valid insert --- auth::sync::job::action -opration insert -username $username1 -email $email1"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "insert" \
                              -username $username1 \
                              -array user_info]

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

            if { [aa_true "Entry has user_id set" {$entry(user_id) ne ""}] } {
                set user [acs_user::get -user_id $entry(user_id)]

                aa_equals "user.first_names" [dict get $user first_names] $user_info(first_names)
                aa_equals "user.last_name" [dict get $user last_name] $user_info(last_name)
                aa_equals "user.email" [dict get $user email] [string tolower $email1]
                aa_equals "user.authority_id" [dict get $user authority_id] [auth::authority::local]
                aa_equals "user.username" [dict get $user username] $username1
                aa_equals "user.url" [dict get $user url] $user_info(url)
                aa_equals "user.screen_name" [dict get $user screen_name] $user_info(screen_name)
            }

            #####
            #
            # Invalid insert action: Reusing username, email
            #
            #####

            aa_log "--- Invalid insert: reusing username, email --- auth::sync::job::action -opration insert -username $username1 -email $email1"
            array unset user_info
            set user_info(first_names) [ad_generate_random_string]
            set user_info(last_name) [ad_generate_random_string]
            set user_info(email) $email1
            set user_info(url) "http://"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "insert" \
                              -username $username1 \
                              -array user_info]

            array unset entry
            auth::sync::job::get_entry \
                -entry_id $entry_id \
                -array entry

            aa_equals "entry.success_p" $entry(success_p) "f"

            aa_true "entry.message not empty" {$entry(message) ne ""}

            aa_log "entry.user_id = '$entry(user_id)'"
            aa_log "entry.message = '$entry(message)'"
            aa_log "entry.element_messages = '$entry(element_messages)'"

            #####
            #
            # Valid update action
            #
            #####

            set email2 "[ad_generate_random_string]@foo.bar"
            array unset user_info
            set user_info(first_names) [ad_generate_random_string]
            set user_info(last_name) [ad_generate_random_string]
            set user_info(url) "http://[ad_generate_random_string].com"
            set user_info(email) $email2
            aa_log "--- Valid update --- auth::sync::job::action -opration update -username $username1"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "update" \
                              -username $username1 \
                              -array user_info]

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

            if { [aa_true "Entry has user_id set" {$entry(user_id) ne ""}] } {
                set user [acs_user::get -user_id $entry(user_id)]

                aa_equals "user.first_names" [dict get $user first_names] $user_info(first_names)
                aa_equals "user.last_name" [dict get $user last_name] $user_info(last_name)
                aa_equals "user.email" [dict get $user email] [string tolower $email2]
                aa_equals "user.authority_id" [dict get $user authority_id] [auth::authority::local]
                aa_equals "user.username" [dict get $user username] $username1
                aa_equals "user.url" [dict get $user url] $user_info(url)
            }

            #####
            #
            # Valid update action, not changing any columns
            #
            #####

            # copy the old user_info array
            array set user_info2 [array get user_info]
            array unset user_info
            aa_log "--- Valid update, no changes --- auth::sync::job::action -opration update -username $username1"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "update" \
                              -username $username1 \
                              -array user_info]

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

            if { [aa_true "Entry has user_id set" {$entry(user_id) ne ""}] } {
                set user [acs_user::get -user_id $entry(user_id)]

                aa_equals "user.first_names" [dict get $user first_names] $user_info2(first_names)
                aa_equals "user.last_name" [dict get $user last_name] $user_info2(last_name)
                aa_equals "user.email" [dict get $user email] $user_info2(email)
                aa_equals "user.authority_id" [dict get $user authority_id] [auth::authority::local]
                aa_equals "user.username" [dict get $user username] $username1
                aa_equals "user.url" [dict get $user url] $user_info2(url)
            }

            #####
            #
            # Invalid insert action: Missing first_names, last_name invalid, email, url invalid
            #
            #####

            set username2 [ad_generate_random_string]
            array unset user_info
            set user_info(last_name) {<b>Foobar</b>}
            set user_info(email) "not_an_email"
            set user_info(url) "NotAURL"
            aa_log "--- Invalid insert --- auth::sync::job::action -opration update -username $username2"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "insert" \
                              -username $username2 \
                              -array user_info]

            array unset entry
            auth::sync::job::get_entry \
                -entry_id $entry_id \
                -array entry

            aa_equals "entry.success_p" $entry(success_p) "f"
            aa_log "entry.message = '$entry(message)'"
            if { [aa_true "entry.element_messages not empty" \
              {[info exists entry(element_messages)] && $entry(element_messages) ne ""}] } {
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
                              -username $username1]

            array unset entry
            auth::sync::job::get_entry \
                -entry_id $entry_id \
                -array entry

            aa_equals "entry.success_p" $entry(success_p) "t"
            aa_log "entry.message = '$entry(message)'"

            if { [aa_true "Entry has user_id set" {[info exists entry(user_id)] && $entry(user_id) ne ""}] } {
                set member_state [acs_user::get_user_info \
                                      -user_id $entry(user_id) -element "member_state"]
                aa_equals "User member state is banned" $member_state "banned"
            }


            #####
            #
            # End job
            #
            #####

            array set job [auth::sync::job::end -job_id $job_id]

            aa_true "Elapsed time less than 30 seconds" {$job(run_time_seconds) < 30}

            aa_false "Not interactive" [template::util::is_true $job(interactive_p)]

            aa_equals "Number of actions" $job(num_actions) 6

            aa_equals "Number of problems" $job(num_problems) 2

            aa_false "Log URL nonempty" {$job(log_url) eq ""}

        }
}

aa_register_case \
    -cats {api db} \
    -procs {
        acs_user::get
        ad_generate_random_string
        auth::authority::local
        auth::sync::job::action
        auth::sync::job::end
        auth::sync::job::get_entry
        auth::sync::job::snapshot_delete_remaining
        auth::sync::job::start
    } \
    sync_snapshot {
    Test a snapshot job
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {

            # Start noninteractive job

            set job_id [auth::sync::job::start -authority_id [auth::authority::local]]

            aa_true "Returns a job_id" {$job_id ne ""}

            #####
            #
            # Valid insert action
            #
            #####

            set username1 [ad_generate_random_string]
            set email1 "[ad_generate_random_string]@foo.bar"
            array unset user_info
            set user_info(email) $email1
            set user_info(first_names) [ad_generate_random_string]
            set user_info(last_name) [ad_generate_random_string]
            set user_info(url) "http://[ad_generate_random_string].com"
            aa_log "--- Valid insert --- auth::sync::job::action -opration insert -username $username1 -email $email1"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "snapshot" \
                              -username $username1 \
                              -array user_info]

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

            if { [aa_true "Entry has user_id set" {$entry(user_id) ne ""}] } {
                set user [acs_user::get -user_id $entry(user_id)]

                aa_equals "user.first_names" [dict get $user first_names] $user_info(first_names)
                aa_equals "user.last_name" [dict get $user last_name] $user_info(last_name)
                aa_equals "user.email" [dict get $user email] [string tolower $email1]
                aa_equals "user.authority_id" [dict get $user authority_id] [auth::authority::local]
                aa_equals "user.username" [dict get $user username] $username1
                aa_equals "user.url" [dict get $user url] $user_info(url)
            }

            #####
            #
            # Valid update action
            #
            #####

            array unset user_info
            set user_info(email) "[ad_generate_random_string]@foo.bar"
            set user_info(first_names) [ad_generate_random_string]
            set user_info(last_name) [ad_generate_random_string]
            set user_info(url) "http://[ad_generate_random_string].com"
            aa_log "--- Valid update --- auth::sync::job::action -opration update -username $username1"
            set entry_id [auth::sync::job::action \
                              -job_id $job_id \
                              -operation "snapshot" \
                              -username $username1 \
                              -array user_info]

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

            if { [aa_true "Entry has user_id set" {$entry(user_id) ne ""}] } {
                set user [acs_user::get -user_id $entry(user_id)]

                aa_equals "user.first_names" [dict get $user first_names] $user_info(first_names)
                aa_equals "user.last_name" [dict get $user last_name] $user_info(last_name)
                aa_equals "user.email" [dict get $user email] [string tolower $user_info(email)]
                aa_equals "user.authority_id" [dict get $user authority_id] [auth::authority::local]
                aa_equals "user.username" [dict get $user username] $username1
                aa_equals "user.url" [dict get $user url] $user_info(url)
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
                -job_id $job_id

            #####
            #
            # End job
            #
            #####

            array set job [auth::sync::job::end -job_id $job_id]

            aa_true "Elapsed time less than 30 seconds" {$job(run_time_seconds) < 30}

            aa_false "Not interactive" [template::util::is_true $job(interactive_p)]

            aa_equals "Number of actions" $job(num_actions) [expr {$num_users_not_banned + 1}]

            aa_equals "Number of problems" $job(num_problems) 0

            aa_false "Log URL nonempty" {$job(log_url) eq ""}

        }
}


aa_register_case \
    -cats {api smoke} \
    -procs {
        auth::authority::batch_sync
        auth::authority::local
        auth::sync::job::get
    } \
    sync_batch_for_local {
    Test a batch job for the local authority
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {

            set job_id [auth::authority::batch_sync -authority_id [auth::authority::local]]

            auth::sync::job::get -job_id $job_id -array job

            aa_log "job.message = '$job(message)'"
            aa_true "job.message not empty when called for local authority" {$job(message) ne ""}
        }
}


aa_register_case \
    -cats {api} \
    -procs {
        acs_sc::impl::get_id
        auth::authority::batch_sync
        auth::authority::create
        auth::sync::job::get
        auth::sync::job::get_entries
        auth::sync::job::get_entry
        util_sets_equal_p
    } \
    sync_batch_ims_example_doc {
    Test IMS Enterprise 1.1 batch sync with the XML document from the specification.
} {
    aa_stub acs_sc::invoke {

        if { $contract eq "auth_sync_retrieve" && $operation eq "GetDocument" } {
            array set result {
                doc_status ok
                doc_message {}
                document {}
                snapshot_p f
            }

            # Example document grabbed pulled from
            # http://www.imsglobal.org/enterprise/entv1p1/imsent_bestv1p1.html#1404584
            set result(document) {
<enterprise>
  <properties>
    <datasource>Dunelm Services Limited</datasource>
    <target>Telecommunications LMS</target>
    <type>DATABASE UPDATE</type>
    <datetime>2001-08-08</datetime>
  </properties>
  <person recstatus = "1">
    <comments>Add a new Person record.</comments>
    <sourcedid>
      <source>Dunelm Services Limited</source>
      <id>CK1</id>
    </sourcedid>
    <name>
      <fn>Clark Kent</fn>
      <sort>Kent, C</sort>
      <nickname>Superman</nickname>
    </name>
    <demographics>
      <gender>2</gender>
    </demographics>
    <adr>
      <extadd>The Daily Planet</extadd>
      <locality>Metropolis</locality>
      <country>USA</country>
    </adr>
  </person>
  <person recstatus = "2">
    <comments>Update a previously created record.</comments>
    <sourcedid>
      <source>Dunelm Services Limited</source>
      <id>CS1</id>
    </sourcedid>
    <name>
      <fn>Colin Smythe</fn>
      <sort>Smythe, C</sort>
      <nickname>Colin</nickname>
      <n>
        <family>Smythe</family>
        <given>Colin</given>
        <other>Manfred</other>
        <other>Wingarde</other>
        <prefix>Dr.</prefix>
        <suffix>C.Eng</suffix>
        <partname partnametype = "Initials">C.M.W.</partname>
      </n>
    </name>
    <demographics>
      <gender>2</gender>
      <bday>1958-02-18</bday>
      <disability>None.</disability>
    </demographics>
    <email>colin@dunelm.com</email>
    <url>http://www.dunelm.com</url>
    <tel teltype = "Mobile">4477932335019</tel>
    <adr>
      <extadd>Dunelm Services Limited</extadd>
      <street>34 Acorn Drive</street>
      <street>Stannington</street>
      <locality> Sheffield</locality>
      <region>S.Yorks</region>
      <pcode>S7 6WA</pcode>
      <country>UK</country>
    </adr>
    <photo imgtype = "gif">
      <extref>http://www.dunelm.com/staff/colin2.gif</extref>
    </photo>
    <institutionrole primaryrole = "No" institutionroletype = "Alumni"/>
    <datasource>dunelm:colinsmythe:1</datasource>
  </person>
  <person recstatus = "3">
    <comments>Delete this record.</comments>
    <sourcedid>
      <source>Dunelm Services Limited</source>
      <id>LL1</id>
    </sourcedid>
    <name>
      <fn>Lois Lane</fn>
      <sort>Lane, L</sort>
    </name>
  </person>
</enterprise>
}

            return [array get result]
        } else {
            acs_sc::invoke_unstubbed \
                -contract $contract \
                -operation $operation \
                -impl $impl \
                -impl_id $impl_id \
                -call_args $call_args \
                -error=$error_p
        }
    }

    aa_run_with_teardown \
        -rollback \
        -test_code {

            # Create a new dummy authority with the dummy IMS get-document driver and the IMS Enterprise 1.1 process driver.
            array set new_auth {
                short_name dummy-test
                pretty_name dummy-test
                enabled_p t
                sort_order 999
                auth_impl_id {}
                pwd_impl_id {}
                forgotten_pwd_url {}
                change_pwd_url {}
                register_impl_id {}
                register_url {}
                help_contact_text {}
                batch_sync_enabled_p f
            }
            set new_auth(get_doc_impl_id) 1
            set new_auth(process_doc_impl_id) [acs_sc::impl::get_id -owner "acs-authentication" -name "IMS_Enterprise_v_1p1"]

            set new_auth(get_doc_impl_id) [acs_sc::impl::get_id -owner "acs-authentication" -name "HTTPGet"]

            set authority_id [auth::authority::create \
                                  -array new_auth]

            set job_id [auth::authority::batch_sync -authority_id $authority_id]

            auth::sync::job::get -job_id $job_id -array job

            aa_equals "Number of actions" $job(num_actions) 3

            aa_equals "Number of problems" $job(num_problems) 3

            foreach entry_id [auth::sync::job::get_entries -job_id $job_id] {
                array unset entry
                auth::sync::job::get_entry \
                    -entry_id $entry_id \
                    -array entry

                aa_false "Success_p is false" [template::util::is_true $entry(success_p)]

                array unset elm_msgs
                array set elm_msgs $entry(element_messages)

                aa_log "entry.operation = '$entry(operation)'"
                aa_log "entry.username = '$entry(username)'"
                aa_log "entry.message = '$entry(message)'"
                aa_log "array names elm_msgs = '[array names elm_msgs]'"

                switch $entry(operation) {
                    insert {
                        aa_true "email has a problem (email missing)" [util_sets_equal_p { email } [array names elm_msgs]]
                    }
                    update {
                        aa_true "User does not exist" {$entry(message) ne ""}
                    }
                    delete {
                        aa_false "Message is not empty" {$entry(message) eq ""}
                    }
                }
            }

            aa_log "job.message = '$job(message)'"

        }
}


aa_register_case \
    -cats {api} \
    -procs {
        acs_sc::impl::get_id
        acs_user::get
        acs_user::get_user_info
        ad_generate_random_string
        auth::authority::batch_sync
        auth::authority::create
        auth::driver::set_parameter_value
        auth::sync::GetElements
        auth::sync::job::get
        auth::sync::job::get_entries
        auth::sync::job::get_entry
    } \
    sync_batch_ims_test {
    Test IMS Enterprise 1.1 batch sync with a constructed document which actually works
} {
    aa_stub acs_sc::invoke {

        if { $contract eq "auth_sync_retrieve" && $operation eq "GetDocument" } {
            array set result {
                doc_status ok
                doc_message {}
                document {}
            }

            global ims_doc

            set result(document) "<enterprise>
  <person recstatus=\"$ims_doc(recstatus)\">
    <sourcedid>
      <id>$ims_doc(username)</id>
    </sourcedid>
    <name>
      <fn>$ims_doc(first_names) $ims_doc(last_name)</fn>
      <n>
        <given>$ims_doc(first_names)</given>
        <family>$ims_doc(last_name)</family>
      </n>
    </name>
    <email>$ims_doc(email)</email>
    <url>$ims_doc(url)</url>
  </person>
</enterprise>"

            return [array get result]
        } else {
            acs_sc::invoke_unstubbed \
                -contract $contract \
                -operation $operation \
                -impl $impl \
                -impl_id $impl_id \
                -call_args $call_args \
                -error=$error_p
        }
    }

    aa_run_with_teardown \
        -rollback \
        -test_code {

            # Create a new dummy authority with the dummy IMS get-document driver and the IMS Enterprise 1.1 process driver.
            array set new_auth {
                short_name dummy-test
                pretty_name dummy-test
                enabled_p t
                sort_order 999
                auth_impl_id {}
                pwd_impl_id {}
                forgotten_pwd_url {}
                change_pwd_url {}
                register_impl_id {}
                register_url {}
                help_contact_text {}
                batch_sync_enabled_p f
            }

            set new_auth(process_doc_impl_id) [acs_sc::impl::get_id -owner "acs-authentication" -name "IMS_Enterprise_v_1p1"]
            set new_auth(get_doc_impl_id) [acs_sc::impl::get_id -owner "acs-authentication" -name "HTTPGet"]

            set authority_id [auth::authority::create \
                                  -array new_auth]


            global ims_doc

            #####
            #
            # Insert
            #
            #####

            aa_log "--- Insert test ---"

            # 1 = insert operation
            set ims_doc(recstatus) 1

            # dummy user variables
            set ims_doc(username) [ad_generate_random_string]
            set ims_doc(first_names) [ad_generate_random_string]
            set ims_doc(last_name) [ad_generate_random_string]
            set ims_doc(email) [string tolower "[ad_generate_random_string]@foo.bar"]
            set ims_doc(url) "http://www.[ad_generate_random_string].com"

            set job_id [auth::authority::batch_sync -authority_id $authority_id]

            auth::sync::job::get -job_id $job_id -array job

            aa_equals "Number of actions" $job(num_actions) 1
            aa_equals "Number of problems" $job(num_problems) 0
            aa_log "job.message = '$job(message)'"

            set entry_id [auth::sync::job::get_entries -job_id $job_id]
            aa_equals "One entry" [llength $entry_id] 1

            array unset entry
            auth::sync::job::get_entry -entry_id $entry_id -array entry

            aa_log "entry.message = '$entry(message)'"
            aa_log "entry.element_messages = '$entry(element_messages)'"

            set user [acs_user::get -user_id $entry(user_id)]

            foreach varname { username first_names last_name email url } {
                aa_equals "$varname" [dict get $user $varname] $ims_doc($varname)
            }
            aa_equals "authority_id" [dict get $user authority_id] $authority_id
            aa_false "member_state not banned" {[dict get $user member_state] eq "banned"}
            # saving this for later
            set first_user_id $entry(user_id)


            #####
            #
            # Update
            #
            #####

            aa_log "--- Update test ---"

            # 2 = update operation
            set ims_doc(recstatus) 2

            # dummy user variables
            # username is unchanged
            set ims_doc(first_names) [ad_generate_random_string]
            set ims_doc(last_name) [ad_generate_random_string]
            set ims_doc(email) [string tolower "[ad_generate_random_string]@foo.bar"]
            set ims_doc(url) "http://www.[ad_generate_random_string].com"

            set job_id [auth::authority::batch_sync -authority_id $authority_id]

            auth::sync::job::get -job_id $job_id -array job

            aa_equals "Number of actions" $job(num_actions) 1
            aa_equals "Number of problems" $job(num_problems) 0
            aa_log "job.message = '$job(message)'"

            set entry_id [auth::sync::job::get_entries -job_id $job_id]
            aa_equals "One entry" [llength $entry_id] 1

            array unset entry
            auth::sync::job::get_entry -entry_id $entry_id -array entry

            aa_log "entry.message = '$entry(message)'"
            aa_log "entry.element_messages = '$entry(element_messages)'"

            set user [acs_user::get -user_id $entry(user_id)]

            foreach varname { username first_names last_name email url } {
                aa_equals "$varname" [dict get $user $varname] $ims_doc($varname)
            }
            aa_false "member_state not banned" {[dict get $user member_state] eq "banned"}

            #####
            #
            # Delete
            #
            #####

            aa_log "--- Delete test ---"

            # 3 = delete operation
            set ims_doc(recstatus) 3

            # user variables stay the same, we are deleting

            set job_id [auth::authority::batch_sync -authority_id $authority_id]

            auth::sync::job::get -job_id $job_id -array job

            aa_equals "Number of actions" $job(num_actions) 1
            aa_equals "Number of problems" $job(num_problems) 0
            aa_log "job.message = '$job(message)'"

            set entry_id [auth::sync::job::get_entries -job_id $job_id]
            aa_equals "One entry" [llength $entry_id] 1

            array unset entry
            auth::sync::job::get_entry -entry_id $entry_id -array entry

            aa_log "entry.message = '$entry(message)'"
            aa_log "entry.element_messages = '$entry(element_messages)'"
            aa_log "entry.user_id = '$entry(user_id)'"

            set user_info [acs_user::get_user_info -user_id $entry(user_id)]
            aa_equals "username"     [dict get $user_info username]     $ims_doc(username)
            aa_equals "member_state" [dict get $user_info member_state] "banned"

            #####
            #
            # Reuse username and email. This should fail, as we don't
            # allow 'stealing' usernames from banned users.
            #
            #####

            aa_log "--- Reuse username/email of a deleted user test ---"

            # 1 = insert operation
            set ims_doc(recstatus) 1

            # attributes of the previously deletes user
            set old_doc [array get ims_doc]

            # dummy user variables
            # same username
            set ims_doc(first_names) [ad_generate_random_string]
            set ims_doc(last_name)   [ad_generate_random_string]
            # same email
            set ims_doc(url) "http://www.[ad_generate_random_string].com"

            set job_id [auth::authority::batch_sync -authority_id $authority_id]

            auth::sync::job::get -job_id $job_id -array job

            # operation has failed because user exists already
            aa_equals "Number of actions" $job(num_actions) 1
            aa_equals "Number of problems" $job(num_problems) 1
            aa_log "job.message = '$job(message)'"

            set entry_id [auth::sync::job::get_entries -job_id $job_id]
            aa_equals "One entry" [llength $entry_id] 1

            array unset entry
            auth::sync::job::get_entry -entry_id $entry_id -array entry

            aa_log "entry.message = '$entry(message)'"
            aa_log "entry.element_messages = '$entry(element_messages)'"
            aa_log "entry.user_id = '$entry(user_id)'"

            # all attributes remained the same
            set user [acs_user::get -user_id $entry(user_id)]
            foreach varname { username email first_names last_name url } {
                aa_true "$varname" {[dict get $user $varname] eq [dict get $old_doc $varname]}
            }
            aa_equals "authority_id" [dict get $user authority_id] $authority_id
            # previously deleted user keeps being banned
            aa_true "member_state is still banned" {[dict get $user member_state] eq "banned"}

            # Check that first_user_id has had username/email changed

            #####
            #
            # Test GetElements
            #
            #####

            aa_log "--- GetElements test ---"

            set desired_elements [ad_generate_random_string]

            auth::driver::set_parameter_value \
                -authority_id $authority_id \
                -impl_id [acs_sc::impl::get_id -owner "acs-authentication" -name "IMS_Enterprise_v_1p1"] \
                -parameter Elements \
                -value $desired_elements

            set elements [auth::sync::GetElements -authority_id $authority_id]

            aa_equals "Elements are '$desired_elements'" $elements $desired_elements

        }
}

aa_register_case \
    -cats {api smoke} \
    -procs acs_sc::invoke \
    sync_http_get_document {
    Test the HTTPGet implementation of GetDocument service contract.
} {
    set url [ad_url]
    # When the server is configured with wildcard IPv4 address 0.0.0.0
    # and the hostname "localhost", and localhost is mapped on the
    # host to the IPv6 address "::1", then ns_http to
    # http://localhost:.../ is rejected, while the connection to the
    # current IPv4 address http://127.0.0.1:.../ succeeds. However,
    # the determination of the current IP address requires NaviServer
    # 4.99.17d3 or newer, so we can't assume, this works always.
    #
    # If ad_url is empty, try util_current_location instead.
    #
    if {$url eq ""} {
        set url [util_current_location]
    }
    set parsed_url [ns_parseurl $url]
    if {[dict get $parsed_url host] eq "localhost"} {
        set url [dict get $parsed_url proto]://127.0.0.1:[dict get $parsed_url port]
        set url [string trimright $url ":"]
    }
    array set result [acs_sc::invoke \
                          -error \
                          -contract "auth_sync_retrieve" \
                          -impl "HTTPGet" \
                          -operation "GetDocument" \
                          -call_args [list [list SnapshotURL {} IncrementalURL "$url/SYSTEM/dbtest.tcl"]]]


    aa_equals "result.doc_status is ok" $result(doc_status) "ok"
    aa_true "result.doc_message is empty" {$result(doc_message) eq ""}
    aa_equals "result.document is 'success'" $result(document) "success"
}

aa_register_case \
    -cats {api web} \
    -procs {
        acs_sc::invoke
        template::util::read_file
    } \
    sync_file_get_document {
    Test the HTTPGet implementation of GetDocument service contract.
} {
    set path "$::acs::rootdir/www/SYSTEM/dbtest.tcl"

    aa_log "Getting path '$path'"

    array set result [acs_sc::invoke \
                          -error \
                          -contract "auth_sync_retrieve" \
                          -impl "LocalFilesystem" \
                          -operation "GetDocument" \
                          -call_args [list [list SnapshotPath {} IncrementalPath $path]]]

    aa_equals "result.doc_status is ok" $result(doc_status) "ok"
    aa_true "result.doc_message is empty" {$result(doc_message) eq ""}
    aa_equals "result.document is 'success'" $result(document) [template::util::read_file $path]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
