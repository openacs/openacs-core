ad_library {

    Community routines (dealing with users, parties, etc.).

    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 11 Aug 2000
    @cvs-id $Id$

}

namespace eval party {}

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

    ad_proc -public name_flush {
        {-person_id:required}
    } {
        Flush the person::name cache.
    } {
        util_memoize_flush [list person::name_not_cached -person_id $person_id]
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
        name_flush -person_id $person_id
    }
}

ad_proc -public person::get_bio {
    {-person_id {}}
    {-exists_var {}}
} {
    Get the value of the user's bio(graphy) field.

    @option person_id    The person_id of the person to get the bio for. Leave blank for currently logged in user.
    
    @option exists_var The name of a variable in the caller's namespace, which will be set to 1 
                       if a bio was found, or 0 if no bio was found. Leave blank if you're not
                       interested in this information.
    
    @return The bio of the user as a text string.

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [empty_string_p $person_id] } {
        set person_id [ad_conn user_id]
    }

    if { ![empty_string_p $exists_var] } {
        upvar $exists_var exists_p
    }

    set exists_p [db_0or1row select_bio {}]
    
    if { !$exists_p } {
        set bio {}
    }
    
    return $bio
}

ad_proc -public person::update_bio {
    {-person_id:required}
    {-bio:required}
} {
    Update the bio for a person.

    @param person_id The ID of the person to edit bio for
    @param bio       The new bio for the person

    @author Lars Pind (lars@collaboraid.biz)
} {
    # This will set exists_p to whether or not a row for the bio existed
    set bio_old [get_bio -person_id $person_id -exists_var exists_p]

    # bio_change_to = 0 -> insert
    # bio_change_to = 1 -> don't change
    # bio_change_to = 2 -> update

    if { !$exists_p } {
        # There is no bio yet.
        # If new bio is empty, that's a don't change (1)
        # If new bio is non-empty, that's an insert (0)
        set bio_change_to [empty_string_p $bio]
    } else {
        if { [string equal $bio $bio_old] } {
            set bio_change_to 1
        } else {
            set bio_change_to 2
        }
    }
    
    if { $bio_change_to == 0 } {
	# perform the insert
	db_dml insert_bio {}
    } elseif { $bio_change_to == 2 } {
	# perform the update
	db_dml update_bio {}
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


ad_proc -public acs_user::get {
    {-user_id {}}
    {-array:required}
    {-include_bio:boolean}
} {
    Get basic information about a user.

    @option user_id     The user_id of the user to get the bio for. Leave blank for current user.

    @option include_bio Whether to include the bio in the user information

    @param  array       The name of an array into which you want the information put. 
    
    The attributes returned are: 
                 user_id, 
                 first_names, 
                 last_name, 
                 name (first_names last_name),
                 email, 
                 url, 
                 screen_name,
                 priv_name,  
                 priv_email,
                 email_verified_p,
                 email_bouncing_p,
                 no_alerts_until,
                 last_visit,
                 second_to_last_visit,
                 n_sessions,
                 password_question,
                 password_answer,
                 password_changed_date,
                 member_state,
                 rel_id,
                 bio (if -include_bio switch is present)

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [empty_string_p $user_id] } {
        set user_id [ad_conn user_id]
    }

    upvar $array row
    db_1row select_user_info {} -column_array row

    if { $include_bio_p } {
        set row(bio) [person::get_bio -person_id $user_id]
    }
}

ad_proc -public acs_user::update {
    {-user_id:required}
    {-screen_name}
    {-password_question}
    {-password_answer}
} {
    Update information about a user. 
    Feel free to expand this with more switches later as needed, as long as they're optional.

    @param  party_id           The ID of the party to edit
    @option screen_name        The new screen_name for the user
    @option password_question  The new password_question for the user
    @option password_answer    The new password_question for the user

    @author Lars Pind (lars@collaboraid.biz)
} {
    set cols [list]
    foreach var { screen_name password_question password_answer  } {
        if { [info exists $var] } {
            lappend cols "$var = :$var"
        }
    }
    db_dml user_update {}
}

ad_proc -public acs_user::site_wide_admin_p {
    {-user_id ""}
} {
    Return 1 if the specified user (defaults to logged in user)
    is site-wide administrator and 0 otherwise.

    @param user_id The id of the user to check for admin privilege.

    @author Peter Marklund
} {
    if { [empty_string_p $user_id]} {
        set user_id [ad_conn user_id]
    }

    return [permission::permission_p -party_id $user_id \
                                     -object_id [acs_lookup_magic_object security_context_root] \
                                     -privilege "admin"]
}

ad_proc -public party::update {
    {-party_id:required}
    {-email:required}
    {-url:required}
} {
    Update information about a party.

    @param party_id The ID of the party to edit
    @param email    The new email for the party
    @param url      The new URL for the party

    @author Lars Pind (lars@collaboraid.biz)
} {
    db_dml party_update {}
}
