ad_library {

    Procs to manage groups

    @author mbryzek@arsdigita.com
    @creation-date Thu Dec  7 18:13:56 2000
    @cvs-id $Id$

}


namespace eval group {}

ad_proc -public group::new {
    { -form_id "" }
    { -variable_prefix "" }
    { -creation_user "" }
    { -creation_ip "" }
    { -group_id "" }
    { -context_id "" }
    { -group_name "" }
    { -pretty_name ""}
    {group_type "group"}
} {
    Creates a group of this type by calling the .new function for
    the package associated with the given group_type. This
    function will fail if there is no package.

    <p>
    There are now several ways to create a group of a given
    type. You can use this Tcl API with or without a form from the form
    system, or you can directly use the PL/SQL API for the group type.

    <p><b>Examples:</b>
    <pre>

    # OPTION 1: Create the group using the Tcl Procedure. Useful if the
    # only attribute you need to specify is the group name

    db_transaction {
        set group_id [group::new -group_name "Author" $group_type]
    }


    # OPTION 2: Create the group using the Tcl API with a templating
    # form. Useful when there are multiple attributes to specify for the
    # group

    template::form create add_group
    template::element create add_group group_name -value "Publisher"

    db_transaction {
        set group_id [group::new -form_id add_group $group_type ]
    }

    # OPTION 3: Create the group using the PL/SQL package automatically
    # created for it

    # creating the new group
    set group_id [db_exec_plsql add_group "
      begin
        :1 := ${group_type}.new (group_name => 'Editor');
      end;
    "]

    </pre>

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 10/2000

    @return <code>group_id</code> of the newly created group

    @param form_id The form id from templating form system (see
    example above)

    @param group_name The name of this group. Note that if
    group_name is specified explicitly, this name will be used even if
    there is a group_name attribute in the form specified by
    <code>form_id</code>.

    @param group_type The type of group we are creating. Defaults to group
                      which is what you want in most cases.

    @param group_name The name of this group. This is a required
    variable, though it may be specified either explicitly or through
    <code>form_id</code>

} {

    # We select out the name of the primary key. Note that the
    # primary key is equivalent to group_id as this is a subtype of
    # acs_group

    if { ![db_0or1row package_select {
        select t.package_name, lower(t.id_column) as id_column
          from acs_object_types t
         where t.object_type = :group_type
    }] } {
        error "Object type \"$group_type\" does not exist"
    }

    set var_list [list context_id $context_id]
    lappend var_list [list $id_column $group_id]
    if { $group_name ne "" } {
        lappend var_list [list group_name $group_name]
        if {$pretty_name eq ""} {
            set pretty_name $group_name
        }
    }

    set group_id [package_instantiate_object \
        -creation_user $creation_user \
        -creation_ip $creation_ip \
        -package_name $package_name \
        -start_with "group" \
        -var_list $var_list \
        -form_id $form_id \
        -variable_prefix $variable_prefix \
        $group_type]

    # We can't change the group_name to an I18N version as this would
    # break compatibility with group::member_p -group_name and the
    # like. So instead we change the title of the object of the group
    # (through the pretty name). We just have to change the display of
    # groups to the title at the appropriate places.
    #
    # In case, a pretty_name was already provided in form of a message
    # key, there is no need to convert this a second time.

    if {![regexp [lang::util::message_key_regexp] $pretty_name]} {
        set pretty_name [lang::util::convert_to_i18n -message_key "group_title_${group_id}" -text "$pretty_name"]
    }

    # Update the title to the pretty name
    if {$pretty_name ne ""} {
        db_dml title_update "update acs_objects set title = :pretty_name where object_id = :group_id"
    }
    return $group_id
}

ad_proc group::delete { group_id } {
    Deletes the group specified by group_id, including all
    relational segments specified for the group and any relational
    constraint that depends on this group in any way.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 10/2000

    @return <code>object_type</code> of the deleted group, if it
            was actually deleted. Returns the empty string if the
            object didn't exist to begin with

    @param group_id The group to delete

} {
    if { ![db_0or1row package_select {
        select t.package_name, t.object_type
        from acs_object_types t
        where t.object_type = (select o.object_type
                                 from acs_objects o
                                where o.object_id = :group_id)
    }] } {
        # No package means the object doesn't exist. We're done :)
        return
    }

    # Maybe the relational constraint deletion should be moved to
    # the acs_group package...

    db_exec_plsql delete_group {}

    # Remove the automatically generated message key localizing the
    # group name
    lang::message::unregister acs-translations "group_title_${group_id}"

    return $object_type
}

ad_proc -private group::get_not_cached {
    {-group_id:required}
} {
    Get basic info about a group: group_name, join_policy.

    @return dict containing group_name, title, join_policy, and description
} {
    db_1row group_info {
        select group_name, title, join_policy, description
        from   groups g, acs_objects o
        where  group_id = :group_id
        and object_id = :group_id
    } -column_array row
    return [array get row]
}

ad_proc -public group::get {
    {-group_id:required}
    {-array}
} {
    Get basic info about a group: group_name, join_policy.

    @param array The name of an array in the caller's namespace where the info gets delivered.
    @return dict containing group_name, title, join_policy, and description
    @see group::get_element
} {
    set info [acs::group_cache eval -partition_key $group_id \
                  info-$group_id- {
                      group::get_not_cached -group_id $group_id
                  }]

    if {[info exists array]} {
        upvar 1 $array row
        array set row $info
    }
    return $info
}


ad_proc -public group::get_element {
    {-group_id:required}
    {-element:required}
} {
    Get an element from the basic info about a group: group_name, join_policy.

    @see group::get
} {
    return [dict get [group::get -group_id $group_id] $element]
}

ad_proc -public group::get_id {
    {-group_name:required}
    {-subsite_id ""}
    {-application_group_id ""}
} {
    Retrieve the group_id to a given group-name. If you have more than one group with this name, it will return the first one it finds.
    Keep that in mind when using this procedure.

    @author Christian Langmann (C_Langmann@gmx.de)
    @author Malte Sussdorff (openacs@sussdorff.de)
    @creation-date 2005-06-09

    @param group_name the name of the group to look for
    @param subsite_id the ID of the subsite to search for the group name
    @param application_group_id the ID of the application group to search for the group name

    @return the first group_id of the groups found for that group_name.

} {
    return [util_memoize [list group::get_id_not_cached \
                              -group_name $group_name \
                              -subsite_id $subsite_id \
                              -application_group_id $application_group_id]]
}

ad_proc -private group::get_id_not_cached {
    {-group_name:required}
    {-subsite_id ""}
    {-application_group_id ""}
} {
    Retrieve the group_id to a given group-name.

    @author Christian Langmann (C_Langmann@gmx.de)
    @author Malte Sussdorff (openacs@sussdorff.de)
    @creation-date 2005-06-09

    @param group_name the name of the group to look for

    @return the id of the group

    @error
} {
    if {$subsite_id ne ""} {
        if {$application_group_id ne ""} {
            ad_log warning "group::get_id '$group_name': overwriting specified application_group_id by application group of subsite"
        }
        set application_group_id [application_group::group_id_from_package_id \
                                      -package_id $subsite_id]
    }

    if {$application_group_id ne ""} {
        set group_ids [db_list get_group_id_with_application {
            SELECT g.group_id
            FROM   acs_rels rels
            INNER JOIN composition_rels comp ON rels.rel_id = comp.rel_id
            INNER JOIN groups g              ON rels.object_id_two = g.group_id
            WHERE rels.object_id_one = :application_group_id
            AND   g.group_name = :group_name
        }]
    } else {
        set group_ids [db_list get_group_id {
            select group_id
            from groups
            where group_name = :group_name
        }]
    }
    if {[llength $group_ids] > 1} {
        ad_log warning "group::get_id for '$group_name' returns more than one value; returning the first one"
    }
    return [lindex $group_ids 0]
}

ad_proc -public group::get_members {
    {-group_id:required}
    {-type "party"}
    {-rel_type ""}
    {-member_state ""}
} {
    Get party_ids of all members from cache.

    @param type Type of members - party, person, user
    @param member_state when specified, return only members in this
                        membership state

    @see group::get_members_not_cached
    @see group::flush_members_cache

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-07-26
} {
    acs::group_cache eval -partition_key $group_id \
        members-$group_id-$type-$rel_type-$member_state {
            group::get_members_not_cached -group_id $group_id \
                -type $type -rel_type $rel_type -member_state $member_state
        }
}

ad_proc -private group::get_members_not_cached {
    {-group_id:required}
    {-type:required}
    {-rel_type ""}
    {-member_state ""}
} {
    Get party_ids of all members.

    @param type Type of members - party, person, user
    @param member_state when specified, return only members in this
                        membership state

    @see group::get_members
    @see group::flush_members_cache

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-07-26
} {
    return [db_list group_members {
        select distinct member_id
        from group_member_map m
        where group_id = :group_id
          and (:member_state is null or
               (select member_state from membership_rels
                 where rel_id = m.rel_id) = :member_state)
          and (:type is null or
               :type = 'party' or
               (select object_type from acs_objects
                 where object_id = m.member_id) = :type)
          and (:rel_type is null or
               rel_type = :rel_type)
    }]
}


ad_proc -private group::flush_members_cache {
    {-group_id:required}
} {
    Flush group members cache.

    @see group::get_members
    @see group::get_members_not_cached

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-07-26
} {
    ::acs::group_cache flush_pattern -partition_key $group_id *-$group_id-*
    #util_memoize_flush [list group::get_members_not_cached -group_id $group_id -type party]
    #util_memoize_flush [list group::get_members_not_cached -group_id $group_id -type user]
    #util_memoize_flush [list group::get_members_not_cached -group_id $group_id -type person]
    #util_memoize_flush_regexp [list group::member_p_not_cached -group_id $group_id (.*)]
}

ad_proc -deprecated -public group::permission_p {
    { -user_id "" }
    { -privilege "read" }
    group_id
} {
    THIS PROC SHOULD GO AWAY! All calls to group::permission_p can be
    replaced with permission::permission_p

    Wrapper for ad_permission to allow us to bypass having to
    specify the read privilege

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 10/2000

    @see permission::permission_p

} {
    return [permission::permission_p -party_id $user_id -privilege $privilege -object_id $group_id]
}

ad_proc -public group::join_policy {
    {-group_id:required}
} {
    Returns a group's join policy ('open', 'closed', or 'needs approval')

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 10/2000

} {
    return [dict get [group::get -group_id $group_id] join_policy]
}

ad_proc -public group::description {
    {-group_id:required}
} {
    Returns a group's description

    @creation-date 09/2008

} {
    return [dict get [group::get -group_id $group_id] description]
}

ad_proc -public group::update {
    {-group_id:required}
    {-array:required}
} {
    Updates a group.

    @param group_id The ID of the group to update.

    @param array    Name of array containing the columns to update.
                    Valid columns are group_name, join_policy.
                    Valid join_policy values are 'open', 'closed', 'needs approval'.

} {
    upvar $array row

    # Construct clauses for the update statement
    set columns { group_name join_policy description }
    set set_clauses [list]
    foreach name [array names row] {
        if {$name ni $columns} {
            error "Attribute '$name' isn't valid for groups."
        }
        lappend set_clauses "$name = :$name"
        set $name $row($name)
    }

    if { [llength $set_clauses] == 0 } {
        # No rows to update
        return
    }

    db_dml update_group "
        update groups
        set    [join $set_clauses ", "]
        where  group_id = :group_id
    "

    if {[info exists group_name]} {
        set pretty_name [lang::util::convert_to_i18n -message_key "group_title_${group_id}" -text "$group_name"]
        db_dml update_object_title {
            update acs_objects
            set title = :pretty_name
            where object_id = :group_id
        }
    }
    acs::group_cache flush -partition_key $group_id info-$group_id-
}

ad_proc -public group::possible_member_states {} {
    Returns the list of possible member states: approved, needs approval, banned, merged, rejected, deleted.
} {
    return [list approved "needs approval" banned merged rejected deleted]
}

ad_proc -public group::get_member_state_pretty {
    {-member_state:required}
    {-component pretty_name}
    {-user_name ""}
    {-community_name ""}
    {-site_name ""}
    {-url ""}
    {-locale ""}
} {
    Returns the pretty-name of a member state.
} {
    if {$member_state ni {approved banned deleted merged "needs approval" rejected}} {
        error "invalid member_state '$member_state'"
    }
    #
    # We can't use spaces in message keys, so replace it with a "_".
    #
    regsub -all " " $member_state "_" member_state

    switch -- $component {
        pretty_name {
            set message #acs-kernel.member_state_$member_state#
        }
        action {
            if {$user_name eq ""} { error "user_name must be specified and must be non-empty" }
            set message #acs-kernel.member_state_action_$member_state#
        }
        account_mail {
            if {$site_name eq ""} { error "site_name must be specified and must be non-empty" }
            if {[string match "#*#" $site_name]} {
                # site names can be localized
                set site_name [lang::util::localize $site_name $locale]
            }
            if {$url eq ""} { error "url must be specified and must be non-empty" }
            set message #acs-kernel.member_state_account_mail_$member_state#
        }
        community_mail {
            if {$community_name eq ""} { error "community_name must be specified and must be non-empty" }
            if {[string match "#*#" $community_name]} {
                # community_names can be localized
                set community_name [lang::util::localize $community_name $locale]
            }
            if {$url eq ""} { error "url must be specified and must be non-empty" }
            set message #acs-kernel.member_state_community_mail_$member_state#
        }
        default {
            error "invalid component '$component'"
        }
    }

    return [lang::util::localize $message $locale]
}


ad_proc -public group::get_join_policy_options {} {
    Returns a list of valid join policies in a format suitable for a form builder drop-down.
} {
    return [list \
                [list [_ acs-kernel.common_open] "open"] \
                [list [_ acs-kernel.common_needs_approval] "needs approval"] \
                [list [_ acs-kernel.common_closed] "closed"]]
}

ad_proc -public group::default_member_state {
    { -join_policy "" }
    { -create_p false }
    -no_complain:boolean
} {
    If user has 'create' privilege on group_id OR
       the group's join policy is 'open',
    then default_member_state will return "approved".

    If the group's join policy is 'needs approval'
    then default_member_state will return 'needs approval'.

    If the group's join policy is closed
    then an error will be thrown, unless the no_complain flag is
    set, in which case empty string is returned.

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 10/2000

    @param join_policy - the group's join policy
                         (one of 'open', 'closed', or 'needs approval')

    @param create_p - 1 if the user has 'create' privilege on the group,
                      0 otherwise.
} {
    if {$create_p || $join_policy eq "open"} {
        return "approved"
    }

    if {$join_policy eq "needs approval"} {
        return "needs approval"
    }

    if {$no_complain_p} {
        error "group::default_member_state - user is not a group admin and join policy is $join_policy."
    }

    return ""
}


ad_proc -public group::member_p {
    {-user_id ""}
    {-group_name ""}
    {-group_id ""}
    {-subsite_id ""}
    -cascade:boolean
} {
    Return 1 if the user is a member of the group specified.
    You can specify a group name or group id.

    If there is more than one group with this name, it will use the first one.

    If cascade is true, check to see if the user is
    a member of the group by virtue of any other component group.
    (e.g. if group B is a component of group A then if a user
     is a member of group B then he is automatically a member of A
     also.)
    If cascade is false, then the user must have specifically
    been granted membership on the group in question.

    @param subsite_id Only useful when using group_name. Marks the subsite in which to search for the group_id that belongs to the group_name

    @see group::flush_members_cache

} {

    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }

    if { $group_name eq "" && $group_id eq "" } {
        ad_log warning "group::member_p: neither group_name nor group_id was provided; returning 0"
        return 0
    }

    if { $group_name ne "" } {
        set group_id [group::get_id -group_name $group_name -subsite_id $subsite_id]
        if { $group_id eq "" } {
            ad_log warning "group::member_p: could not lookup '$group_name' (for subsite_id '$subsite_id'); returning 0"
            return 0
        }
    }

    return [acs::group_cache eval -partition_key $group_id \
                member-$group_id-$user_id-$cascade_p {
                    group::member_p_not_cached -group_id $group_id -user_id $user_id -cascade_p $cascade_p
                }]
    #return [util_memoize [list group::member_p_not_cached -group_id $group_id -user_id $user_id -cascade_p $cascade_p]]
}

