ad_library {
    API for managing synchronization of user data.
    
    @creation-date 2003-09-05
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval auth {}
namespace eval auth::sync {}
namespace eval auth::sync::job {}
namespace eval auth::sync::get_doc {}
namespace eval auth::sync::get_doc::http {}
namespace eval auth::sync::entry {}
namespace eval auth::sync::process_doc {}
namespace eval auth::sync::process_doc::ims {}

#####
#
# auth::sync::job namespace
#
#####

ad_proc -public auth::sync::job::get {
    {-job_id:required}
    {-array:required}
} {
    Get information about a batch job in an array.

    @param job_id        The ID of the batch job you're ending.
    
    @param array         Name of an array into which you want the information.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    upvar 1 $array row

    db_1row select_job {} -column_array row

    # TODO: This is temporary, make sure this is where the UI ends up
    set row(log_url) [export_vars -base "[ad_url]/acs-admin/package/acs-authentication/sync-log" { job_id }]
}

ad_proc -public auth::sync::job::get_entries {
    {-job_id:required}
} {
    Get a list of entry_ids of the job log entries, ordered by entry_time.

    @param job_id        The ID of the batch job you're ending.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    return [db_list select_entries { select entry_id from auth_batch_job_entries where job_id = :job_id order by entry_time }]
}

ad_proc -public auth::sync::job::get_authority_id {
    {-job_id:required}
} {
    Get the authority_id from a job_id. Cached.

    @param job_id        The ID of the batch job you're ending.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    return [util_memoize [list auth::sync::job::get_authority_id_not_cached $job_id]]
}

ad_proc -private auth::sync::job::get_authority_id_flush {
    {-job_id ""}
} {
    Flush cache

    @param job_id        The ID of the batch job you're ending.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    if { ![empty_string_p $job_id] } {
        util_memoize_flush [list auth::sync::job::get_authority_id_not_cached $job_id]
    } else {
        util_memoize_flush_regexp [list auth::sync::job::get_authority_id_not_cached .*]
    }
}

ad_proc -private auth::sync::job::get_authority_id_seed {
    {-job_id:required}
    {-authority_id:required}
} {
    Flush cache

    @param job_id        The ID of the batch job you're ending.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    util_memoize_seed [list auth::sync::job::get_authority_id_not_cached $job_id] $authority_id
}

ad_proc -private auth::sync::job::get_authority_id_not_cached {
    job_id
} {
    Get the authority_id from a job_id. Not cached.

    @param job_id        The ID of the batch job you're ending.
    
    @author Lars Pind (lars@collaboraid.biz)
    
    @see auth::sync::job::get_authority_id
} {
    return [db_string select_auth_id { select authority_id from auth_batch_jobs where job_id = :job_id }]
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
        
        set interactive_p [db_boolean $interactive_p]

        db_dml job_insert {
            insert into auth_batch_jobs
            (job_id, interactive_p, creation_user, authority_id)
            values
            (:job_id, :interactive_p, :creation_user, :authority_id)
        }

    }
    
    # See the cache, we're going to need it shortly
    auth::sync::job::get_authority_id_seed -job_id $job_id -authority_id $authority_id

    return $job_id
}

ad_proc -public auth::sync::job::end {
    {-job_id:required}
    {-message ""}
} {
    Record the end of a batch job. Closes out the transaction 
    log and sends out notifications.

    @param job_id        The ID of the batch job you're ending.

    @return array list with result of auth::sync::job::get.

    @see auth::sync::job::get

    @author Lars Pind (lars@collaboraid.biz)
} {
    db_dml update_job_end {}
    
    # interactive_p, run_time_seconds, num_actions, num_problems
    get -job_id $job_id -array job
        
    if { ![template::util::is_true $job(interactive_p)] } {
        # Only send out email if not an interactive job

        with_catch errmsg {
            ns_sendmail \
                [ad_system_owner] \
                [ad_system_owner] \
                "Batch user synchronization for $job(authority_pretty_name) complete" \
                "Batch user synchronization for $job(authority_pretty_name) is complete.

Authority         : $job(authority_pretty_name)
Running time      : $job(run_time_seconds) seconds
Number of actions : $job(num_actions)
Number of problems: $job(num_problems)
Job message       : $job(message)

To view the complete log, please visit\n$job(log_url)"
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
    {-snapshot:boolean}
} {
    Record the that we've finished getting the document, and record the status.

    @param job_id The ID of the batch job you're ending.

    @param snapshot          Set this if this is a snapshot job, as opposed to an incremental ('event driven') job.
} {
    set snapshot_p [db_boolean $snapshot_p]

    db_dml update_doc_end {} -clobs [list $document]
}

ad_proc -public auth::sync::job::create_entry {
    {-job_id:required}
    {-operation:required}
    {-username:required}
    {-user_id ""}
    {-success:boolean}
    {-message ""}
    {-element_messages ""}
} {
    Record a batch job entry.

    @param job_id The ID of the batch job you're ending.
    
    @param operation One of 'insert', 'update', or 'delete'.

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
        select e.entry_id,
               e.job_id,
               e.entry_time,
               e.operation,
               j.authority_id,
               e.username,
               e.user_id,
               e.success_p,
               e.message,
               e.element_messages
        from   auth_batch_job_entries e,
               auth_batch_jobs j
        where  e.entry_id = :entry_id
        and    j.job_id = e.job_id
    } -column_array row
}


ad_proc -public auth::sync::job::action {
    {-job_id:required}
    {-operation:required}
    {-username:required}
    {-array ""}
} {
    Inserts/updates/deletes a user, depending on the operation.

    @param job_id        The job which this is part of for logging purposes.
    
    @param operation     'insert', 'update', 'delete', or 'snapshot'.
    
    @param username      The username which this action refers to. 
    
    @param array         Name of an array containing the relevant registration elements. Not required if this is a delete operation.
    
    @return entry_id of newly created entry
} {
    if { ![string equal $operation "delete"] && [empty_string_p $array] } {
        error "Switch -array is required when operation is not delete"
    }
    upvar 1 $array user_info
    
    set entry_id {}
    set user_id {}

    set authority_id [get_authority_id -job_id $job_id]

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
                                          -array user_info]

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
                                          -array user_info]
                    
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
                          -username $username \
                          -user_id $user_id \
                          -success=$success_p \
                          -message $result(message) \
                          -element_messages $result(element_messages)]
    }

    return $entry_id
}

