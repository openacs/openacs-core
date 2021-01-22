ad_library {

    Community routines (dealing with users, parties, etc.).

    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 11 Aug 2000
    @cvs-id $Id$

}

namespace eval party {}
namespace eval person {}
namespace eval acs_user {}

ad_proc -deprecated -private cc_lookup_screen_name_user { screen_name } {
    @see acs_user::get_user_id_by_screen_name
} {
    return [db_string user_select {} -default {}]
}

ad_proc -deprecated cc_screen_name_user { screen_name } {

    @return Returns the user ID for a particular screen name, or an empty string
    if none exists.

    @see acs_user::get_user_id_by_screen_name

} {
    return [util_memoize [list cc_lookup_screen_name_user $screen_name]]
}

ad_proc -deprecated -private cc_lookup_email_user { email } {
    Return the user_id of a user given the email. Returns the empty string if no such user exists.
    @see party::get_by_email
} {
    return [db_string user_select {} -default {}]
}

ad_proc -public -deprecated cc_email_from_party { party_id } {
    @return The email address of the indicated party.
    @see party::email
} {
    return [db_string email_from_party {} -default {}]
}

ad_proc -deprecated cc_email_user { email } {

    @return Returns the user ID for a particular email address, or an empty string
    if none exists.

    @see party::get_by_email
} {
    return [util_memoize [list cc_lookup_email_user $email]]
}

ad_proc -deprecated -private cc_lookup_name_group { name } {
    @see group::get_id
} {
    return [db_string group_select {} -default {}]
}

ad_proc -deprecated cc_name_to_group { name } {

    Returns the group ID for a particular name, or an empty string
    if none exists.
    
    @see group::get_id
} {
    return [util_memoize [list cc_lookup_name_group $name]]
}

ad_proc -deprecated ad_user_new {
    email
    first_names
    last_name
    password 
    password_question
    password_answer
    {url ""} 
    {email_verified_p "t"} 
    {member_state "approved"} 
    {user_id ""} 
    {username ""} 
    {authority_id ""}
    {screen_name ""}
} {
    Creates a new user in the system.  The user_id can be specified as an argument to enable double click protection.
    If this procedure succeeds, returns the new user_id.  Otherwise, returns 0.
    
    @see auth::create_user
    @see auth::create_local_account
} {
    return [auth::create_local_account_helper \
		$email \
		$first_names \
		$last_name \
		$password \
		$password_question \
		$password_answer \
		$url \
		$email_verified_p \
		$member_state \
		$user_id \
		$username \
		$authority_id \
		$screen_name]
}

ad_proc -public person::person_p {
    {-party_id:required}
} {
    is this party a person? Cached
} {
    return [util_memoize [list ::person::person_p_not_cached -party_id $party_id]]
}

ad_proc -private person::person_p_not_cached {
    {-party_id:required}
} {
    is this party a person? Cached
} {
    if {[db_0or1row contact_person_exists_p {select '1' from persons where person_id = :party_id}]} {
        return 1
    } else {
        return 0
    }
}
    
ad_proc -public person::new {
    {-first_names:required}
    {-last_name:required}
    {-email {}}
} {
    create a new person
} {
   
    set extra_vars [ns_set create]
    ns_set put $extra_vars first_names $first_names
    ns_set put $extra_vars last_name $last_name
    ns_set put $extra_vars email $email

    set object_type "person"
    return [package_instantiate_object -extra_vars $extra_vars $object_type]
}

ad_proc -public person::delete {
    {-person_id:required}
} {
    delete a person
} {
    db_exec_plsql delete_person {}
}

ad_proc -public person::get {
    {-person_id:required} 
} {
    get info for a person as a Tcl array in list form
} {
    db_1row get_person {}
    
    set person(person_id) $person_id
    set person(first_names) $first_names
    set person(last_name) $last_name

    return [array get person]
}

ad_proc -public person::name {
    {-person_id ""}
    {-email ""}
} {
    get the name of a person. Cached.
} {
    if {$person_id eq "" && $email eq ""} {
        error "You need to provide either person_id or email"
    } elseif {"" ne $person_id && "" ne $email } {
        error "Only provide provide person_id OR email, not both"
    } else {
        return [util_memoize [list person::name_not_cached -person_id $person_id -email $email]]
    }
}

ad_proc -public person::name_flush {
    {-person_id:required}
    {-email ""}
} {
    Flush the person::name cache.
} {
    util_memoize_flush [list person::name_not_cached -person_id $person_id -email $email]
    acs_user::flush_cache -user_id $person_id
}