ad_proc -private group::member_p_not_cached {
    -user_id:required
    -group_id:required
    {-cascade_p f}
} {
    Return 1 if the user is a member of the group specified.

    If cascade_p is true, check to see if the user is a member of the
    group by virtue of any other component group. e.g. if group B is
    a component of group A then if a user is a member of group B then
    he is automatically a member of A also.

    If cascade_p is false, then the user must have specifically been
    granted membership on the group in question.

    @return boolean value
    @see group::flush_members_cache

} {

    set cascade [db_boolean $cascade_p]
    set result [db_string user_is_member {} -default "f"]

    return [template::util::is_true $result]
}

ad_proc -public group::party_member_p {
    -party_id
    { -group_id "" }
    { -group_name "" }
    { -subsite_id "" }
} {

    Return 1 if the party is an approved member of the group
    specified.

    One can specify a group_id (preferred) or a group name.
    <strong>Note:</strong> The group name is <strong>not</strong>
    unique by definition, and if you call this function with a
    duplicate group name it <strong>will</strong> return the first one
    (arbitrary)!!! Using the group name as a parameter is thus
    strongly discouraged unless you are really, really sure the name
    is unique.</p>

    <p>The party must have specifically been granted
    membership on the group in question.</p>

} {
    if { $group_name ne "" } {
        if {$group_id ne ""} {
            ad_log warning "group::party_member_p: ignore specified group_id $group_id, using name '$group_name' instead"
        }
        set group_id [group::get_id -group_name $group_name -subsite_id $subsite_id]
    }

    if { $group_id eq "" } {
        set result 0
    } else {
        # Limiting to one row is required for those groups that define
        # relational segments (e.g. subsites, as for admins two rows
        # will be there for both their roles of member and
        # administrator).
        set result [db_0or1row party_is_member {
            select 1 from group_approved_member_map
            where member_id = :party_id
            and group_id = :group_id
            limit 1
        }]
    }
    return $result
}