ad_proc -public auth::sync::job::snapshot_delete_remaining {
    {-job_id:required}
} {
    Deletes the users that weren't included in the snapshot.
} {
    set authority_id [get_authority_id -job_id $job_id]

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
            -username $username
    }
}


#####
#
# auth::sync namespace
#
#####

ad_proc -public auth::sync::purge_jobs {
    {-num_days ""}
} {
    Purge jobs that are older than KeepBatchLogDays days.
} {
    if { ![exists_and_not_null num_days] } {
        set num_days [parameter::get_from_package_key -parameter KeepBatchLogDays -package_key "acs-authentication" -default 0]
    }
    
    validate_integer num_days $num_days

    if { $num_days > 0 } { 
        db_dml purge_jobs {}
    }
}

ad_proc -private auth::sync::get_sync_elements {
    {-user_id ""}
    {-authority_id ""}
} {
    Get a Tcl list of the user profile elements controlled by the batch synchronization. 
    These should not be editable by the user. Supply either user_id or authority_id. 
    Authority_id is the most efficient.
} {
    if { [empty_string_p $authority_id] } {
        if { [empty_string_p $user_id] } {
            error "You must supply either user_id or authority_id"
        }
        set authority_id [acs_user::get_element -user_id $user_id -element authority_id]
    }

    set elms [list]
    with_catch errmsg {
        set elms [auth::sync::GetElements -authority_id $authority_id]
    } {}

    return $elms
}

ad_proc -private auth::sync::sweeper {} {
    db_foreach select_authorities {
        select authority_id
        from   auth_authorities
        where  enabled_p = 't'
        and    batch_sync_enabled_p = 't'
    } {
        auth::authority::batch_sync \
            -authority_id $authority_id
    }
}

ad_proc -private auth::sync::GetDocument {
    {-authority_id:required}
} {
    Wrapper for the GetDocument operation of the auth_sync_retrieve service contract.
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "get_doc_impl_id"]

    if { [empty_string_p $impl_id] } {
        # No implementation of GetDocument
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support GetDocument"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -contract "auth_sync_retrieve" \
                -impl_id $impl_id \
                -operation GetDocument \
                -call_args [list $parameters]]
}

ad_proc -private auth::sync::ProcessDocument {
    {-authority_id:required}
    {-job_id:required}
    {-document:required}
} {
    Wrapper for the ProcessDocument operation of the auth_sync_process service contract.
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "process_doc_impl_id"]

    if { [empty_string_p $impl_id] } {
        # No implementation of auth_sync_process
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support auth_sync_process"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -contract "auth_sync_process" \
                -impl_id $impl_id \
                -operation ProcessDocument \
                -call_args [list $job_id $document $parameters]]
}

ad_proc -private auth::sync::GetElements {
    {-authority_id:required}
} {
    Wrapper for the GetElements operation of the auth_sync_process service contract.
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "process_doc_impl_id"]

    if { [empty_string_p $impl_id] } {
        # No implementation of auth_sync_process
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support auth_sync_process"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -contract "auth_sync_process" \
                -impl_id $impl_id \
                -operation GetElements \
                -call_args [list $parameters]]
}





#####
#
# auth::sync::get_doc::http namespace
#
#####