ad_proc -private person::name_not_cached {
    {-person_id ""}
    {-email ""}
} {
    get the name of a person
} {
    if {$email eq ""} {
        db_1row get_person_name {}
    } else {
        # As the old functionality returned an error, but I want an empty string for e-mail
        # Therefore for emails we use db_string
        set person_name [db_string get_party_name {} -default ""]
    }
    return $person_name
}

ad_proc -public person::update {
    {-person_id:required}
    {-first_names:required}
    {-last_name:required}
} {
    update the name of a person
} {
    db_dml update_person {}
    db_dml update_object_title {}
    name_flush -person_id $person_id
}

# DRB: Though I've moved the bio field to type specific rather than generic storage, I've
# maintained the API semantics exactly as they were before mostly in order to make upgrade
# possible.  In the future, the number of database hits can be diminished by getting rid of
# the separate queries for bio stuff. However, I have removed bio_mime_type because it's
# unused and unsupported in the existing code.

ad_proc -public person::get_bio {
    {-person_id {}}
    {-exists_var {}}
} {
    Get the value of the user's bio(graphy) field.

    @option person_id    The person_id of the person to get the bio for. Leave blank for
       currently logged in user.
    
    @option exists_var The name of a variable in the caller's namespace, which will be set to 1 
                       if the bio column is not null.  Leave blank if you're not
                       interested in this information.
    
    @return The bio of the user as a text string.

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { $person_id eq "" } {
        set person_id [ad_conn user_id]
    }

    if { $exists_var ne "" } {
        upvar $exists_var exists_p
    }

    db_1row select_bio {}
    
    set exists_p [expr {$bio ne ""}]
    
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
    db_dml update_bio {}
}



ad_proc -public acs_user::change_state {
    {-user_id:required}
    {-state:required}
} {
    Change the membership state of a user.
} {
    set rel_id [db_string select_rel_id {} -default {}]

    if {$rel_id eq ""} {
        return
    }

    membership_rel::change_state -rel_id $rel_id -state $state
}

ad_proc -public acs_user::approve {
    {-user_id:required}
} {
    Approve a user
} {
    change_state -user_id $user_id -state "approved"
}

ad_proc -public acs_user::ban {
    {-user_id:required}
} {
    Ban a user
} {
    change_state -user_id $user_id -state "banned"
}

ad_proc -public acs_user::reject {
    {-user_id:required}
} {
    Reject a user
} {
    change_state -user_id $user_id -state "rejected"
}

ad_proc -public acs_user::delete {
    {-user_id:required}
    {-permanent:boolean}
} {
    Delete a user
    
    @param permanent If provided the user will be deleted permanently
                       from the database. Otherwise the user
                       state will merely be set to "deleted".
} {
    if { ! $permanent_p } {
        change_state -user_id $user_id -state "deleted"
        acs_user::flush_cache -user_id $user_id
    } else {
        db_exec_plsql permanent_delete {}
    }
}

ad_proc -public acs_user::unapprove {
    {-user_id:required}
} {
    Unapprove a user
} {
    change_state -user_id $user_id -state "needs approval"
}

ad_proc -public acs_user::get_by_username {
    {-authority_id ""}
    {-username:required}
} {
    Returns user_id from authority and username. Returns the empty string if no user found.
    
    @param authority_id The authority. Defaults to local authority.

    @param username The username of the user you're trying to find.

    @return user_id of the user, or the empty string if no user found.
}  {
    # Default to local authority
    if { $authority_id eq "" } {
        set authority_id [auth::authority::local]
    }
    
    set user_id [util_memoize [list acs_user::get_by_username_not_cached -authority_id $authority_id -username $username]]
    if {$user_id eq ""} {
	util_memoize_flush [list acs_user::get_by_username_not_cached -authority_id $authority_id -username $username]
    }
    return $user_id
}

ad_proc -private acs_user::get_by_username_not_cached {
    {-authority_id:required}
    {-username:required}
} {
    Returns user_id from authority and username. Returns the empty string if no user found.
    
    @param authority_id The authority. Defaults to local authority.

    @param username The username of the user you're trying to find.

    @return user_id of the user, or the empty string if no user found.
}  {
    return [db_string user_id_from_username {} -default {}]
}    

