ad_page_contract {} {
    object_id:integer
    {perm:multiple {[list]}}
    {privs:optional}
    return_url
}


ad_require_permission $object_id admin

# entried in 'perm' have the form "${party_id}_${privilege}"

foreach elm $perm {
    set elmv [split $elm ","]
    set party_id [lindex $elmv 0]
    set priv [lindex $elmv 1]
    if { ![string equal $priv "remove"] } {
        set perm_array($elm) add
    }
}

foreach elm $perm {
    set elmv [split $elm ","]
    set party_id [lindex $elmv 0]
    set priv [lindex $elmv 1]
    if { [string equal $priv "remove"] } {
        foreach priv $privs {
            if { [info exists perm_array(${party_id},${priv})] } {
                unset perm_array(${party_id},${priv})
            }
        }
    }
}

# Don't want them to remove themselves as admins
if { ![info exists perm_array([ad_conn user_id],admin)] } {
    set perm_array([ad_conn user_id],admin) add
}

set page "<ul>"

db_transaction {
    db_foreach permissions_in_db {} {

        if { ![info exists perm_array(${grantee_id},${privilege})] } {
            # If they're not in the modified list, remove them
            set perm_array(${grantee_id},${privilege}) remove
        } else {
            # If they are in the modified list, make a note that they're also in the databse
            set perm_array(${grantee_id},${privilege}) nothing
        }
    }
    
    # run through the perm_array, and depending on the value
    #  remove:  Remove the privilege
    #  nothing: Do nothing
    #  add:     Add the privilege
    foreach elm [array names perm_array] {
        set elmv [split $elm ","]
        set party_id [lindex $elmv 0]
        set privilege [lindex $elmv 1]
        
        switch -- $perm_array($elm) {
            remove {
                db_exec_plsql remove {}
                append page "<li>select acs_permission__revoke_permission($object_id, $party_id, $privilege)"
            }
            add {
                db_exec_plsql add {}
                append page "<li>select acs_permission__grant_permission($object_id, $party_id, $privilege)"
            }
        }
    }
} on_error {
    global errorInfo
    ad_return_complaint 1 "Ooops, looks like we screwed up. Sorry. $errmsg<p> $errorInfo"
}

append page "</ul>"

ad_returnredirect $return_url
