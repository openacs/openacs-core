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

      <li> short_name         Short name for authority. Used as a key by applications to identify this authority.

      <li> pretty_name        Label for the authority to be shown in a list to users picking a authority.

      <li> enabled_p           't' if this authority available, 'f' if it's disabled. Defaults to 't'.

      <li> sort_order         Sort ordering determines the order in which authoritys are listed in the user interface.
                              Defaults to 1.

      <li> auth_impl_id       The ID of the implementation of the 'auth_authentication' service contract.
                              Defaults to none.

      <li> pwd_impl_id        The ID of the implementation of the 'auth_password' service contract. Defaults to none.

      <li> forgotten_pwd_url  An alternative URL to redirect to when the user has forgotten his/her password.
                              Defaults to none.
                           
      <li> change_pwd_url     An alternative URL to redirect to when the user wants to change his/her password.
                              Defaults to none.

      <li> register_impl_id   The ID of the implementation of the 'auth_register' service contract.
                              Defaults to none.

      <li> register_url       An alternative URL to redirect to when the user wants to register for an account.
                              Defaults to none.

      <li> get_doc_impl_id     Id of the batch sync GetDocument service contract implementation

      <li> process_doc_impl_id Id of the batch sync ProcessDocument service contract implementation

      <li> snapshot_p          Whether batch jobs are snapshots or not

      <li> batch_sync_enabled_p Is batch sync enabled for the authority?
    </ul>

    @author Lars Pind (lars@collaboraid.biz)
} {
    upvar $array row

    db_transaction {

        if { [empty_string_p authority_id] } {
            set authority_id [db_nextval "auth_authority_id_seq"]
        }

        set names [array names row]

        set columns [get_columns]

        # Check that the columns provided in the array are all valid 
        # Set array entries as local variables
        foreach name $names {
            if { [lsearch -exact $columns $name] == -1 } {
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

        if { ![exists_and_not_null context_id] } {
            set context_id [ad_conn package_id]
        }

        if { ![exists_and_not_null creation_user] } {
            set creation_user [ad_conn user_id]
        }

        if { ![exists_and_not_null creation_ip] } {
            set creation_ip [ad_conn peeraddr]
        }

        set authority_id [db_exec_plsql create_authority {}]
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
        if { [string equal $name "authority_id"] } {
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



#####
#
# Private
#
#####

ad_proc -private auth::authority::get_columns {} {
    Get a list of the columns in the auth_authorities table.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    return { 
        authority_id
        short_name
        pretty_name
        help_contact_text
        enabled_p
        sort_order
        auth_impl_id
        pwd_impl_id
        forgotten_pwd_url
        change_pwd_url
        register_impl_id
        register_url
        get_doc_impl_id
        process_doc_impl_id
        snapshot_p
        batch_sync_enabled_p
    }
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

ad_proc -private auth::authority::get_select_columns {} {
    Get a list of the columns which can be selected from auth_authorities table.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    return [concat [get_columns] auth_impl_name pwd_impl_name register_impl_name]
}


ad_proc -private auth::authority::get_flush {
    {-authority_id ""}
} {
    Flush the cache for auth::authority::get.
    
    @see auth::authority::get
} {
    if { ![empty_string_p $authority_id] } {
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

    lappend columns "(select impl_name from acs_sc_impls where impl_id = auth_impl_id) as auth_impl_name"
    lappend columns "(select impl_name from acs_sc_impls where impl_id = pwd_impl_id) as pwd_impl_name"
    lappend columns "(select impl_name from acs_sc_impls where impl_id = register_impl_id) as register_impl_name"

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
    if { [empty_string_p $short_name] } {
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


