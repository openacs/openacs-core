ad_library {

    Community routines (dealing with users, parties, etc.).

    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 11 Aug 2000
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
    } -default ""]
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

    if { [empty_string_p $url] } {
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

namespace eval person {
    
    ad_proc -public new {
        {-first_names:required}
        {-last_name:required}
    } {
        create a new person
    } {
       
        set extra_vars [ns_set create]
        ns_set put $extra_vars first_names $first_names
        ns_set put $extra_vars last_name $last_name

        set object_type "person"
        return [package_instantiate_object -extra_vars $extra_vars $object_type]
    }

    ad_proc -public delete {
        {-person_id:required}
    } {
        delete a person
    } {
        db_exec_plsql delete_person {}
    }

    ad_proc -public get {
        {-person_id:required} 
    } {
        get info for a person as a tcl array in list form
    } {
        db_1row get_person {}
        
        set person(person_id) $person_id
        set person(first_names) $first_names
        set person(last_name) $last_name

        return [array get person]
    }

    ad_proc -public name {
        {-person_id:required}
    } {
        get the name of a person. Cached.
    } {
        return [util_memoize [list person::name_not_cached -person_id $person_id]]
    }

    ad_proc -public name_not_cached {
        {-person_id:required}
    } {
        get the name of a person
    } {
        db_1row get_person_name {}
        return $person_name
    }

    ad_proc -public update {
        {-person_id:required}
        {-first_names:required}
        {-last_name:required}
    } {
        update the name of a person
    } {
        db_dml update_person {}
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

        membership_rel::change_state -rel_id $rel_id -state $state
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
