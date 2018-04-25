ad_library {
    Manage Membership Relations

    @author yon (yon@openforce.net)
    @creation-date 2002-03-15
    @cvs-id $Id$
}

namespace eval membership_rel {

    ad_proc -public change_state {
        {-rel_id:required}
        {-state:required}
    } {
        Change the state of a membership relation
    } {
        db_transaction {
            
            # We need the id of the user that we are changing state for
            set rel_user_id [get_user_id -rel_id $rel_id]

            # If user is being undeleted - remove him from the public group
            acs_user::get -user_id $rel_user_id -array user
            if { $user(member_state) eq "deleted" && $state eq "approved" } {
                group::remove_member \
                    -group_id [acs_magic_object the_public] \
                    -user_id $rel_user_id
            }

            switch -exact $state {
                "approved" { db_exec_plsql approve {} }
                "banned" { db_exec_plsql ban {} }
                "rejected" { db_exec_plsql reject {} }
                "deleted" { 
                    db_exec_plsql delete {} 
                    
                    # Add user to public group - see bug 1468
                    group::add_member \
                        -no_perm_check \
                        -group_id [acs_magic_object the_public] \
                        -user_id $rel_user_id                    
                }
                "needs approval" { db_exec_plsql unapprove {} }
                "merged" { db_exec_plsql merge {} }
            }

            # Record who changed the state
            # This will trigger an update of the acs_objects.modified_date column.
            # We use this in the ApprovalExpiration feature to make sure that a user isn't 
            # bumped back to needs_approval right after an administrator has approved them,
            # even if the user doesn't log in the meantime.

            if { [ad_conn isconnected] } {
                set user_id [ad_conn user_id]
            } else {
                set user_id [db_null]
            }
            db_dml update_modifying_user {}
        }

        if { $rel_user_id ne "" } {
            acs_user::flush_cache -user_id $rel_user_id
        }
    }

    ad_proc -public approve {
        {-rel_id:required}
    } {
        Approve a membership relation
    } {
        change_state -rel_id $rel_id -state "approved"
    }

    ad_proc -public ban {
        {-rel_id:required}
    } {
        Ban a membership relation
    } {
        change_state -rel_id $rel_id -state "banned"
    }

    ad_proc -public reject {
        {-rel_id:required}
    } {
        Reject a membership relation
    } {
        change_state -rel_id $rel_id -state "rejected"
    }

    ad_proc -public delete {
        {-rel_id:required}
    } {
        Delete a membership relation
    } {
        change_state -rel_id $rel_id -state "deleted"
    }

    ad_proc -public unapprove {
        {-rel_id:required}
    } {
        Unapprove a membership relation
    } {
        change_state -rel_id $rel_id -state "needs approval"
    }

    ad_proc -public get {
        {-rel_id:required}
    } {
        Return the user_id of a rel_id
    } {
        db_1row select_rel_id { 
            select u.user_id, r.object_id_one as group_id
            from   acs_rels r,
            users u
            where  r.rel_id = :rel_id 
            and    u.user_id = r.object_id_two
        }
        return [list user_id $user_id group_id $group_id]
    }

    ad_proc -public get_user_id {
        {-rel_id:required}
    } {
        Return the user_id of a rel_id
    } {
        return [dict get [get -rel_id $rel_id] user_id]
    }
    
    ad_proc -public get_group_id {
        {-rel_id:required}
    } {
        Return the group_id of a rel_id
    } {
        return [dict get [get -rel_id $rel_id] group_id]
    }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
