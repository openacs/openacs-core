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
    Is this party a person?
} {
    set person [person::get_person_info -person_id $party_id]
    return [expr {[llength $person] > 0}]
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
    person::flush_cache -person_id $person_id
}

ad_proc -public person::get {
    {-person_id:required}
    {-element ""}
} {
    Get person information together with inherited party and object
    one. If person-only information is what you need, probably a
    better choice would be person::get_person_info.

    @param element if specified, only value in dict with this key will
                   be returned.

    @see person::get_person_info
    @see party::get

    @return a dict or a single string value if <code>-element</code>
    was specified.
} {
    set data [party::get -party_id $person_id]
    # no party found = no user
    if {[llength $data] == 0} {
        return [list]
    }

    # query person info only if we don't have what was asked for already
    if {$element eq "" || ![dict exists $data $element]} {
        lappend data {*}[person::get_person_info -person_id $person_id]
    }

    if {$element ne ""} {
        set data [expr {[dict exists $data $element] ?
                        [dict get $data $element] : ""}]
    }

    return $data
}

ad_proc -public person::get_person_info {
    -person_id:required
    {-element ""}
} {
    Extracts person information. Differently from person::get this
    proc won't return generic party information.

    @param element if specified, only value in dict with this key will
                   be returned.

    @see person::get

    @return a dict or a single string value if <code>-element</code>
    was specified.
} {
    set key [list get_person_info $person_id]

    set person [ns_cache eval person_info_cache $key {
        person::get_person_info_not_cached -person_id $person_id
    }]

    # don't cache invalid persons
    if {[llength $person] == 0} {
        ns_cache flush person_info_cache $key
    }

    if {$element ne ""} {
        return [expr {[dict exists $person $element] ?
                      [dict get $person $element] : ""}]
    } else {
        return $person
    }
}

ad_proc -public person::get_person_info_not_cached {
    {-person_id:required}
} {
    Extracts person information. Differently from person::get this
    proc won't return generic party information.

    @see person::get
} {
    set person_p [db_0or1row get_person_info {
        select person_id,
               first_names,
               last_name,
               first_names, first_names || ' ' || last_name as name,
               bio
          from persons
         where person_id = :person_id
    } -column_array person]

    if {$person_p} {
        return [array get person]
    } else {
        return [list]
    }
}

ad_proc -public person::flush_person_info {
    {-person_id:required}
} {
    Flush only info coming from person::get_person_info proc.

    @see person::get_person_info
} {
    set key [list get_person_info $person_id]
    ns_cache flush person_info_cache $key
}

ad_proc -deprecated -public person::name_flush {
    {-person_id:required}
    {-email ""}
} {
    Flush the person::name cache.

    Deprecated: please use suggested alternative.

    @see person::flush_person_info
} {
    person::flush_person_info -person_id $person_id
}

ad_proc -public person::flush_cache {
    {-person_id:required}
} {
    Flush all caches for specified person. This makes sense when we
    really want all person information to be flushed. Finer-grained
    procs exist and should be used when is clear what we want to
    delete.

    @see person::flush_person_info
    @see party::flush_cache
} {
    person::flush_person_info -person_id $person_id
    party::flush_cache -party_id $person_id
}

ad_proc -public person::name {
    {-person_id ""}
    {-email ""}
} {
    Return the name of a person.

    @see party::get
} {
    if {$person_id eq ""} {
        set person_id [party::get_by_email -email $email]
    }
    return [person::get_person_info -person_id $person_id -element name]
}

ad_proc -public person::update {
    {-person_id:required}
    -first_names
    -last_name
    -bio
} {
    Update person information.
} {
    set cols [list]
    foreach var {first_names last_name bio} {
        if { [info exists $var] } {
            lappend cols "$var = :$var"
        }
    }
    if {[llength $cols] == 0} {
        return
    }

    db_dml update_person {}

    # update object title if changed
    if {[info exists first_names] ||
        [info exists last_name]} {
        db_dml update_object_title {}
        # need to flush also objects attributes for the party
        person::flush_cache -person_id $person_id
    } else {
        # only need to flush person information (e.g. bio)
        person::flush_person_info -person_id $person_id
    }
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

    set bio [person::get_person_info -person_id $person_id -element bio]

    set exists_p [expr {$bio ne ""}]

    return $bio
}

