ad_library {
    Procs for authority management.

    @author Lars Pind (lars@collaobraid.biz)
    @creation-date 2003-05-14
    @cvs-id $Id$
}

namespace eval auth {}
namespace eval auth::authority {}



#####
#
# auth::authority
#
#####


ad_proc -public auth::authority::create {
    {-authority_id ""}
    {-array:required}
} {
    Create a new authentication authority. 
    
    @option authority_id      Authority_id, or blank if you want one generated for you.

    @param array              Name of an array containing the column values. The entries are:

    <ul>

      <li> short_name          Short name for authority. Used as a key by applications to identify this authority.

      <li> pretty_name         Label for the authority to be shown in a list to users picking a authority.

      <li> enabled_p            't' if this authority available, 'f' if it's disabled. Defaults to 't'.

      <li> sort_order          Sort ordering determines the order in which authorities are listed in the user interface.
                               Defaults to the currently highest sort order plus one.

      <li> auth_impl_id        The ID of the implementation of the 'auth_authentication' service contract.
                               Defaults to none.

      <li> pwd_impl_id         The ID of the implementation of the 'auth_password' service contract. Defaults to none.

      <li> forgotten_pwd_url   An alternative URL to redirect to when the user has forgotten his/her password.
                               Defaults to none.
                           
      <li> change_pwd_url      An alternative URL to redirect to when the user wants to change his/her password.
                               Defaults to none.

      <li> register_impl_id    The ID of the implementation of the 'auth_registration' service contract.
                               Defaults to none.

      <li> register_url        An alternative URL to redirect to when the user wants to register for an account.
                               Defaults to none.

      <li> user_info_impl_id   The ID of the implementation of the 'auth_user_info' service contract.
                               Defaults to none.

      <li> get_doc_impl_id     Id of the 'auth_sync_retrieve' service contract implementation

      <li> process_doc_impl_id Id of the 'auth_sync_process' service contract implementation

      <li> batch_sync_enabled_p Is batch sync enabled for the authority?
    </ul>

    @author Lars Pind (lars@collaboraid.biz)
} {
    upvar $array row

    db_transaction {

        if { $authority_id eq "" } {
            set authority_id [db_nextval "acs_object_id_seq"]
        }

        set names [array names row]

        array set column_defaults [get_column_defaults]        
        set all_columns [array names column_defaults]

        # Check that the columns provided in the array are all valid 
        # Set array entries as local variables
        foreach name $names {
            if { [lsearch -exact $all_columns $name] == -1 } {
                error "Attribute '$name' isn't valid for auth_authorities."
            }
            set $name $row($name)
        }

        # Check that the required columns are there
        foreach name [get_required_columns] {
            if { ![info exists $name] } {
                error "Required column '$name' missing for auth_authorities."
            }
        }

        # Set default values for columns not provided
        foreach column $all_columns {
            if { [lsearch $names $column] == -1 } {
                set $column $column_defaults($column)
            }
        }

        if { ![exists_and_not_null context_id] } {
            set context_id [ad_conn package_id]
        }

        if { ![exists_and_not_null creation_user] } {
            set creation_user [ad_conn user_id]
        }

        if { ![exists_and_not_null creation_ip] } {
            set creation_ip [ad_conn peeraddr]
        }

        # Auto generate short name if not provided and make
        # sure it's unique
        # TODO: check for max length 255?
        if { $short_name eq "" } {
            set existing_short_names [db_list select_short_names {
                select short_name
                from auth_authorities
            }]
            set short_name [util_text_to_url \
                                -replacement "_" \
                                -existing_urls $existing_short_names \
                                -text $pretty_name]
        }

        db_transaction {
            set authority_id [db_exec_plsql create_authority {}]

            # Set the arguments not taken by the new function with an update statement
            # LARS: Great, we had a nice abstraction going, so you only had to add a new column in 
            # one place, now that abstraction is broken, because you have to add it here as well
            foreach column { 
                user_info_impl_id
                get_doc_impl_id
                process_doc_impl_id
                batch_sync_enabled_p
                help_contact_text_format 
            } {
                set edit_columns($column) [set $column]
            }        
            
            edit -authority_id $authority_id -array edit_columns
        }
    }

    # Flush the cache, so that if we've tried to request this short_name while it didn't exist, we will now find it
    if { [exists_and_not_null row(short_name)] } {
        get_id_flush -short_name $row(short_name)
    }

    return $authority_id
}


