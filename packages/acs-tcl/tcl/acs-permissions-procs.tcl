ad_library {

    Tcl procs for the acs permissioning system.

    @author rhs@mit.edu
    @creation-date 2000-08-17
    @cvs-id $Id$

}

namespace eval permission {

    ad_proc -public grant {
        {-party_id:required}
        {-object_id:required}
        {-privilege:required}
    } {
        grant privilege Y to party X on object Z
    } {
        db_exec_plsql grant_permission {}
    }

    ad_proc -public revoke {
        {-party_id:required}
        {-object_id:required}
        {-privilege:required}
    } {
        revoke privilege Y from party X on object Z
    } {
        db_exec_plsql revoke_permission {}
    }

    ad_proc -public permission_p {
        {-party_id ""}
        {-object_id:required}
        {-privilege:required}
    } {
        does party X have privilege Y on object Z
    } {
        if {[empty_string_p $party_id]} {
            set party_id [ad_conn user_id]
        }

        return [db_0or1row select_permission_p {}]
    }

    ad_proc -public require_permission {
        {-party_id ""}
        {-object_id:required}
        {-privilege:required}
    } {
        require that party X have privilege Y on object Z
    } {
        if {[empty_string_p $party_id]} {
            set party_id [ad_conn user_id]
        }

        if {![permission_p -party_id $party_id -object_id $object_id -privilege $privilege]} {
            if {!${party_id}} {
                ad_maybe_redirect_for_registration
            } else {
                ns_log notice "$party_id doesn't have $privilege on object $object_id"
                ad_return_forbidden \
                    "Security Violation" \
                    "<blockquote>
  You don't have permission to $privilege [db_string name {}].
  <br>
  This incident has been logged.
</blockquote>"
            }

            ad_script_abort
        }
    }

    ad_proc -public inherit_p {
        {-object_id:required}
    } {
        does this object inherit permissions
    } {
        return [db_string select_inherit_p {} -default 0]
    }

    ad_proc -public toggle_inherit {
        {-object_id:required}
    } {
        toggle whether or not this object inherits permissions from it's parent
    } {
        db_dml toggle_inherit {}
    }

    ad_proc -public set_inherit {
        {-object_id:required}
    } {
        set inherit to true
    } {
        db_dml set_inherit {}
    }

    ad_proc -public set_not_inherit {
        {-object_id:required}
    } {
        set inherit to false
    } {
        db_dml set_not_inherit {}
    }

}

ad_proc -deprecated ad_permission_grant {
    user_id
    object_id
    privilege
} {
    Grant a permission

    @author ben@openforce
} {
    permission::grant -party_id $user_id -object_id $object_id -privilege $privilege
}

ad_proc -deprecated ad_permission_revoke {
    user_id
    object_id
    privilege
} {
    Revoke a permission

    @author ben@openforce
} {
    permission::revoke -party_id $user_id -object_id $object_id -privilege $privilege
}

ad_proc -deprecated ad_permission_p {
    {-user_id ""}
    object_id
    privilege
} {
    return [permission::permission_p -party_id $user_id -object_id $object_id -privilege $privilege]
}

ad_proc -deprecated ad_require_permission {
  object_id
  privilege
} {
    permission::require_permission -object_id $object_id -privilege $privilege
}

ad_proc -private ad_admin_filter {} {
    permission::require_permission -object_id [ad_conn object_id] -privilege "admin"
    return filter_ok
}

ad_proc -private ad_user_filter {} {
    permission::require_permission -object_id [ad_conn object_id] -privilege "read"
    return filter_ok
}