ad_proc -public acs_user::get {
    {-user_id {}}
    {-authority_id {}}
    {-username {}}
    {-array}
    {-include_bio:boolean}
} {
    Get basic information about a user. Uses util_memoize to cache info from the database.
    You may supply either user_id, or  username. 
    If you supply username, you may also supply authority_id, or you may leave it out, in which case it defaults to the local authority.
    If you supply neither user_id nor username, and we have a connection, the currently logged in user will be assumed.

    @option user_id     The user_id of the user to get the bio for. Leave blank for current user.
    
    @option include_bio Whether to include the bio in the user information

    @param  array       The name of an array into which you want the information put. 
    
    The attributes returned are: 

    <ul>
      <li> user_id 
      <li> username
      <li> authority_id
      <li> first_names
      <li> last_name
      <li> name (first_names last_name)
      <li> email
      <li> url
      <li> screen_name
      <li> priv_name 
      <li> priv_email
      <li> email_verified_p
      <li> email_bouncing_p
      <li> no_alerts_until
      <li> last_visit
      <li> last_visit_ansi
      <li> second_to_last_visit
      <li> second_to_last_visit_ansi
      <li> n_sessions
      <li> password_question
      <li> password_answer
      <li> password_changed_date
      <li> member_state
      <li> rel_id
      <li> password_age_days
      <li> creation_date
      <li> creation_ip
      <li> bio (if -include_bio switch is present)
    </ul>
    @result dict of attributes
    @author Lars Pind (lars@collaboraid.biz)
} {
    if { $user_id eq "" } {
        if { $username eq "" } {
            set user_id [ad_conn user_id]
        } else {
            if { $authority_id eq "" } {
                set authority_id [auth::authority::local]
            }
        }
    }

    if { $user_id ne "" } {
        set data [util_memoize [list acs_user::get_from_user_id_not_cached $user_id] [cache_timeout]]
    } else {
        set data [util_memoize [list acs_user::get_from_username_not_cached $username $authority_id] [cache_timeout]]
    }

    if { $include_bio_p } {
        lappend data bio [person::get_bio -person_id [dict get $data user_id]]
    }
    if {[info exists array]} {
        upvar $array row
        array set row $data
    }
    return $data
}

ad_proc -private acs_user::get_from_user_id_not_cached { user_id } {
    Returns an array list with user info from the database. Should
    never be called from application code. Use acs_user::get instead.

    @author Peter Marklund
} {
    db_1row select_user_info {} -column_array row
    
    return [array get row]
}

ad_proc -private acs_user::get_from_username_not_cached { username authority_id } {
    Returns an array list with user info from the database. Should
    never be called from application code. Use acs_user::get instead.

    @author Peter Marklund
} {
    db_1row select_user_info {} -column_array row

    return [array get row]
}

ad_proc -private acs_user::cache_timeout {} {
    Returns the number of seconds the user info cache is kept.

    @author Peter Marklund
} {
    # TODO: This should maybe be an APM parameter
    return 3600
}

ad_proc -public acs_user::flush_cache { 
    {-user_id:required}
} {
    Flush the acs_user::get cache for the given user_id.

    @author Peter Marklund
} {
    util_memoize_flush [list acs_user::get_from_user_id_not_cached $user_id]
    #
    # Get username and authority_id so we can flush the
    # get_from_username_not_cached proc.
    #
    # Note, that it might be the case, that this function is called
    # for user_ids, which are "persons", but do not qualify as
    # "users". Therefore, the catch is used (like in earlier versions)
    #
    catch {
        set u [acs_user::get -user_id $user_id]
        set username     [dict get $u username]
        set authority_id [dict get $u authority_id]
        util_memoize_flush [list acs_user::get_from_username_not_cached $username $authority_id]
        util_memoize_flush [list acs_user::get_by_username_not_cached -authority_id $authority_id -username $username]
    }
}

ad_proc -public acs_user::get_element {
    {-user_id {}}
    {-authority_id {}}
    {-username {}}
    {-element:required}
} {
    Get a particular element from the basic information about a user returned by acs_user::get.
    Throws an error if the element does not exist.

    @option user_id     The user_id of the user to get the bio for. Leave blank for current user.

    @option element     Which element you want to retrieve.
    
    @return The element asked for.

    @see acs_user::get
} {
    acs_user::get \
        -user_id $user_id \
        -authority_id $authority_id \
        -username $username \
        -array row \
        -include_bio=[string equal $element "bio"]
    
    return $row($element)
}

ad_proc -public acs_user::update {
    {-user_id:required}
    {-authority_id}
    {-username}
    {-screen_name}
    {-password_question}
    {-password_answer}
    {-email_verified_p}
} {
    Update information about a user. 
    Feel free to expand this with more switches later as needed, as long as they're optional.

    @param  user_id            The ID of the user to edit
    @option authority_id       Authortiy
    @option username           Username
    @option screen_name        The new screen_name for the user
    @option password_question  The new password_question for the user
    @option password_answer    The new password_question for the user
    @option email_verified_p   Whether the email address has been verified

    @author Lars Pind (lars@collaboraid.biz)
} {
    set cols [list]
    foreach var { authority_id username screen_name password_question password_answer email_verified_p } {
        if { [info exists $var] } {
            lappend cols "$var = :$var"
        }
    }
    db_dml user_update {}

    flush_cache -user_id $user_id
}

