ad_library {

    Tcl procs for the acs permissioning system.

    @author rhs@mit.edu
    @creation-date 2000-08-17
    @cvs-id $Id$

}

namespace eval permission {}
#
# Define cache_p to return 0 or 1 depending on the PermissionCacheP
# kernel parameter on the first call.  The namespace eval is needed to
# make the redefinition work for ttrace.
#
ad_proc -private permission::cache_p {} {
    returns 0 or 1 depending if permission_p caching is enabled or disabled.
    by default caching is disabled.
} {
    set cache_p [parameter::get -package_id [ad_acs_kernel_id] -parameter PermissionCacheP -default 0]
    namespace eval ::permission [list proc cache_p {} "return $cache_p"]
    return $cache_p
}

ad_proc -public permission::grant {
    {-party_id:required}
    {-object_id:required}
    {-privilege:required}
} {
    grant privilege Y to party X on object Z
} {
    db_exec_plsql grant_permission {}
    permission::cache_flush -party_id $party_id -object_id $object_id -privilege $privilege
    permission::permission_thread_cache_flush
}

ad_proc -public permission::revoke {
    {-party_id:required}
    {-object_id:required}
    {-privilege:required}
} {
    revoke privilege Y from party X on object Z
} {
    db_exec_plsql revoke_permission {}
    permission::cache_flush -party_id $party_id -object_id $object_id -privilege $privilege
    permission::permission_thread_cache_flush
}

# args to permission_p and permission_p_no_cache must match
ad_proc -public permission::permission_p {
    {-no_login:boolean}
    {-no_cache:boolean}
    {-party_id ""}
    {-object_id:required}
    {-privilege:required}
} {
    Does the provided party have the reequested privilege on the given object?

    @param no_cache force loading from db even if cached (flushes cache as well)

    @param no_login Don't bump to registration to refresh authentication, if the user's authentication is expired.
                    This is specifically required in the case where you're calling this from the proc that gets
                    the login page.

    @param party_id if null then it is the current user_id

    @param object_id The object you want to check permissions on.

    @param privilege The privilege you want to check for.
} {
    if { $party_id eq "" } {
        set party_id [ad_conn user_id]
    }

    set caching_activated [permission::cache_p]

    if { $no_cache_p || !$caching_activated } {
        #
        # No caching wanted (either per-call or configured)
        #
        if { $no_cache_p } {
            #
            # Avoid all caches.
            #
            permission::permission_thread_cache_flush
        }

        if {$caching_activated} {
            #
            # Only flush the cache, when caching is activated.
            # Frequent cache flushing can cause a flood of
            # intra-server talk in a cluster configuration (see bug
            # #2398);
            #
            permission::cache_flush \
                -party_id $party_id \
                -object_id $object_id \
                -privilege $privilege
        }

        set permission_p [permission::permission_p_not_cached \
                              -party_id $party_id \
                              -object_id $object_id \
                              -privilege $privilege]
    } else {
        #
        # Permission caching is activated
        #
        set permission_p [permission::cache_eval \
                              -party_id $party_id \
                              -object_id $object_id \
                              -privilege $privilege]
    }

    if {
        !$no_login_p
        && $party_id == 0
        && [ad_conn user_id] == 0
        && [ad_conn untrusted_user_id] != 0
        && ![template::util::is_true $permission_p]
    } {
        #
        # In case, permission was granted above, the party and ad_conn
        # user_id are 0, and the permission is NOT granted based on
        # the untrusted_user_id, require login unless this is
        # deactivated for this call.
        #
        set untrusted_permission_p [permission_p_not_cached \
                                        -party_id [ad_conn untrusted_user_id] \
                                        -object_id $object_id \
                                        -privilege $privilege]
        if { $permission_p != $untrusted_permission_p } {
            # Bump to registration page
            ns_log Debug "permission_p: party_id=$party_id ([acs_object_name $party_id]), object_id=$object_id ([acs_object_name $object_id]), privilege=$privilege. Result=>$permission_p. Untrusted-Result=>$untrusted_permission_p\n[ad_get_tcl_call_stack]"
            if { ![ad_login_page] } {
                auth::require_login
            }
        }
    }

    return $permission_p
}


ad_proc -private permission::permission_p_not_cached {
    {-no_cache:boolean}
    {-party_id ""}
    {-object_id:required}
    {-privilege:required}
} {
    does party X have privilege Y on object Z

    This function accepts "-no_cache" just to match the permission_p
    signature since we alias it to permission::permission_p when
    caching is disabled.

    @see permission::permission_p
} {
    if { $party_id eq "" } {
        set party_id [ad_conn user_id]
    }

    # We have a per-request cache here
    set key ::permission__permission_p__cache($party_id,$object_id,$privilege)
    if { ![info exists $key] } {
        set $key [db_string select_permission_p {
            select acs_permission.permission_p(:object_id, :party_id, :privilege)::integer from dual
        }]
    }
    return [set $key]
}


ad_proc -private permission::permission_thread_cache_flush {} {
    Flush thread cache
} {
    array unset ::permission__permission_p__cache
}

ad_proc -public permission::require_permission {
    {-party_id ""}
    {-object_id:required}
    {-privilege:required}
} {
    require that party X have privilege Y on object Z
} {
    if {$party_id eq ""} {
        set party_id [ad_conn user_id]
    }

    if {![permission_p -party_id $party_id -object_id $object_id -privilege $privilege]} {

        if {!$party_id && ![ad_conn ajax_p]} {
            auth::require_login
        } else {
            ns_log notice "permission::require_permission: $party_id doesn't have privilege $privilege on object $object_id"
            ad_return_forbidden \
                "Permission Denied" \
                "You don't have permission to $privilege on object $object_id."
        }

        ad_script_abort
    }
}