ad_proc -private auth::sync::get_doc::http::register_impl {} {
    Register this implementation
} {
    set spec {
        contract_name "auth_sync_retrieve"
        owner "acs-authentication"
        name "HTTPGet"
        pretty_name "HTTP GET"
        aliases {
            GetDocument auth::sync::get_doc::http::GetDocument
            GetParameters auth::sync::get_doc::http::GetParameters
        }
    }

    return [acs_sc::impl::new_from_spec -spec $spec]

}

ad_proc -private auth::sync::get_doc::http::unregister_impl {} {
    Unregister this implementation
} {
    acs_sc::impl::delete -contract_name "auth_sync_retrieve" -impl_name "HTTPGet"
}

ad_proc -private auth::sync::get_doc::http::GetParameters {} {
    Parameters for HTTP GetDocument implementation.
} {
    return {
        IncrementalURL {The URL from which to retrieve document for incremental update. Will retrieve this most of the time.}
        SnapshotURL {The URL from which to retrieve document for snapshot update. If specified, will get this once per month.}
    }
}

ad_proc -private auth::sync::get_doc::http::GetDocument {
    parameters
} {
    Retrieve the document by HTTP
} {
    array set result {
        doc_status failed_to_conntect
        doc_message {}
        document {}
        snapshot_p f
    }
    
    array set param $parameters
    
    if { (![empty_string_p $param(SnapshotURL)] && [string equal [clock format [clock seconds] -format "%d"] "01"]) || \
             [empty_string_p $param(IncrementalURL)] } {

        # On the first day of the month, we get a snapshot
        set url $param(SnapshotURL)
        set result(snapshot_p) "t"
    } else {
        # All the other days of the month, we get the incremental
        set url $param(IncrementalURL)
    }

    if { [empty_string_p $url] } {
        error "You must specify at least one URL to get."
    }

    set result(document) [util_httpget $url]

    set result(doc_status) "ok"

    return [array get result]
}



#####
#
# auth::sync::process_doc::ims namespace
#
#####

ad_proc -private auth::sync::process_doc::ims::register_impl {} {
    Register this implementation
} {
    set spec {
        contract_name "auth_sync_process"
        owner "acs-authentication"
        name "IMS_Enterprise_v_1p1"
        pretty_name "IMS Enterprise 1.1"
        aliases {
            ProcessDocument auth::sync::process_doc::ims::ProcessDocument
            GetElements auth::sync::process_doc::ims::GetElements
            GetParameters auth::sync::process_doc::ims::GetParameters
        }
    }

    return [acs_sc::impl::new_from_spec -spec $spec]

}

ad_proc -private auth::sync::process_doc::ims::unregister_impl {} {
    Unregister this implementation
} {
    acs_sc::impl::delete -contract_name "auth_sync_process" -impl_name "IMS_Enterprise_v_1p1"
}

ad_proc -private auth::sync::process_doc::ims::GetParameters {} {
    Parameters for IMS Enterprise 1.1 auth_sync_process implementation.
} {
    return {}
}


ad_proc -private auth::sync::process_doc::ims::GetElements {
    parameters
} {
    Elements controlled by IMS Enterprise 1.1 auth_sync_process implementation.
} {
    return { username email first_names last_name url }
}

ad_proc -private auth::sync::process_doc::ims::ProcessDocument {
    job_id
    document
    parameters
} {
    Process IMS Enterprise 1.1 document.
} {
    set tree [xml_parse -persist $document]

    set root_node [xml_doc_get_first_node $tree]

    if { ![string equal [xml_node_get_name $root_node] "enterprise"] } {
        error "Root node was not <enterprise>"
    }

    # Loop over <person> records
    foreach person_node [xml_node_get_children_by_name $root_node "person"] {
        switch [xml_node_get_attribute $person_node "recstatus"] {
            1 {
                set operation "insert"
            }
            2 { 
                set operation "update"
            }
            3 {
                set operation "delete"
            }
            default {
                set operation "snapshot"
            }
        }

        # Initialize this record
        array unset user_info

        set username [xml_get_child_node_content_by_path $person_node { { userid } { sourcedid id } }]

        set user_info(email) [xml_get_child_node_content_by_path $person_node { { email } }]
        set user_info(url) [xml_get_child_node_content_by_path $person_node { { url } }]

        # We need a little more logic to deal with first_names/last_name, since they may not be split up in the XML
        set user_info(first_names) [xml_get_child_node_content_by_path $person_node { { n given } }]
        set user_info(last_name) [xml_get_child_node_content_by_path $person_node { { n family } }]

        if { [empty_string_p $user_info(first_names)] || [empty_string_p $user_info(last_name)] } {
            set formatted_name [xml_get_child_node_content_by_path $person_node { { name fn } }]
            if { ![empty_string_p $formatted_name] || [string first " " $formatted_name] > -1 } {
                # Split, so everything up to the last space goes to first_names, the rest to last_name
                regexp {^(.+) ([^ ]+)$} $formatted_name match user_info(first_names) user_info(last_name)
            }
        }

        auth::sync::job::action \
            -job_id $job_id \
            -operation $operation \
            -username $username \
            -array user_info
    }
}