ad_proc -public auth::authority::get {
    {-authority_id:required}
    {-array:required}
} {
    Get info about an authority, either by authority_id, user_id, or authority short_name.
    
    @param authority_id The authority you want to get.

    @param array Name of an array into which you want the attributes delivered.

    @return authority_id

    @author Lars Pind (lars@collaboraid.biz)
} {
    upvar $array row

    array set row [util_memoize [list auth::authority::get_not_cached $authority_id]]

    return $authority_id
}

ad_proc -public auth::authority::get_element {
    {-authority_id:required}
    {-element:required}
} {
    Return a specific element of the auth_authority data table.
    Does a complete database query each time. Should not be used multiple times in a row. 
    Use auth::authority::get instead.

    @see auth::authority::get
} {
    if { [lsearch [get_select_columns] $element] == -1 } {
        error "Column '$element' not found in the auth_authority data source."
    }
    
    get -authority_id $authority_id -array row
    return $row($element)
}


ad_proc -public auth::authority::get_id {
    {-short_name:required}
} {
    Get authority_id by short_name.

    @param short_name The short_name of the authority you wish to get information for.
    
    @return authority_id or the empty string if short_name doesn't exist.

    @author Lars Pind (lars@collaboraid.biz)
} {
    return [util_memoize [list auth::authority::get_id_not_cached -short_name $short_name]]
}

ad_proc -public auth::authority::edit {
    {-authority_id:required}
    {-array:required}
} {
    Edit info about a authority. Note, that there's no checking that the columns you name exist.
    
    @param authority_id The authority you want to get.

    @param array Name of an array with column values to update.

    @author Lars Pind (lars@collaboraid.biz)
} {
    # We need this to flush the cache later
    set old_short_name [get_element -authority_id $authority_id -element short_name]

    upvar $array row
    
    set names [array names row]
    
    # Construct clauses for the update statement
    set set_clauses [list]
    foreach name $names {
        lappend set_clauses "$name = :$name"
    }

    if { [llength $set_clauses] == 0 } {
        # No rows to update
        return
    }

    set columns [get_columns]

    # Check that the columns provided in the array are all valid 
    # Set array entries as local variables
    foreach name $names {
        if { [lsearch -exact $columns $name] == -1 } {
            error "Attribute '$name' isn't valid for auth_authorities."
        }
        if {$name eq "authority_id"} {
            error "Attribute '$name' is the primary key for auth_authorities, and thus cannot be edited."
        }
        set $name $row($name)
    }
    
    db_dml update_authority "
        update auth_authorities
        set    [join $set_clauses ", "]
        where  authority_id = :authority_id
    "

    get_flush -authority_id $authority_id
    get_id_flush -short_name $old_short_name

    # check if we need to update the object title
    set new_short_name [get_element -authority_id $authority_id -element short_name]
    if {$old_short_name ne $new_short_name } {
	db_dml update_object_title {}
    }
}

ad_proc -public auth::authority::delete {
    {-authority_id:required}
} {
    Delete an authority.
} {
    db_exec_plsql delete_authority {}
}

ad_proc -public auth::authority::get_authority_options {} {
    Returns options (value label pairs) for building the authority HTML select box.

    @author Simon Carstensen
} {
    return [db_list_of_lists select_authorities {}]
}