ad_proc -public permission::inherit_p {
    {-object_id:required}
} {
    does this object inherit permissions
} {
    return [db_string select_inherit_p {} -default 0]
}

ad_proc -public permission::toggle_inherit {
    {-object_id:required}
} {
    toggle whether or not this object inherits permissions from its parent
} {
    db_dml toggle_inherit {}
    permission::permission_thread_cache_flush
}

ad_proc -public permission::set_inherit {
    {-object_id:required}
} {
    set inherit to true
} {
    db_dml set_inherit {}
    permission::permission_thread_cache_flush
}

ad_proc -public permission::set_not_inherit {
    {-object_id:required}
} {
    set inherit to false
} {
    db_dml set_not_inherit {}
    permission::permission_thread_cache_flush
}

ad_proc -public permission::write_permission_p {
    {-object_id:required}
    {-party_id ""}
    {-creation_user ""}
} {
    Returns whether a user is allowed to edit an object.
    The logic is that you must have either write permission,
    or you must be the one who created the object.

    @param object_id     The object you want to check write permissions for

    @param party_id      The party to have or not have write permission.

    @param creation_user Optionally specify creation_user directly as an optimization.
                         Otherwise a query will be executed.

    @return True (1) if user has permission to edit the object, 0 otherwise.

    @see permission::require_write_permission
} {
    if { $creation_user eq "" } {
        set creation_user [acs_object::get_element -object_id $object_id -element creation_user]
    }
    if { [ad_conn user_id] == $creation_user } {
        return 1
    }
    if { [permission::permission_p -privilege write -object_id $object_id -party_id $party_id] } {
        return 1
    }
    return 0
}

ad_proc -public permission::require_write_permission {
    {-object_id:required}
    {-creation_user ""}
    {-party_id ""}
    {-action "edit"}
} {
    If the user is not allowed to edit this object, returns a permission denied page.

    @param creation_user Optionally specify creation_user directly as an optimization.
                         Otherwise a query will be executed.
    @param party_id      The party to have or not have write permission.

    @see permission::write_permission_p
} {
    if { ![permission::write_permission_p -object_id $object_id -party_id $party_id] } {
        ad_return_forbidden  "Permission Denied"  "You don't have permission to $action this object."
        ad_script_abort
    }
}

ad_proc -public permission::get_parties_with_permission {
    {-object_id:required}
    {-privilege "admin"}
} {
    Return a list of lists of party_id and acs_object.title,
    having a given privilege on the given object

    @param object_id
    @param privilege

    @see permission::permission_p
} {
    return [db_list_of_lists get_parties {}]
}

if {[info commands ns_cache_eval] ne ""} {
    #
    # Permission cache management for NaviServer.
    #
    # Some of this code will go away, when abstract cache management
    # will be introduced.
    #
    #
    # run permission call or get permission from cache
    #
    ad_proc -private permission::cache_eval {
        {-party_id}
        {-object_id}
        {-privilege}
    } {
        Run permission call and cache the result.

        @param party_id
        @param object_id
        @param privilege

        @see permission::permission_p
    } {
        return [ns_cache eval permission_cache $party_id/$object_id/$privilege {
            permission::permission_p_not_cached \
                -party_id $party_id \
                -object_id $object_id \
                -privilege $privilege
        }]
    }

    #
    # flush permission cache
    #

    ad_proc -public permission::cache_flush {
        {-party_id}
        {-object_id}
        {-privilege}
    } {

        Flush permissions from the cache. Either specify all three
        parameters or only party_id

        @param party_id
        @param object_id
        @param privilege

        @see permission::permission_p
    } {
        if {![info exists ::permission::cache_created]} {
            return

        } elseif {[info exists party_id] && [info exists object_id] && [info exists privilege]} {
            #
            # All three attributes are provided
            #
            ns_cache_flush permission_cache $party_id/$object_id/$privilege

        } elseif {[info exists party_id] } {
            #
            # At least the party_id is provided
            #
            ns_cache_flush -glob permission_cache $party_id/*
        } else {
            #
            # tell user, what's implemented
            #
            error "either specify party_id, object_id and privilege, or only party_id"
        }
    }


} else {

    #
    # Permission cache management for AOLserver.
    # Use classical util_memoize cache for maximum
    # backwards compatibility.
    #

    ad_proc -private permission::cache_eval {
        {-party_id}
        {-object_id}
        {-privilege}
    } {
        Run permission call and cache the result.

        @param party_id
        @param object_id
        @param privilege

        @see permission::permission_p
    } {
        return [util_memoize \
                    [list permission::permission_p_not_cached \
                         -party_id $party_id \
                         -object_id $object_id \
                         -privilege $privilege] \
                    [parameter::get -package_id [ad_acs_kernel_id] \
                         -parameter PermissionCacheTimeout \
                         -default 300]]
    }


    ad_proc -public permission::cache_flush {
        {-party_id}
        {-object_id}
        {-privilege}
    } {

        Flush permissions from the cache. Either specify all three
        parameters or only party_id

        @param party_id
        @param object_id
        @param privilege

        @see permission::permission_p
    } {
        if {![info exists ::permission::cache_created]} {
            return

        } elseif {[info exists party_id] && [info exists object_id] && [info exists privilege]} {
            #
            # All three attributes are provided
            #
            util_memoize_flush [list permission::permission_p_not_cached -party_id $party_id -object_id $object_id -privilege $privilege]

        } elseif {[info exists party_id] } {
            #
            # At least the party_id is provided
            #
            util_memoize_flush_pattern "permission::*-party_id $party_id"
        } else {
            #
            # tell user, what's implemented
            #
            error "either specify party_id, object_id and privilege, or only party_id"
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