ad_proc -public acs_user::get_user_id_by_screen_name {
    {-screen_name:required}
} {
    Returns the user_id from a screen_name, or empty string if no user found.
    Searches all users, including banned, deleted, unapproved, etc.
} {
    return [db_string select_user_id_by_screen_name {} -default {}]
}



ad_proc -public acs_user::site_wide_admin_p {
    {-user_id ""}
} {
    Return 1 if the specified user (defaults to logged in user)
    is site-wide administrator and 0 otherwise.

    @param user_id The id of the user to check for admin privilege.

    @author Peter Marklund
} {
    if { $user_id eq ""} {
        set user_id [ad_conn user_id]
    }

    return [permission::permission_p -party_id $user_id \
		-object_id [acs_lookup_magic_object security_context_root] \
		-privilege "admin"]
}

ad_proc -public acs_user::registered_user_p {
    {-user_id ""}
} {
    Return 1 if the specified user (defaults to logged in user)
    is a registered user and 0 otherwise.

    A registered user is a user who is in the view registered_users and
    this is primarily true for any user who is approved and has a
    verified e-mail.

    @param user_id The id of the user to check.

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
} {
    if { $user_id eq ""} {
        set user_id [ad_conn user_id]
    }

    return [db_string registered_user_p {} -default 0]
}


ad_proc -public acs_user::ScreenName {} {
    Get the value of the ScreenName parameter. Checked to ensure that it only returns none, solicit, or require.
} {
    set value [parameter::get -parameter ScreenName -package_id [ad_acs_kernel_id] -default "solicit"]
    if { [lsearch { none solicit require } $value] == -1 } {
        ns_log Error "acs-kernel.ScreenName parameter invalid. Set to '$value', should be one of none, solicit, or require."
        return "solicit"
    } else {
        return $value
    }

}

ad_proc -public party::update {
    {-party_id:required}
    {-email}
    {-url}
} {
    Update information about a party.

    @param party_id The ID of the party to edit
    @param email    The new email for the party
    @param url      The new URL for the party

    @author Lars Pind (lars@collaboraid.biz)
} {
    set cols [list]
    foreach var { email url } {
        if { [info exists $var] } {
            lappend cols "$var = :$var"
        }
    }
    db_dml party_update {}
    if {[info exists email]} {
	db_dml object_title_update {}
	util_memoize_flush [list ::party::email_not_cached -party_id $party_id]
    }
    acs_user::flush_cache -user_id $party_id
}

ad_proc -public party::get_by_email {
    {-email:required}
} {
    Return the party_id of the party with the given email. 
    Uses a lowercase comparison as we don't allow for parties
    to have emails that only differ in case.
    Returns empty string if no party found.

    @return party_id
} {
    #    return [db_string select_party_id {} -default ""]

    # The following query is identical in the result as the one above
    # It just takes into account that some applications (like contacts) make email not unique
    # Instead of overwriting this procedure in those packages, I changed it here, as the functionality
    # is unchanged.
    return [lindex [db_list select_party_id {}] 0]
}

ad_proc -public party::approved_members {
    {-party_id:required}
    {-object_type ""}
} {
    Get a list of approved members of the given party.
   
    @param party_id The id of the party to get members for
    @param object_type Restrict to only members of this object type. For example,
                       if you are only interested in users, set to "user".

    @author Peter Marklund
} {
    if { $object_type ne "" } {
        set sql {
            select pamm.member_id
            from party_approved_member_map pamm, acs_objects ao
            where pamm.party_id  = :party_id
            and   pamm.member_id = ao.object_id
            and   ao.object_type = :object_type
        }
    } {
        set sql {
            select pamm.member_id
            from party_approved_member_map pamm
            where pamm.party_id = :party_id
        }
    }

    return [db_list select_party_members $sql]
}

ad_proc -public acs_user::get_portrait_id {
    {-user_id:required}
} {
    Return the image_id of the portrait of a user, if it does not exist, return 0

    @param user_id user_id of the user for whom we need the portrait
} {
    return [util_memoize [list acs_user::get_portrait_id_not_cached -user_id $user_id] 600]
}

ad_proc -private acs_user::get_portrait_id_not_cached {
    {-user_id:required}
} {
    Return the image_id of the portrait of a user, if it does not exist, return 0

    @param user_id user_id of the user for whom we need the portrait
} {
    return [db_string get_item_id "" -default 0]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