ad_proc -public auth::authority::batch_sync {
    -authority_id:required
} {
    Execute batch synchronization for this authority now.

    @param authority_id
    @param snapshot     If set, we will delete all authority's users 
                        not touched by the process document proc.

    @return job_id
} {
    set job_id [auth::sync::job::start \
                   -authority_id $authority_id]

    get -authority_id $authority_id -array authority
    
    set message {}

    # Verify that we have implementations
    if { $authority(get_doc_impl_id) eq "" } {
        set message "No Get Document implementation"
    } elseif { $authority(process_doc_impl_id) eq "" } { 
        set message "No Process Document implementation"
    } else {
        auth::sync::job::start_get_document -job_id $job_id

        array set doc_result {
            doc_status failed_to_connect
            doc_message {}
            document {}
            snapshot_p f
        }
        with_catch errmsg {
            array set doc_result [auth::sync::GetDocument -authority_id $authority_id]
        } {
            global errorInfo
            ns_log Error "Error getting sync document:\n$errorInfo"
            set doc_result(doc_status) failed_to_connect
            set doc_result(doc_message) $errmsg
        }
        
        set snapshot_p [template::util::is_true $doc_result(snapshot_p)]

        auth::sync::job::end_get_document \
            -job_id $job_id \
            -doc_status $doc_result(doc_status) \
            -doc_message $doc_result(doc_message) \
            -document $doc_result(document) \
            -snapshot=$snapshot_p

        if { $doc_result(doc_status) eq "ok" && $doc_result(document) ne "" } {
            with_catch errmsg {
                auth::sync::ProcessDocument \
                    -authority_id $authority_id \
                    -job_id $job_id \
                    -document $doc_result(document)
            
                set ack_doc [auth::sync::GetAcknowledgementDocument \
                                 -authority_id $authority_id \
                                 -job_id $job_id \
                                 -document $doc_result(document)]
                
                set ack_file_name [parameter::get_from_package_key \
                                       -parameter AcknowledgementFileName \
                                       -package_key acs-authentication \
                                       -default {}]
                                       
                if { $ack_file_name ne "" } {
                    # Interpolate
                    set pairs [list \
                                   acs_root_dir [acs_root_dir] \
                                   ansi_date [clock format [clock seconds] -format %Y-%m-%d] \
                                   authority $authority(short_name)]
                    foreach { var value } $pairs {
                        regsub -all "{$var}" $ack_file_name $value ack_file_name
                    }

                    template::util::write_file \
                        $ack_file_name \
                        $ack_doc
                }
            } {
                global errorInfo
                ns_log Error "Error processing sync document:\n$errorInfo"
                set message "Error processing sync document: $errmsg"
            }
        } else {
            if { $message eq "" } {
                set message $doc_result(doc_message)
            }
        }
        
        if { $snapshot_p } {
            # If this is a snapshot, we need to delete all the users belonging to this authority
            # that weren't included in the snapshot.
            auth::sync::job::snapshot_delete_remaining \
                -job_id $job_id
        }
    }

    auth::sync::job::end \
        -job_id $job_id \
        -message $message

    return $job_id
}

ad_proc -public auth::authority::get_short_names {} {
    Return a list of authority short names.

    @author Peter Marklund
} {
    return [db_list select_authority_short_names {
        select short_name
        from auth_authorities
    }]
}





#####
#
# Private
#
#####

ad_proc -private auth::authority::get_columns {} {
    Get a list of the columns in the auth_authorities table.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    array set column_defaults [get_column_defaults]
    return [array names column_defaults]
}

ad_proc -private auth::authority::get_column_defaults {} {
    Get an array list with column names as keys and their default
    value as values. Note however that required columns are not defaulted.

    @author Peter Marklund
} {
    set columns { 
        authority_id ""
        short_name ""
        pretty_name ""
        help_contact_text ""
        help_contact_text_format "text/enhanced"
        enabled_p "f"
        sort_order ""
        auth_impl_id ""
        pwd_impl_id ""
        forgotten_pwd_url ""
        change_pwd_url ""
        register_impl_id ""
        register_url ""
        user_info_impl_id ""
        get_doc_impl_id ""
        process_doc_impl_id ""
        batch_sync_enabled_p "f"
    }
    if {[apm_version_names_compare [ad_acs_version] 5.5.0] > -1} {
        lappend columns allow_user_entered_info_p "f" search_impl_id ""
    }
    return $columns
}

