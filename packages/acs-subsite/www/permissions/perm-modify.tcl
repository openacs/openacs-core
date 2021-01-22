ad_page_contract {} {
    object_id:naturalnum,notnull
    {perm:multiple {[list]}}
    {privs:optional}
    return_url:localurl
}


permission::require_permission -object_id $object_id -privilege admin

# entried in 'perm' have the form "${party_id}_${privilege}"

foreach elm $perm {
    set elmv [split $elm ","]
    set party_id [lindex $elmv 0]
    set priv [lindex $elmv 1]
    if { $priv ne "remove" } {
        set perm_array($elm) add
    }
}

foreach elm $perm {
    set elmv [split $elm ","]
    set party_id [lindex $elmv 0]
    set priv [lindex $elmv 1]
    if {$priv eq "remove"} {
        foreach priv $privs {
            if { [info exists perm_array(${party_id},${priv})] } {
                unset perm_array(${party_id},${priv})
            }
        }
    }
}

# Don't want them to remove themselves as admins
if { ![info exists perm_array([ad_conn user_id],admin)] && ![acs_user::site_wide_admin_p] } {
    set perm_array([ad_conn user_id],admin) add
}

set changes_p false
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
                permission::revoke -party_id $party_id -object_id $object_id -privilege $privilege
                set changes_p true
            }
            add {
                permission::grant -party_id $party_id -object_id $object_id -privilege $privilege
                set changes_p true
            }
        }
    }
} on_error {
    ad_return_complaint 1 "[_ acs-tcl.The] $errmsg<p> $::errorInfo"
    ad_script_abort
}

set message [expr {$changes_p ? [_ acs-subsite.Information_Updated] : ""}]

ad_returnredirect -message $message $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
