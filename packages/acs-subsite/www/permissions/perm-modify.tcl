ad_page_contract {

    Modify permissions on an object.

} {
    object_id:object_id,notnull
    {perm:token,multiple {[list]}}
    {privs:token,notnull}
    return_url:localurl
} -validate {
    privs_exists_p -requires {privs} {
        foreach priv $privs {
            if {![db_0or1row get_priv {select 1 from acs_privileges where privilege = :priv}]} {
                ad_complain "privilege [ns_quotehtml $priv] doesn't exist"
            }
        }
    }
    perm_is_valid -requires {perm} {
        foreach elm $perm {
            lassign [split $elm ","] party_id priv
            if {![string is integer -strict $party_id] ||
                ![db_0or1row party_exists {select 1 from parties where party_id = :party_id}] ||
                ($priv ne "remove" && ![db_0or1row priv_exists {select 1 from acs_privileges where privilege = :priv}])
            } {
                ad_complain "perm [ns_quotehtml $elm] is not valid"
            }
        }
    }
}


permission::require_permission -object_id $object_id -privilege admin

set mainsite_p [expr {$object_id eq [subsite::main_site_id]}]

#
# Entries in 'perm' have the form "${party_id}_${privilege}"
#
foreach elm $perm {
    lassign [split $elm ","] party_id priv
    if { $priv ne "remove" } {
        set perm_array($elm) add
    }
}

foreach elm $perm {
    lassign [split $elm ","] party_id priv
    if {$priv eq "remove"} {
        foreach priv $privs {
            if { [info exists perm_array(${party_id},${priv})] } {
                if {$mainsite_p && $party_id == "-1"} {
                    util_user_message "#acs-kernel.The_Public# $priv: #acs-subsite.perm_cannot_be_removed#"
                } else {
                    unset perm_array(${party_id},${priv})
                }
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
            # If they are in the modified list, make a note that they're also in the database
            set perm_array(${grantee_id},${privilege}) nothing
        }
    }

    # run through the perm_array, and depending on the value
    #  remove:  Remove the privilege
    #  nothing: Do nothing
    #  add:     Add the privilege
    foreach elm [array names perm_array] {
        lassign [split $elm ","] party_id privilege

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

set message [expr {$changes_p ? [_ acs-subsite.Permissions_Updated] : ""}]

ad_returnredirect -message $message $return_url
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