ad_proc -public group::get_rel_segment {
    {-group_id:required}
    {-type:required}
} {
    Get a segment for a particular relation type for a given group.
} {
    return [db_string select_segment_id {
        select segment_id from rel_segments
        where group_id = :group_id and rel_type = :type
    }]
}

ad_proc -public group::get_rel_types_options {
    {-group_id:required}
    {-object_type "person"}
} {
    Get the valid relationship-types for this group in a format suitable for a select widget in the form builder.
    The label used is the name of the role for object two.

    @param group_id The ID of the group for which to get options.

    @param object_type The object type which must occupy side two of the relationship. Typically 'person' or 'group'.
    @return a list of lists with label (role two pretty name) and ID (rel_type)
} {
    # LARS:
    # The query has a hack to make sure 'membership_rel' appears before all other rel types
    set rel_types [list]
    db_foreach select_rel_types {} {
        # Localize the name
        lappend rel_types [list [lang::util::localize $pretty_name] $rel_type]
    }
    return $rel_types
}

ad_proc -public group::admin_p {
    {-group_id:required}
    {-user_id:required}
} {
    @return 1 if user_id is in the admin_rel for group_id
} {
    set admin_rel_id [relation::get_id \
                          -object_id_one $group_id \
                          -object_id_two $user_id \
                          -rel_type "admin_rel"]

    # The party is an admin if the call above returned something non-empty
    return [expr {$admin_rel_id ne ""}]
}


