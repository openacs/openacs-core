ad_library {
  Tcl procs for the acs permissioning system.

  @author rhs@mit.edu
  @creation-date 2000-08-17
  @cvs-id $Id$
}

ad_proc -public ad_permission_grant {
    user_id
    object_id
    privilege
} {
    Grant a permission

    @author ben@openforce
} {
    db_exec_plsql grant_permission {}
}

ad_proc -public ad_permission_revoke {
    user_id
    object_id
    privilege
} {
    Revoke a permission

    @author ben@openforce
} {
    db_exec_plsql revoke_permission {}
}

ad_proc -public ad_permission_p {
  {-user_id ""}
  object_id
  privilege
} {
  if {[empty_string_p $user_id]} {
    set user_id [ad_verify_and_get_user_id]
  }

  if { [db_string result {
    select count(*) 
      from dual
     where acs_permission.permission_p(:object_id, :user_id, :privilege) = 't'
  }] } {
      return 1
  }

  # This user doesn't have permission. If we're not in performance mode, 
  # Let's check the name of the privilege and throw an error if no
  # such privilege exists.
  if { ![rp_performance_mode] && ![db_string n_privs {
      select count(*)
        from acs_privileges
       where privilege = :privilege
  }] } {
    error "$privilege isn't a valid privilege"
  }

  return 0
}

ad_proc -public ad_require_permission {
  object_id
  privilege
} {
  set user_id [ad_verify_and_get_user_id]
  if {![ad_permission_p $object_id $privilege]} {
    if {$user_id == 0} {
      ad_maybe_redirect_for_registration
    } else {
      ns_log Notice "$user_id doesn't have $privilege on object $object_id"
      ad_return_forbidden "Security Violation" "<blockquote>
      You don't have permission to $privilege [db_string name {select acs_object.name(:object_id) from dual}].
      <p>
      This incident has been logged.
      </blockquote>"
    }
    ad_script_abort
  }
}

ad_proc -private ad_admin_filter {} {
  ad_require_permission [ad_conn object_id] admin
  return filter_ok
}

ad_proc -private ad_user_filter {} {
  ad_require_permission [ad_conn object_id] read
  return filter_ok
}