ad_proc -private auth::authority::get_required_columns {} {
    Get a list of the required columns in the auth_authorities table.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    return { 
        authority_id
        short_name
        pretty_name
    }
}

ad_proc -private auth::authority::get_sc_impl_columns {} {
    Get a list of column names for storing service contract implementation ids
    of the authority.

    @author Peter Marklund 
} {
    # DAVEB
    set columns {auth_impl_id pwd_impl_id register_impl_id user_info_impl_id get_doc_impl_id process_doc_impl_id}
    if {[apm_version_names_compare [ad_acs_version] 5.5.0] > -1} {
        lappend columns search_impl_id
    }
    return $columns
}

ad_proc -private auth::authority::get_select_columns {} {
    Get a list of the columns which can be selected from auth_authorities table.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    set columns [concat [get_columns] auth_impl_name pwd_impl_name register_impl_name user_info_impl_name get_doc_impl_name process_doc_impl_name]
    if {[apm_version_names_compare [ad_acs_version] 5.5.0] > -1} {
        lappend columns get_search_impl_name
    }
    return $columns
}


ad_proc -private auth::authority::get_flush {
    {-authority_id ""}
} {
    Flush the cache for auth::authority::get.
    
    @see auth::authority::get
} {
    if { $authority_id ne "" } {
        util_memoize_flush [list auth::authority::get_not_cached $authority_id]
    } else {
        util_memoize_flush_regexp [list auth::authority::get_not_cached .*]
    }
}

ad_proc -private auth::authority::get_not_cached {
    authority_id
} {
    Get info about an authority, either by authority_id, user_id, or authority short_name. Not cached

    @see auth::authority::get
} {
    set columns [get_columns]

    lappend columns "(select impl_pretty_name from acs_sc_impls where impl_id = auth_impl_id) as auth_impl_name"
    lappend columns "(select impl_pretty_name from acs_sc_impls where impl_id = pwd_impl_id) as pwd_impl_name"
    lappend columns "(select impl_pretty_name from acs_sc_impls where impl_id = register_impl_id) as register_impl_name"
    lappend columns "(select impl_pretty_name from acs_sc_impls where impl_id = user_info_impl_id) as user_info_impl_name"
    if {[apm_version_names_compare [ad_acs_version] 5.5.0] > -1} {
        lappend columns "(select impl_pretty_name from acs_sc_impls where impl_id = search_impl_id) as search_impl_name"
    }
    lappend columns "(select impl_pretty_name from acs_sc_impls where impl_id = get_doc_impl_id) as get_doc_impl_name"
    lappend columns "(select impl_pretty_name from acs_sc_impls where impl_id = process_doc_impl_id) as process_doc_impl_name"

    db_1row select_authority "
        select     [join $columns ",\n                   "]
        from       auth_authorities
        where      authority_id = :authority_id
    " -column_array row

    return [array get row]
}

ad_proc -private auth::authority::get_id_flush {
    {-short_name ""}
} {
    Flush the cache for gett authority_id by short_name.
} {
    if { $short_name eq "" } {
        util_memoize_flush_regexp [list auth::authority::get_id_not_cached .*]
    } else {
        util_memoize_flush [list auth::authority::get_id_not_cached -short_name $short_name]
    }
}

ad_proc -private auth::authority::get_id_not_cached {
    {-short_name:required}
} {
    Get authority_id by short_name. Not cached.
} {
    return [db_string select_authority_id {} -default {}]
}
ad_proc -public auth::authority::local {} {
    Returns the authority_id of the local authority.
} {
    return [auth::authority::get_id -short_name "local"]
}
