ad_library {

    Community routines (dealing with users, parties, etc.).

    @author Jon Salz (jsalz@arsdigita.com)
    @date 11 Aug 2000
    @cvs-id $Id$

}

ad_proc -private cc_lookup_screen_name_user { screen_name } {
    return [db_string user_select {
        select user_id from cc_users where upper(screen_name) = upper(:screen_name)
    } -default ""]
}

ad_proc cc_screen_name_user { screen_name } {

    Returns the user ID for a particular screen name, or an empty string
    if none exists.

} {
    return [util_memoize [list cc_lookup_screen_name_user $screen_name]]
}

ad_proc -private cc_lookup_email_user { email } {
    return [db_string user_select {
        select user_id from cc_users where email = lower(:email)
    } -default ""]
}

ad_proc -public cc_email_from_party { party_id } {
    @return The email address of the indicated party.
} {
    return [db_string email_from_party {
        select email from parties where party_id = :party_id
    } -default 0]
}

ad_proc cc_email_user { email } {

    Returns the user ID for a particular email address, or an empty string
    if none exists.

} {
    return [util_memoize [list cc_lookup_email_user $email]]
}

ad_proc -private cc_lookup_name_group { name } {
    return [db_string group_select {
        select group_id from groups where group_name = :name
    } -default ""]
}

ad_proc cc_name_to_group { name } {

    Returns the group ID for a particular name, or an empty string
    if none exists.

} {
    return [util_memoize [list cc_lookup_name_group $name]]
}

ad_proc ad_user_new {email first_names last_name password password_question password_answer  {url ""} {email_verified_p "t"} {member_state "approved"} {user_id ""} } {

    Creates a new user in the system.  The user_id can be specified as an argument to enable double click protection.
    If this procedure succeeds, returns the new user_id.  Otherwise, returns 0.
} {
    if { [empty_string_p $user_id] } {
        set user_id [db_nextval acs_object_id_seq]
    }

    if { [empty_string_p $password_question] } {
        set password_question [db_null]
    }

    if { [empty_string_p $password_answer] } {
        set password_answer [db_null]
    }

    if { [empty_string_p url] } {
        set url [db_null]
    }

    set peeraddr [ad_conn peeraddr]
    set salt [sec_random_token]
    set hashed_password [ns_sha1 "$password$salt"]

    db_transaction {

        set user_id [db_exec_plsql user_insert {
            begin
            :1 := acs.add_user(user_id => :user_id,
            email => :email,
            url => :url,
            first_names => :first_names,
            last_name => :last_name,
            password => :hashed_password,
            salt => :salt,
            password_question => :password_question,
            password_answer => :password_answer,
            creation_ip => :peeraddr,
            email_verified_p => :email_verified_p,
            member_state => :member_state);
            end;
        }
        ]

        if {[catch {
            # Call the extension
            acs_user_extension::user_new -user_id $user_id
        } errmsg]} {
            # At this point, we don't want the user addition to fail
            # if some extension is screwing things up
        }

    } on_error {
        # we got an error.  log it and signal failure.
        ns_log Error "Problem creating a new user: $errmsg"
        return 0
    }
    # success.
    return $user_id
}

ad_proc -public ad_user_remove {
    -user_id:required
} {
    remove a user from the ACS
} {
    db_exec_plsql user_remove {
        begin
            acs.remove_user(
                user_id => :user_id
            );
        end;
    }
}

namespace eval acs_user {

    ad_proc -public change_state {
        {-user_id:required}
        {-state:required}
    } {
        Change the membership state of a user.
    } {
        set rel_id [db_string select_rel_id {
            select rel_id
            from cc_users
            where user_id = :user_id
        } -default ""]

        if {[empty_string_p $rel_id]} {
            return
        }

        switch -exact $state {
            "approved" {
                db_exec_plsql member_approve {
                    begin membership_rel.approve(rel_id => :rel_id); end;
                }
            }
            "banned" {
                db_exec_plsql member_ban {
                    begin membership_rel.ban(rel_id => :rel_id); end;
                }
            }
            "rejected" {
                db_exec_plsql member_reject {
                    begin membership_rel.reject(rel_id => :rel_id); end;
                }
            }
            "deleted" {
                db_exec_plsql member_delete {
                    begin membership_rel.delete(rel_id => :rel_id); end;
                }
            }
            "needs approval" {
                db_exec_plsql member_unapprove {
                    begin membership_rel.unapprove(rel_id => :rel_id); end;
                }
            }
        }
    }

    ad_proc -public approve {
        {-user_id:required}
    } {
        Approve a user
    } {
        change_state -user_id $user_id -state "approved"
    }
        
    ad_proc -public ban {
        {-user_id:required}
    } {
        Ban a user
    } {
        change_state -user_id $user_id -state "banned"
    }
        
    ad_proc -public reject {
        {-user_id:required}
    } {
        Reject a user
    } {
        change_state -user_id $user_id -state "rejected"
    }
        
    ad_proc -public delete {
        {-user_id:required}
    } {
        Delete a user
    } {
        change_state -user_id $user_id -state "deleted"
    }
        
    ad_proc -public unapprove {
        {-user_id:required}
    } {
        Unapprove a user
    } {
        change_state -user_id $user_id -state "needs approval"
    }
        
}
