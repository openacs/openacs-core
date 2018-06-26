ad_library {

    Community routines (dealing with users, parties, etc.).

    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 11 Aug 2000
    @cvs-id $Id$

}

namespace eval party {}
namespace eval person {}
namespace eval acs_user {}

ad_proc -public person::person_p {
    {-party_id:required}
} {
    is this party a person? Cached
} {
    return [string is true -strict [party::get -party_id $party_id -element person_p]]
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
    party::flush_cache -party_id $person_id
}

ad_proc -deprecated -public person::get {
    {-person_id:required}
} {
    get info for a person as a Tcl array in list form<br>
    DEPRECATED: plese use the new generic party api

    @see party::get
} {
    return [party::get -party_id $person_id]
}

ad_proc -deprecated -public person::name_flush {
    {-person_id:required}
    {-email ""}
} {
    Flush the person::name cache.<br>
    DEPRECATED: plese use the new generic party api

    @see party::flush_cache
} {
    party::flush_cache -party_id $person_id
}

ad_proc -deprecated -public person::name {
    {-person_id ""}
    {-email ""}
} {
    get the name of a person<br>
    DEPRECATED: plese use the new generic party api

    @see party::get
} {
    return [party::get -party_id $person_id -email $email -element name]
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
    party::flush_cache -party_id $person_id
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

    set bio [party::get -party_id $person_id -element bio]

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
    party::flush_cache -party_id $person_id
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
    party::flush_cache -party_id $user_id
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

ad_proc -public acs_user::unapprove {
    {-user_id:required}
} {
    Unapprove a user
} {
    change_state -user_id $user_id -state "needs approval"
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
    } else {
        # portrait is also an entry in acs_objects with creation_user
        # set to this user. Therefore won't be deleted by cascade and
        # must be removed manually
        acs_user::erase_portrait -user_id $user_id
        db_exec_plsql permanent_delete {}
        party::flush_cache -party_id $user_id
    }
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

    set key [list get_by_username -authority_id $authority_id -username $username]
    set user_id [ns_cache eval party_info_cache $key {
        acs_user::get_by_username_not_cached \
            -authority_id $authority_id \
            -username     $username
    }]
    if {$user_id eq ""} {
        ns_cache flush party_info_cache $key
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
    {-element ""}
    {-array}
    {-include_bio:boolean}
} {
    Get basic information about a user. You may supply either user_id,
    or username. If you supply username, you may also supply
    authority_id, or you may leave it out, in which case it defaults
    to the local authority. If you supply neither user_id nor
    username, and we have a connection, the currently logged in user
    will be assumed.

    @param user_id     The user_id of the user to get the bio for. Leave blank for current user.
    @param element If specified, only this element in the dict will be
                   returned. If an array was specified, this will
                   contain only this element.
    @option include_bio Whether to include the bio in the user
                        information. This flag is deprecated and bio
                        will be now always returned.

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
      <li> bio
    </ul>
    @result dict of attributes
    @author Lars Pind (lars@collaboraid.biz)
} {
    if { $user_id eq "" } {
        set user_id [expr {$username ne "" ?
                           [acs_user::get_by_username \
                                -authority_id $authority_id \
                                -username     $username] :
                           [ad_conn user_id]}]
    }

    set data [party::get -party_id $user_id -element $element]

    if {$include_bio_p} {
        ns_log warning "acs_user::get: -include_bio flag is deprecated. Bio will be returned in any case."
    }

    if {[info exists array]} {
        upvar $array row
        if {$element eq ""} {
            array set row $data
        } else {
            set row($element) $data
        }
    }

    return $data
}

ad_proc -deprecated -public acs_user::flush_cache {
    {-user_id:required}
} {
    Flush the acs_user::get cache for the given user_id.<br>
    DEPRECATED: plese use the new generic party api

    @see party::flush_cache

    @author Peter Marklund
} {
    party::flush_cache -party_id $user_id
}

ad_proc -deprecated -public acs_user::get_element {
    {-user_id {}}
    {-authority_id {}}
    {-username {}}
    {-element:required}
} {
    Get a particular element from the basic information about a user returned by acs_user::get.
    Throws an error if the element does not exist.<br>
    DEPRECATED: plese use the new 'element' parameter in acs_user::get

    @see acs_user::get

    @option user_id     The user_id of the user to get the bio for. Leave blank for current user.

    @option element     Which element you want to retrieve.

    @return The element asked for.

    @see acs_user::get
} {
    return [acs_user::get \
                -user_id $user_id \
                -authority_id $authority_id \
                -username $username \
                -element $element]
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
    @option authority_id       Authority
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

    party::flush_cache -party_id $user_id
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
		-object_id [acs_magic_object security_context_root] \
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
    return [party::get -party_id $user_id -element registered_user_p]
}


ad_proc -public acs_user::ScreenName {} {
    Get the value of the ScreenName parameter. Checked to ensure that it only returns none, solicit, or require.
} {
    set value [parameter::get -parameter ScreenName -package_id [ad_acs_kernel_id] -default "solicit"]
    if { $value ni {"none" "solicit" "require"} } {
        ns_log Error "acs-kernel.ScreenName parameter invalid. Set to '$value', should be one of none, solicit, or require."
        return "solicit"
    } else {
        return $value
    }
}

ad_proc -deprecated -public party::email {
    -party_id:required
} {
    this returns the parties email. Cached<br>
    DEPRECATED: plese use the new generic party api

    @see party::get
} {
    return [party::get -party_id $party_id -element email]
}

ad_proc -public party::get {
    {-party_id ""}
    {-email ""}
    {-element ""}
} {
    Returns party information. Will also retrieve whether this party
    is also a person, a group, a user or a registered user and in this
    case also extra information belonging in referenced table will be
    extracted.<br>
    <br>
    Cached version

    @param party_id id of the party
    @param email if specified and no party_id is given, party lookup
                 will happen by email.
    @param element if specified, only this attribute will be returned
                   from the whole dict.

    @return dict containing party information, or an empty dict if no
            party was found. A string if 'element' was specified.
} {
    if {$party_id eq ""} {
        set party_id [party::get_by_email -email $email]
    }

    set key [list get $party_id]
    set data [ns_cache eval party_info_cache $key {
        party::get_not_cached -party_id $party_id
    }]

    # don't cache invalid parties
    if {[llength [dict keys $data]] == 0} {
        ns_cache flush party_info_cache $key
    }

    if {$element ne ""} {
        return [expr {[dict exists $data $element] ?
                      [dict get $data $element] : ""}]
    } else {
        return $data
    }
}

ad_proc -private party::get_not_cached {
    {-party_id:required}
} {
    Returns party information. Will also retrieve whether this party
    is also a person, a group, a user or a registered user and in this
    case also extra information belonging in referenced table will be
    extracted.

    @param party_id id of the party

    @return dict containing party information. If no party was found,
            an empty dict will be returned.
} {
    set registered_users_group_id [acs_magic_object "registered_users"]

    set party_p [db_0or1row party_info {
        select o.object_id,
               o.object_type,
               o.title,
               o.package_id,
               o.context_id,
               o.security_inherit_p,
               o.creation_user,
               o.creation_date,
               o.creation_ip,
               o.last_modified,
               o.modifying_user,
               o.modifying_ip,
               pa.party_id,
               pa.email,
               pa.url,
               pe.person_id,
               pe.person_id is not null as person_p,
               pe.first_names,
               pe.last_name,
               pe.first_names || ' ' || pe.last_name as name,
               pe.bio,
               u.user_id,
               u.user_id is not null as user_p,
               u.authority_id,
               u.username,
               u.screen_name,
               u.priv_name,
               u.priv_email,
               u.email_verified_p,
               u.email_bouncing_p,
               u.no_alerts_until,
               u.last_visit,
               to_char(last_visit, 'YYYY-MM-DD HH24:MI:SS') as last_visit_ansi,
               u.second_to_last_visit,
               to_char(second_to_last_visit, 'YYYY-MM-DD HH24:MI:SS') as second_to_last_visit_ansi,
               u.n_sessions,
               u.password,
               u.salt,
               u.password_question,
               u.password_answer,
               u.password_changed_date,
               extract(day from current_timestamp - password_changed_date) as password_age_days,
               u.auth_token,
               mm.rel_id,
               mr.member_state = 'approved' as registered_user_p,
               mr.member_state,
               g.group_id,
               g.group_id is not null as group_p,
               g.group_name,
               g.description as group_description,
               g.join_policy
        from parties pa
             left join persons pe on pa.party_id = pe.person_id
             left join users u on pe.person_id = u.user_id
             left join group_member_map mm on mm.member_id = u.user_id
                                          and mm.group_id  = mm.container_id
                                          and mm.group_id  = :registered_users_group_id
                                          and mm.rel_type  = 'membership_rel'
             left join membership_rels mr on mr.rel_id = mm.rel_id
             left join groups g on g.group_id = pa.party_id,
             acs_objects o
        where o.object_id = pa.party_id
          and pa.party_id = :party_id
    } -column_array row]

    if {!$party_p} {
        return [dict create]
    } else {
        return [array get row]
    }
}

ad_proc -public party::flush_cache {
    {-party_id:required}
} {
    Flush the party cache
} {
    set party [party::get -party_id $party_id]

    set keys [list]
    lappend keys [list get $party_id]
    lappend keys [list get_by_email [dict get $party email]]
    if {[dict get $party user_p]} {
        lappend keys [list get_portrait_id -user_id $party_id]
        lappend keys [list get_by_username \
                          -authority_id [dict get $party authority_id] \
                          -username [dict get $party username]]
    }

    foreach key $keys {
        ns_cache flush party_info_cache $key
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
    }
    party::flush_cache -party_id $party_id
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
    set key [list get_by_email $email]
    set party_id [ns_cache eval party_info_cache $key {
        party::get_by_email_not_cached -email $email
    }]

    # don't cache invalid parties
    if {$party_id eq ""} {
        ns_cache flush party_info_cache $key
    }

    return $party_id
}

ad_proc -public party::get_by_email_not_cached {
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
    set key [list get_portrait_id -user_id $user_id]
    return [ns_cache eval party_info_cache $key {
        acs_user::get_portrait_id_not_cached -user_id $user_id
    }]
}

ad_proc -private acs_user::get_portrait_id_not_cached {
    {-user_id:required}
} {
    Return the image_id of the portrait of a user, if it does not exist, return 0

    @param user_id user_id of the user for whom we need the portrait
} {
    set item_id [content::item::get_id_by_name \
                     -name "portrait-of-user-$user_id" \
                     -parent_id $user_id]
    return [expr {$item_id ne "" ? $item_id : 0}]
}

ad_proc -public acs_user::create_portrait {
    {-user_id:required}
    {-description ""}
    {-filename ""}
    {-mime_type ""}
    {-file:required}
} {
    Sets (or resets) the portraif for current user to the one
    specified.

    @param user_id user_id of user whose portrait we want to set.

    @param description A caption for the portrait.

    @param filename Original filename of the portrait. Used to guess
    the mimetype if an explicit one is not specified.

    @param mime_type mimetype of the portrait. If missing, filename
    will be used to guess one.

    @param file Actual file containing the portrait

    @return item_id of the new content item
} {
    # Delete old portrait, if any
    acs_user::erase_portrait -user_id $user_id

    if {$mime_type eq ""} {
        # This simple check will suffice here. CR has its own means to
        # ensure a valid mimetype
        set mime_type [ns_guesstype $filename]
    }

    # Create the new portrait
    set item_id [content::item::new \
                     -name "portrait-of-user-$user_id" \
                     -parent_id $user_id \
                     -content_type image \
                     -storage_type file \
                     -creation_user [ad_conn user_id] \
                     -creation_ip [ad_conn peeraddr] \
                     -description $description \
                     -tmp_filename $file \
                     -is_live t \
                     -mime_type $mime_type]

    # Create portrait relationship
    db_exec_plsql create_rel {}

    return $item_id

}

ad_proc -public acs_user::erase_portrait {
    {-user_id:required}
} {
    Erases portrait of a user

    @param user_id user_id of user whose portrait we want to delete
} {
    set item_id [acs_user::get_portrait_id \
                     -user_id $user_id]

    if { $item_id != 0 } {
        # Delete the item
        content::item::delete -item_id $item_id
    }

    # Flush the portrait cache
    set key [list get_portrait_id -user_id $user_id]
    ns_cache flush user_info_cache $key
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
