ad_library {
    API for managing synchronization of user data.
    
    @creation-date 2003-09-05
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval auth {}
namespace eval auth::sync {}
namespace eval auth::sync::job {}



ad_proc -public auth::sync::job::get {
    {-job_id:required}
    {-array:required}
    {-include_document:boolean}
} {
    Get information about a batch job in an array.

    @param job_id        The ID of the batch job you're ending.
    
    @param array         Name of an array into which you want the information.
    
    @param include_document
                         Set this switch if you also want the document returned in the array.

    @author Lars Pind (lars@collaboraid.biz)
} {
    upvar 1 $array row

    db_1row select_job {} -column_array row

    # TODO: This is temporary, make sure this is where the UI ends up
    set row(log_url) [export_vars -base "[ad_url]/acs-admin/package/acs-authentication/sync-log" { job_id }]

    if { $include_document_p } {
        # TODO: Return the document once we know how we'll store it
        set job(document) "Not implemented"
    }
}

ad_proc -public auth::sync::job::start {
    {-job_id ""}
    {-authority_id:required}
    {-interactive:boolean}
    {-creation_user ""}
} {
    Record the beginning of a job.

    @param authority_id      The ID of the authority you're trying to sync
    
    @param interactive       Set this if this is an interactive job, i.e. it's initiated by a user.

    @return job_id           An ID for the new batch job. Used when calling other procs in this API.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    db_transaction {
        if { [empty_string_p $job_id] } {
            set job_id [db_nextval "auth_batch_jobs_job_id_seq"]
        }

        if { $interactive_p && [empty_string_p $creation_user] } {
            set creation_user [ad_conn user_id]
        }
        
        db_dml job_insert {
            insert into auth_batch_jobs
            (job_id, interactive_p, creation_user)
            values
            (:job_id, :interactive_p, :creation_user)
        }
    }
    
    return $job_id
}

ad_proc -public auth::sync::job::end {
    {-job_id:required}
} {
    Record the end of a batch job. Closes out the transaction 
    log and sends out notifications.

    @param job_id        The ID of the batch job you're ending.

    @return array list with result of auth::sync::job::get.

    @see auth::sync::job::get

    @author Lars Pind (lars@collaboraid.biz)
} {
    db_dml set_end_time {
        update auth_batch_jobs
        set    job_end_time = current_timestamp
        where  job_id = :job_id
    }
    
    # interactive_p, run_time_seconds, num_actions, num_problems
    get -job_id $job_id -array job
        
    if { ![template::util::is_true $job(interactive_p)] } {
        # Only send out email if not an interactive job

        with_catch errmsg {
            ns_sendmail \
                [ad_system_owner] \
                [ad_system_owner] \
                "Batch sync completed" \
                "Batch user synchronization is complete.\n\nRunning time: $job(run_time_seconds) seconds\nNumber of actions: $job(num_actions)\nNumber of problems: $job(num_problems)\n\nTo view the log, please visit\n$job(log_url)"
        } {
            # We don't fail hard here, just log an error
            global errorInfo
            ns_log Error "Error sending registration confirmation to [ad_system_owner].\n$errorInfo"
        }
    }
    
    return [array get job]
}

ad_proc -public auth::sync::job::start_get_document {
    {-job_id:required}
} {
    Record the that we're starting to get the document.

    @param job_id The ID of the batch job you're ending.
} {
    db_dml update_doc_start_time {}
}

ad_proc -public auth::sync::job::end_get_document {
    {-job_id:required}
    {-doc_status:required}
    {-doc_message ""}
    {-document ""}
} {
    Record the that we've finished getting the document, and record the status.

    @param job_id The ID of the batch job you're ending.
} {
    # TODO: Create cr_item containing document. Talk to Jun Kyamog about a CR API
    set document_id {}

    db_dml update_doc_end {}
}

ad_proc -public auth::sync::job::create_entry {
    {-job_id:required}
    {-operation:required}
    {-authority_id:required}
    {-username:required}
    {-user_id ""}
    {-success:boolean}
    {-message ""}
    {-element_messages ""}
} {
    Record a batch job entry.

    @param job_id The ID of the batch job you're ending.
    
    @param operation One of 'insert', 'update', or 'delete'.

    @param authority_id The authority this is about
    
    @param username The username of the user being inserted/updated/deleted.
    
    @param user_id The user_id of the local user account, if known.

    @param success Whether or not the operation went well.
    
    @param message Any error message to stick into the log.
    
    @return entry_id
} {
    set success_p_db [ad_decode $success_p 1 "t" "f"]

    set entry_id [db_nextval "auth_batch_job_entry_id_seq"]

    db_dml insert_entry {} -clobs [list $element_messages]

    return $entry_id
}

ad_proc -public auth::sync::job::get_entry {
    {-entry_id:required}
    {-array:required}
} { 
    Get information about a log entry
} {
    upvar 1 $array row

    db_1row select_entry {
        select   entry_id,
                 job_id,
                 entry_time,
                 operation,
                 authority_id,
                 username,
                 user_id,
                 success_p,
                 message,
                 element_messages
        from     auth_batch_job_entries
        where    entry_id = :entry_id
    } -column_array row
}


ad_proc -public auth::sync::job::action {
    {-job_id:required}
    {-operation:required}
    {-authority_id:required}
    {-username:required}
    {-first_names ""}
    {-last_name ""}
    {-email ""}
    {-url ""}
    {-portrait_url ""}
} {
    Inserts/updates/deletes a user, depending on the operation.

    @param job_id        The job which this is part of for logging purposes.
    
    @param operation     'insert', 'update', 'delete', or 'snapshot'.
    
    @param authority_id  The authority involved

    @param username      The username which this action refers to. 
    
    @return entry_id of newly created entry
} {
    set entry_id {}
    set user_id {}

    db_transaction {
        # We deal with insert/update in a snaphsot sync here
        if { [string equal $operation "snapshot"] } {
            set user_id [acs_user::get_by_username \
                             -authority_id $authority_id \
                             -username $username]
            
            if { ![empty_string_p $user_id] } {
                # user exists, it's an update
                set operation "update"
            } else {
                # user does not exist, it's an insert
                set operation "insert"
            }
        }

        set success_p 1
        array set result {
            message {}
            element_messages {}
        }
        
        with_catch errmsg {
            switch $operation {
                "insert" {
                    # We set email_verified_p to 't', because we trust the email we get from the remote system
                    array set result [auth::create_local_account \
                                          -authority_id $authority_id \
                                          -username $username \
                                          -first_names $first_names \
                                          -last_name $last_name \
                                          -email $email \
                                          -email_verified_p "t" \
                                          -url $url]

                    if { ![string equal $result(creation_status) "ok"] } {
                        set result(message) $result(creation_message)
                        set success_p 0
                    } else {
                        set user_id $result(user_id)
                    }

                    # We ignore account_status
                }
                "update" {
                    # We set email_verified_p to 't', because we trust the email we get from the remote system
                    array set result [auth::update_local_account \
                                          -authority_id $authority_id \
                                          -username $username \
                                          -first_names $first_names \
                                          -last_name $last_name \
                                          -email $email \
                                          -email_verified_p "t" \
                                          -url $url]
                    
                    if { ![string equal $result(update_status) "ok"] } {
                        set result(message) $result(update_message)
                        set success_p 0
                    } else {
                        set user_id $result(user_id)
                    }
                }
                "delete" {
                    array set result [auth::delete_local_account \
                                          -authority_id $authority_id \
                                          -username $username]
                    
                    if { ![string equal $result(delete_status) "ok"] } {
                        set result(message) $result(delete_message)
                        set success_p 0
                    } else {
                        set user_id $result(user_id)
                    }
                }
            }
        } {
            # Get errorInfo and log it
            global errorInfo
            ns_log Error "Error during batch syncrhonization job:\n$errorInfo"
            set success_p 0
            set result(message) $errorInfo
        }

        # Make a log entry
        set entry_id [auth::sync::job::create_entry \
                          -job_id $job_id \
                          -operation $operation \
                          -authority_id $authority_id \
                          -username $username \
                          -user_id $user_id \
                          -success=$success_p \
                          -message $result(message) \
                          -element_messages $result(element_messages)]
    }

    return $entry_id
}

ad_proc -public auth::sync::job::snapshot_delete_remaining {
    -job_id:required
    -authority_id:required
} {
    Deletes the users that weren't included in the snapshot.
} {
    set usernames [db_list select_user_ids {
        select username
        from   cc_users
        where  authority_id = :authority_id
        and    user_id not in (select user_id from auth_batch_job_entries where job_id = :job_id and authority_id = :authority_id)
        and    member_state != 'banned'
    }]

    foreach username $usernames {
        auth::sync::job::action \
            -job_id $job_id \
            -operation "delete" \
            -authority_id [auth::authority::local] \
            -username $username
    }
}






ad_proc -public auth::sync::purge_jobs {} {
    Purge jobs that are older than KeepBatchLogDays days.
} {
    # Don't forget to also delete the cr_item referenced by the auth_batch_jobs.document column.

    # Parameter: KeepBatchLogDays - number of days to keep batch job log around. 0 = forever.

    # TODO
}






