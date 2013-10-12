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
namespace eval auth::sync::get_doc::file {}
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

    set row(log_url) [export_vars -base "[ad_url]/acs-admin/auth/batch-job" { job_id }]
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
    if { $job_id ne "" } {
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
        if { $job_id eq "" } {
            set job_id [db_nextval "auth_batch_jobs_job_id_seq"]
        }

        if { $interactive_p && $creation_user eq "" } {
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

    set email_p [parameter::get_from_package_key \
                     -parameter SyncEmailConfirmationP \
                     -package_key "acs-authentication" \
                     -default 0] 

    if { ![template::util::is_true $job(interactive_p)] && $email_p } {
        # Only send out email if not an interactive job

        with_catch errmsg {
            acs_mail_lite::send -send_immediately \
                -to_addr [ad_system_owner] \
                -from_addr [ad_system_owner] \
                -subject "Batch user synchronization for $job(authority_pretty_name) complete" \
                -body "Batch user synchronization for $job(authority_pretty_name) is complete.

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
    if { $operation ne "delete" && $array eq "" } {
        error "Switch -array is required when operation is not delete"
    }
    upvar 1 $array user_info
    
    set entry_id {}
    set user_id {}

    set authority_id [get_authority_id -job_id $job_id]

    db_transaction {
        set user_id [acs_user::get_by_username \
                         -authority_id $authority_id \
                         -username $username]
        
        set success_p 1
        array set result {
            message {}
            element_messages {}
        }
        
        switch $operation {
            snapshot {
                if { $user_id ne "" } {
                    # user exists, it's an update
                    set operation "update"
                } else {
                    # user does not exist, it's an insert
                    set operation "insert"
                }
            }
            update - delete {
                if { $user_id eq "" } {
                    # Updating/deleting a user that doesn't exist
                    set success_p 0
                    set result(message) "A user with username '$username' does not exist"
                } else {
                    acs_user::get -user_id $user_id -array existing_user_info
                    if {$existing_user_info(member_state) eq "banned"} {
                        # Updating/deleting a user that's already deleted
                        set success_p 0
                        set result(message) "The user with username '$username' has been deleted (banned)"
                    }
                }
            }
            insert {
                if { $user_id ne "" } {
                    acs_user::get -user_id $user_id -array existing_user_info
                    if { $existing_user_info(member_state) ne "banned" } {
                        # Inserting a user that already exists (and is not deleted)
                        set success_p 0
                        set result(message) "A user with username '$username' already exists"
                    }
                }
            }
        }

        # Only actually perform the action if we didn't already encounter a problem
        if { $success_p } {
            with_catch errmsg {
                switch $operation {
                    "insert" {
                        # We set email_verified_p to 't', because we trust the email we get from the remote system
                        set user_info(email_verified_p) t

                        array set result [auth::create_local_account \
                                              -authority_id $authority_id \
                                              -username $username \
                                              -array user_info]

                        if { $result(creation_status) ne "ok" } {
                            set result(message) $result(creation_message)
                            set success_p 0
                        } else {
                            set user_id $result(user_id)

                            set add_to_dotlrn_p [parameter::get_from_package_key \
                                                     -parameter SyncAddUsersToDotLrnP \
                                                     -package_key "acs-authentication" \
                                                     -default 0]

                            if { $add_to_dotlrn_p } {
                                # Add user to .LRN
                                # Beware that this creates a portal and lots of other things for each user

                                set type [parameter::get_from_package_key \
                                              -parameter SyncDotLrnUserType \
                                              -package_key "acs-authentication" \
                                              -default "student"]

                                set can_browse_p [parameter::get_from_package_key \
                                                      -parameter SyncDotLrnAccessLevel \
                                                      -package_key "acs-authentication" \
                                                      -default 1]

                                set read_private_data_p [parameter::get_from_package_key \
                                                             -parameter SyncDotLrnReadPrivateDataP \
                                                             -package_key "acs-authentication" \
                                                             -default 1]
                                
                                dotlrn::user_add \
                                    -id $user_info(email) \
                                    -type $type \
                                    -can_browse=$can_browse_p \
                                    -user_id $user_id
                                
                                dotlrn_privacy::set_user_is_non_guest \
                                    -user_id $user_id \
                                    -value $read_private_data_p

                            }
                        }

                        # We ignore account_status
                    }
                    "update" {
                        # We set email_verified_p to 't', because we trust the email we get from the remote system
                        set user_info(email_verified_p) t

                        array set result [auth::update_local_account \
                                              -authority_id $authority_id \
                                              -username $username \
                                              -array user_info]
                        
                        if { $result(update_status) ne "ok" } {
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
                        
                        if { $result(delete_status) ne "ok" } {
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
    if { $num_days eq "" } {
        set num_days [parameter::get_from_package_key \
                          -parameter KeepBatchLogDays \
                          -package_key "acs-authentication" \
                          -default 0]
    }
    
    if {![string is integer -strict $num_days]} {
	error "num_days ($num_days) has to be an integer"
    }

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
    if { $authority_id eq "" } {
        if { $user_id eq "" } {
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

    if { $impl_id eq "" } {
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

    if { $impl_id eq "" } {
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

ad_proc -private auth::sync::GetAcknowledgementDocument {
    {-authority_id:required}
    {-job_id:required}
    {-document:required}
} {
    Wrapper for the GetAckDocument operation of the auth_sync_process service contract.
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "process_doc_impl_id"]

    if { $impl_id eq "" } {
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
                -operation GetAcknowledgementDocument \
                -call_args [list $job_id $document $parameters]]
}

ad_proc -private auth::sync::GetElements {
    {-authority_id:required}
} {
    Wrapper for the GetElements operation of the auth_sync_process service contract.
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "process_doc_impl_id"]

    if { $impl_id eq "" } {
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
    
    if { ($param(SnapshotURL) ne "" && [clock format [clock seconds] -format "%d"] eq "01") || \
             $param(IncrementalURL) eq "" } {

        # On the first day of the month, we get a snapshot
        set url $param(SnapshotURL)
        set result(snapshot_p) "t"
    } else {
        # All the other days of the month, we get the incremental
        set url $param(IncrementalURL)
    }

    if { $url eq "" } {
        error "You must specify at least one URL to get."
    }

    set result(document) [util_httpget $url]

    set result(doc_status) "ok"

    return [array get result]
}



#####
#
# auth::sync::get_doc::file namespace
#
#####

ad_proc -private auth::sync::get_doc::file::register_impl {} {
    Register this implementation
} {
    set spec {
        contract_name "auth_sync_retrieve"
        owner "acs-authentication"
        name "LocalFilesystem"
        pretty_name "Local Filesystem"
        aliases {
            GetDocument auth::sync::get_doc::file::GetDocument
            GetParameters auth::sync::get_doc::file::GetParameters
        }
    }

    return [acs_sc::impl::new_from_spec -spec $spec]

}

ad_proc -private auth::sync::get_doc::file::unregister_impl {} {
    Unregister this implementation
} {
    acs_sc::impl::delete -contract_name "auth_sync_retrieve" -impl_name "LocalFilesystem"
}

ad_proc -private auth::sync::get_doc::file::GetParameters {} {
    Parameters for FILE GetDocument implementation.
} {
    return {
        IncrementalPath {The path to the document for incremental update. Will retrieve this most of the time.}
        SnapshotPath {The path to the document for snapshot update. If specified, will get this once per month.}
    }
}

ad_proc -private auth::sync::get_doc::file::GetDocument {
    parameters
} {
    Retrieve the document from local file system
} {
    array set result {
        doc_status failed_to_conntect
        doc_message {}
        document {}
        snapshot_p f
    }
    
    array set param $parameters
    
    if { ($param(SnapshotPath) ne "" && [clock format [clock seconds] -format "%d"] eq "01") || \
             $param(IncrementalPath) eq "" } {

        # On the first day of the month, we get a snapshot
        set path $param(SnapshotPath)
        set result(snapshot_p) "t"
    } else {
        # All the other days of the month, we get the incremental
        set path $param(IncrementalPath)
    }

    if { $path eq "" } {
        error "You must specify at least one path to get."
    }

    set result(document) [template::util::read_file $path]

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
            GetAcknowledgementDocument auth::sync::process_doc::ims::GetAcknowledgementDocument
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
    return {
        Elements {List of elements covered by IMS batch synchronization, which we should prevent users from editing in OpenACS. Example: 'username email first_names last_name url'.}
    }
}


ad_proc -private auth::sync::process_doc::ims::GetElements {
    parameters
} {
    Elements controlled by IMS Enterprise 1.1 auth_sync_process implementation.
} {
    array set param $parameters
    return $param(Elements)
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

    if { [xml_node_get_name $root_node] ne "enterprise" } {
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
        set user_info(first_names) [xml_get_child_node_content_by_path $person_node { { name n given } }]
        set user_info(last_name) [xml_get_child_node_content_by_path $person_node { { name n family } }]

        if { $user_info(first_names) eq "" || $user_info(last_name) eq "" } {
            set formatted_name [xml_get_child_node_content_by_path $person_node { { name fn } }]
            if { $formatted_name ne "" || [string first " " $formatted_name] > -1 } {
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


ad_proc -public auth::sync::process_doc::ims::GetAcknowledgementDocument {
    job_id
    document
    parameters
} {
    Generates an record-wise acknolwedgement document in home-brewed 
    adaptation of the IMS Enterprise v 1.1 spec.
} {
    set tree [xml_parse -persist $document]
    set root_node [xml_doc_get_first_node $tree]
    if { [xml_node_get_name $root_node] ne "enterprise" } {
        error "Root node was not <enterprise>"
    }

    set timestamp [xml_get_child_node_content_by_path $root_node { { properties datetime } }]

    append doc {<?xml version="1.0" encoding="} [ns_config "ns/parameters" OutputCharset] {"?>} \n
    append doc {<enterprise>} \n
    append doc {  <properties>} \n
    append doc {    <type>acknowledgement</type>} \n
    append doc {    <datetime>} $timestamp {</datetime>} \n
    append doc {  </properties>} \n

    array set recstatus {
        insert 1
        update 2
        delete 3
    }

    # Loop over successful actions
    db_foreach select_success_actions {
        select entry_id,
               operation,
               username
        from   auth_batch_job_entries
        where  job_id = :job_id
        and    success_p = 't'
        order  by entry_id
    } {
        if { [info exists recstatus($operation)] } {
            append doc {  <person recstatus="} $recstatus($operation)  {">} \n
            append doc {    <sourcedid><source>OpenACS</source><id>} $username {</id></sourcedid>} \n
            append doc {  </person>} \n
        } else {
            ns_log Error "Illegal operation encountered in job action log: '$operation'. Entry_id is '$entry_id'."
        }
    }

    append doc {</enterprise>} \n
    
    return $doc
}