ad_proc -public group::add_member {
    {-no_perm_check:boolean}
    {-no_automatic_membership_rel:boolean}
    {-group_id:required}
    {-user_id:required}
    {-rel_type ""}
    {-member_state ""}
} {
    Adds a user to a group, checking that the rel_type is permissible given the user's privileges,
    Can default both the rel_type and the member_state to their relevant values.

    @param no_perm_check avoid permission check
    @param no_automatic_membership_rel Use this flag, when we do not want to add automatically a membership_rel (e.g. in DotLRN)
    @param group_id group, to which a member should be added
    @param user_id user, which should be added to a group
    @param rel_type relationship type to be used (defaults to membership_rel)
    @param member_state state, in which member should be added  (gets default via group::default_member_state)

} {
    set admin_p [permission::permission_p -object_id $group_id -privilege "admin"]

    # Only admins can add non-membership_rel members
    if { $rel_type eq ""
         || (!$no_perm_check_p
             && $rel_type ne ""
             && $rel_type ne "membership_rel"
             && ![permission::permission_p -object_id $group_id -privilege "admin"])
     } {
        set rel_type "membership_rel"
    }

    group::get -group_id $group_id -array group

    if { !$no_perm_check_p } {
        set create_p [permission::permission_p -object_id $group_id -privilege "create"]
        if { $group(join_policy) eq "closed" && !$create_p } {
            error "You do not have permission to add members to the group '$group(group_name)'"
        }
    } else {
        set create_p 1
    }

    if { $member_state eq "" } {
        set member_state [group::default_member_state \
                              -join_policy $group(join_policy) \
                              -create_p $create_p]
    }

    if { !$no_automatic_membership_rel_p && $rel_type ne "membership_rel" } {
        # add them with a membership_rel first
        relation_add -member_state $member_state "membership_rel" $group_id $user_id
    }
    relation_add -member_state $member_state $rel_type $group_id $user_id

    #
    # Flush all permission checks pertaining to this user.
    #
    permission::cache_flush -party_id $user_id
    #
    # Flush members cache for the group
    #
    flush_members_cache -group_id $group_id
}


