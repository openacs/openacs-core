ad_library {
    Manage Membership Relations

    @author yon (yon@openforce.net)
    @creation-date 2002-03-15
    @version $Id$
}

namespace eval membership_rel {

    ad_proc -public change_state {
        {-rel_id:required}
        {-state:required}
    } {
        Change the state of a membership relation
    } {
        switch -exact $state {
            "approved" { db_exec_plsql approve {} }
            "banned" { db_exec_plsql ban {} }
            "rejected" { db_exec_plsql reject {} }
            "deleted" { db_exec_plsql delete {} }
            "needs approval" { db_exec_plsql unapprove {} }
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

}