ad_proc -deprecated -public person::update_bio {
    {-person_id:required}
    {-bio:required}
} {
    Update the bio for a person.

    Deprecated: please use person::update as now supports optional parameters.

    @see person::update

    @param person_id The ID of the person to edit bio for
    @param bio       The new bio for the person

    @author Lars Pind (lars@collaboraid.biz)
} {
    person::update -person_id $person_id -bio $bio
}


ad_proc -public acs_user::change_state {
    {-user_id:required}
    {-state:required}
} {
    Change the membership state of a user.
} {
    set rel_id [acs_user::get_user_info \
                    -user_id $user_id -element rel_id]

    # most likely this is not a registered user
    if {$rel_id eq ""} {
        return
    }

    membership_rel::change_state -rel_id $rel_id -state $state
    # flush user-specific info
    acs_user::flush_user_info -user_id $user_id
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
        # flush before actual deletion, so all the information is
        # there to be retrieved
        acs_user::flush_cache -user_id $user_id        
        db_exec_plsql permanent_delete {}
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

    set key [list get_by_username \
                 -authority_id $authority_id -username $username]
    set user_id [ns_cache eval user_info_cache $key {
        acs_user::get_by_username_not_cached \
            -authority_id $authority_id \
            -username     $username
    }]

    # don't cache invalid usernames
    if {$user_id eq ""} {
        ns_cache flush user_info_cache $key
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
    Get all information about a user, together with related person,
    party and object information. In case only user-specific
    information was needed, probably a better alternative could be
    acs_user::get_person_info.<br>
    <br>
    The attributes returned are all those retrieved by person::get and
    acs_user::get_person_info.


    @param user_id User id to retrieve. Defaults to currently connected user.
    @param authority_id if user_id was not specified, but a username
                        was given, this proc will try to retrieve a
                        user_id from username and authority. If
                        authority_id is left blank, will default to
                        the local authority.
    @param username if specified and no user_id was give, will be used
                    to retrieve user_id from the authority. If no
                    user_id and no username were specified, proc will
                    default to currently connected user.
    @param element If specified, only this element in the dict will be
                   returned. If an array was specified, This function will
                   contain only this element.
    @option include_bio Whether to include the bio in the user
                        information. This flag is deprecated and bio
                        will be now always returned.

    @param array The name of an array into which you want the
                 information put. This parameter is not mandatory, and
                 the actual suggested way to retrieve information from
                 this proc is to just set a variable from the return
                 value and use it as a dict.

    @see acs_user::get_person_info
    @see person::get

    @return dict or a single string value if the <code>-element</code>
            parameter was specified.

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { $user_id eq "" } {
        set user_id [expr {$username ne "" ?
                           [acs_user::get_by_username \
                                -authority_id $authority_id \
                                -username     $username] :
                           [ad_conn user_id]}]
    }

    set data [person::get -person_id $user_id]
    # no person found = no user
    if {[llength $data] == 0} {
        return [list]
    }

    # query user info only if we don't have what was asked for already
    if {$element eq "" || ![dict exists $data $element]} {
        lappend data {*}[acs_user::get_user_info -user_id $user_id]
    }

    if {$element ne ""} {
        set data [expr {[dict exists $data $element] ?
                        [dict get $data $element] : ""}]
    }

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

ad_proc acs_user::get_user_info {
    -user_id:required
    {-element ""}
} {
    Extracts user information. Differently from acs_user::get this
    proc won't return generic party information.

    @param element if specified, only value with this key in the dict
           will be returned.

    @see acs_user::get

    @return dict or a single string value if the <code>-element</code>
            parameter was specified.
} {
    set key [list get_user_info $user_id]

    set user [ns_cache eval user_info_cache $key {
        acs_user::get_user_info_not_cached -user_id $user_id
    }]

    # don't cache invalid users
    if {[llength $user] == 0} {
        ns_cache flush user_info_cache $key
    }

    if {$element ne ""} {
        return [expr {[dict exists $user $element] ?
                      [dict get $user $element] : ""}]
    } else {
        return $user
    }
}

ad_proc -private acs_user::get_user_info_not_cached {
    -user_id:required
} {
    Extracts user information. Differently from acs_user::get this
    proc won't return generic party information.

    @return a dict
} {
    set registered_users_group_id [acs_magic_object "registered_users"]
    set user_p [db_0or1row user_info {
        select u.user_id,
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
               mr.member_state
        from users u
             left join group_member_map mm on mm.member_id = u.user_id
                                          and mm.group_id  = mm.container_id
                                          and mm.group_id  = :registered_users_group_id
                                          and mm.rel_type  = 'membership_rel'
             left join membership_rels mr on mr.rel_id = mm.rel_id
        where u.user_id = :user_id
    } -column_array user]

    if {$user_p} {
        return [array get user]
    } else {
        return [list]
    }
}

ad_proc -public acs_user::flush_user_info {
    {-user_id:required}
} {
    Flush only info coming from acs_user::get_user_info proc. This
    includes also lookup by username, because username and
    authority_id might also have changed.

    @see acs_user::get_user_info
} {
    set user [acs_user::get_user_info -user_id $user_id]
    ns_cache flush user_info_cache [list get_by_username \
                                        -authority_id [dict get $user authority_id] \
                                        -username [dict get $user username]]
    ns_cache flush user_info_cache [list get_user_info $user_id]
}

ad_proc -public acs_user::flush_cache {
    {-user_id:required}
} {
    Flush all caches for specified user. This makes sense when we
    really want all user information to be flushed. Finer-grained
    procs exist and should be used when is clear what we want to
    delete.

    @see acs_user::flush_user_info
    @see acs_user::flush_portrait
    @see person::flush_cache

    @author Peter Marklund
} {
    acs_user::flush_user_info -user_id $user_id
    acs_user::flush_portrait -user_id $user_id
    person::flush_cache -person_id $user_id
}

ad_proc -public acs_user::get_element {
    {-user_id {}}
    {-authority_id {}}
    {-username {}}
    {-element:required}
} {
    Get a particular element from the basic information about a user returned by acs_user::get.
    Throws an error if the element does not exist.

    It is recommended to use use acs_user::get instead.
    This function will be probably deprecated after the release of 5.10.

    @option user_id     The user_id of the user to get the bio for. Leave blank for current user.
    @option element     Which element you want to retrieve.
    @return             The element asked for.

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
    acs_user::flush_user_info -user_id $user_id
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
    set registered_p [acs_user::get_user_info \
                          -user_id $user_id \
                          -element registered_user_p]
    return [string is true -strict $registered_p]
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

ad_proc -public party::email {
    -party_id:required
} {
    Return the parties email.

    This function will be probably deprecated in the future: please
    use the new generic party API.

    @return the parties email.
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
    extracted.

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
    if {[llength $data] == 0} {
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
               pa.url
        from parties pa,
             acs_objects o
        where o.object_id = pa.party_id
          and pa.party_id = :party_id
    } -column_array row]

    if {!$party_p} {
        return [list]
    } else {
        return [array get row]
    }
}

ad_proc -public party::party_p {
    -object_id:required
} {

    @author Malte Sussdorff
    @creation-date 2007-01-26

    @param object_id object_id which is checked if it is a party
    @return true if object_id is a party

} {
    return [expr {[llength [party::get -party_id $object_id]] != 0}]
}

ad_proc -public party::flush_cache {
    {-party_id:required}
} {
    Flush the party cache
} {
    set email [party::get -party_id $party_id -element email]

    set keys [list]
    lappend keys \
        [list get $party_id] \
        [list get_by_email $email]

    foreach key $keys {
        ns_cache flush party_info_cache $key
    }
}

ad_proc party::types_valid_for_rel_type_multirow {
    {-datasource_name object_types}
    {-start_with party}
    {-rel_type "membership_rel"}
} {
    creates multirow datasource containing party types starting with
    the $start_with party type.  The datasource has columns that are
    identical to the relation_types_allowed_to_group_multirow, which is why
    the columns are broadly named "object_*" instead of "party_*".  A
    common template can be used for generating select widgets etc. for
    both this datasource and the relation_types_allowed_to_groups_multirow
    datasource.

    All subtypes of $start_with are returned, but the "valid_p" column in
    the datasource indicates whether the type is a valid one for $group_id.

    Includes fields that are useful for
    presentation in a hierarchical select widget:
    <ul>
    <li> object_type
    <li> object_type_enc - encoded object type
    <li> indent          - an html indentation string
    <li> pretty_name     - pretty name of object type
    <li> valid_p         - 1 or 0 depending on whether the type is valid
    </ul>

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 2000-02-07

    @param datasource_name
    @param start_with
    @param rel_type - if unspecified, then membership_rel is used
} {

    template::multirow create $datasource_name \
            object_type object_type_enc indent pretty_name valid_p

    # Special case "party" because we don't want to display "party" itself
    # as an option, and we don't want to display "rel_segment" as an
    # option.
    if {$start_with eq "party"} {
        set start_with_clause [db_map start_with_clause_party]
    } else {
        set start_with_clause [db_map start_with_clause]
    }

    db_foreach select_sub_rel_types {} {
        template::multirow append $datasource_name $object_type \
            [ad_urlencode $object_type] $indent $pretty_name $valid_p
    }

}

ad_proc -public party::name {
    {-party_id ""}
    {-email ""}
} {
    Gets the party name of the provided party_id

    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)

    @param party_id The party_id to get the name from.
    @param email The email of the party

    @return The party name
} {
    if {$party_id eq "" && $email eq ""} {
        error "You need to provide either party_id or email"
    } elseif {"" ne $party_id && "" ne $email } {
        error "Only provide party_id OR email, not both"
    }

    if {$party_id eq ""} {
        set party_id [party::get_by_email -email $email]
    }

    set name [person::name -person_id $party_id]

    if { $name eq "" && [apm_package_installed_p "organizations"] } {
        set name [db_string get_org_name {} -default ""]
    }

    if { $name eq "" } {
        set name [db_string get_group_name {} -default ""]
    }

    if { $name eq "" } {
        set name [db_string get_party_name {} -default ""]
    }

    return $name
}

ad_proc party::new {
    { -form_id "" }
    { -variable_prefix "" }
    { -creation_user "" }
    { -creation_ip "" }
    { -party_id "" }
    { -context_id "" }
    { -email "" }
    party_type
} {
    Creates a party of this type by calling the .new function for
    the package associated with the given party_type. This
    function will fail if there is no package.

    <p>
    There are now several ways to create a party of a given
    type. You can use this Tcl API with or without a form from the form
    system, or you can directly use the PL/SQL API for the party type.

    <p><b>Examples:</b>
    <pre>

    # OPTION 1: Create the party using the Tcl Procedure. Useful if the
    # only attribute you need to specify is the party name

    db_transaction {
        set party_id [party::new -email "joe@foo.com" $party_type]
    }


    # OPTION 2: Create the party using the Tcl API with a templating
    # form. Useful when there are multiple attributes to specify for the
    # party

    template::form create add_party
    template::element create add_party email -value "joe@foo.com"

    db_transaction {
        set party_id [party::new -form_id add_party $party_type ]
    }

    # OPTION 3: Create the party using the PL/SQL package automatically
    # created for it

    # creating the new party
    set party_id [db_exec_plsql add_party "
      begin
        :1 := ${party_type}.new (email => 'joe@foo.com');
      end;
    "]

    </pre>

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 2001-02-08

    @return <code>party_id</code> of the newly created party

    @param form_id The form id from templating form system (see
    example above)

    @param email The email of this party. Note that if
    email is specified explicitly, this value will be used even if
    there is a email attribute in the form specified by
    <code>form_id</code>.

    @param party_type The type of party we are creating

} {

    # We select out the name of the primary key. Note that the
    # primary key is equivalent to party_id as this is a subtype of
    # acs_party

    if { ![db_0or1row package_select {
        select t.package_name, lower(t.id_column) as id_column
          from acs_object_types t
         where t.object_type = :party_type
    }] } {
        error "Object type \"$party_type\" does not exist"
    }

    set var_list [list \
            [list context_id $context_id]  \
            [list $id_column $party_id] \
            [list "email" $email]]

    return [package_instantiate_object \
            -creation_user $creation_user \
            -creation_ip $creation_ip \
            -package_name $package_name \
            -start_with "party" \
            -var_list $var_list \
            -form_id $form_id \
            -variable_prefix $variable_prefix \
            $party_type]

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
    return [ns_cache eval user_info_cache $key {
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

ad_proc -private acs_user::flush_portrait {
    {-user_id:required}
} {
    Flush the portrait cache for specified user
} {
    # Flush the portrait cache
    set key [list get_portrait_id -user_id $user_id]
    ns_cache flush user_info_cache $key
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

    acs_user::flush_portrait -user_id $user_id
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