ad_proc -public group::remove_member {
    {-group_id:required}
    {-user_id:required}
} {
    Removes a user from a group. No permission checking.
} {

    # Find all acs_rels between this group and this user, which are membership_rels or descendants thereof (admin_rels, for example)
    set rel_id_list [db_list select_rel_ids {
        select r.rel_id
        from   acs_rels r,
               membership_rels mr
        where  r.rel_id = mr.rel_id
        and    r.object_id_one = :group_id
        and    r.object_id_two = :user_id
    }]

    db_transaction {
        foreach rel_id $rel_id_list {
            relation_remove $rel_id
        }
    }

    flush_members_cache -group_id $group_id
}

ad_proc -public group::title {
    {-group_name ""}
    {-group_id ""}
} {

    Get the title of a group based either on group_name or on the group_id.

    @param group_id The group_id of the group
    @param group_name The name of the group. Note this is not the I18N title we want to retrieve with this procedure
} {
    if {$group_name ne ""} {
        if {$group_id ne ""} {
            error "specify either -group_name or -group_id, but not both"
        }
        set group_id [group::get_id -group_name $group_name]
    }

    if {$group_id ne ""} {
        return [group::get_element -group_id $group_id -element "title"]
    } else {
        return ""
    }
}

ad_proc -private group::group_p {
    {-group_id:required}
} {
    Test, of group exists

    @param group_id The group_id of the group
} {
    return [acs::group_cache eval -partition_key $group_id \
                exists-$group_id- {
                    db_string group {select 1 from groups where group_id = :group_id} -default 0
                }]
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
