ad_page_contract {
    List and manage subsite members.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
} {
    {member_state "approved"}
    {orderby "name,asc"}
} -validate {
    member_state_valid -requires { member_state } {
        if { [lsearch [group::possible_member_states] $member_state] == -1 } {
            ad_complain "Invalid member_state"
        }
    }
}

set page_title [_ acs-subsite.Members]
set context [list $page_title]

set group_id [application_group::group_id_from_package_id]

set rel_type "membership_rel"

set user_id [ad_conn user_id]

set show_member_list_to [parameter::get -parameter "ShowMembersListTo" -default 2]
# 0 = anyone
# 1 = members
# 2 = admins

if { $show_member_list_to != 0 || [permission::permission_p -party_id [ad_conn untrusted_user_id] -object_id $group_id -privilege "admin"] } {
    # Refresh login
    auth::require_login
}

# We need to know both: 
#    - does user have admin on group?
#    - does user have delete on group?
set admin_p [permission::permission_p -party_id $user_id -object_id $group_id -privilege "admin"]

set show_member_list_p [expr { $show_member_list_to == 0 || $admin_p || ($show_member_list_to == 1 && [group::member_p -group_id $group_id]) }]

if { !$show_member_list_p } { 
    set title [_ acs-subsite.Cannot_see_memb_list]
}

if { $admin_p } {
    # We can skip the permissions check for "delete" because user had admin.
    set delete_p 1
} else {
    # user doesn't have admin -- now find out if they have delete.
    set delete_p [ad_permission_p -user_id $user_id $group_id "delete"]
}

set actions {}

if { $admin_p || [parameter::get -parameter "MembersCanInviteMembersP" -default 0] } {
    set actions [_ acs-subsite.Invite]
    lappend actions { member-invite }
}

# TODO: Pagination

set member_state_options [list]
db_foreach select_member_states {
    select mr.member_state as state, 
           count(mr.rel_id) as num_members
    from   membership_rels mr,
           acs_rels r
    where  r.rel_id = mr.rel_id
    and    r.object_id_one = :group_id
    group  by mr.member_state
} {
    lappend member_state_options \
        [list \
             [group::get_member_state_pretty -member_state $state] \
             $state \
             $num_members]
}

list::create \
    -name "members" \
    -multirow "members" \
    -key rel_id \
    -row_pretty_plural "members" \
    -actions $actions \
    -elements {
        name {
            label "[_ acs-subsite.Name]"
            link_url_eval {[acs_community_member_url -user_id $user_id]}
        }
        email {
            label "[_ acs-subsite.Email]"
            link_url_col email_url
            link_html { title "[_ acs-subsite.Send_email_to_this_user]" }
        }
        rel_role {
            label "[_ acs-subsite.Role]"
            display_template {
                @members.rel_role_pretty@
                <if @members.make_admin_url@ not nil>
                  (<a href="@members.make_admin_url@">#acs-subsite.Make_administrator#</a>)
                </if>
                <if @members.make_member_url@ not nil>
                  (<a href="@members.make_member_url@">#acs-subsite.Make_member#</a>)
                </if>
            }
        }
        member_state_pretty {
            label "[_ acs-subsite.Member_State]"
            display_template {
                @members.member_state_pretty@
                <if @members.approve_url@ not nil>
                  (<a href="@members.approve_url@">#acs-subsite.Approve#</a>)
                </if>
                <if @members.reject_url@ not nil>
                  (<a href="@members.reject_url@">#acs-subsite.Reject#</a>)
                </if>
                <if @members.ban_url@ not nil>
                  (<a href="@members.ban_url@">#acs-subsite.Ban#</a>)
                </if>
                <if @members.delete_url@ not nil>
                  (<a href="@members.delete_url@">#acs-subsite.Delete#</a>)
                </if>
                <if @members.remove_url@ not nil>
                  (<a href="@members.remove_url@">#acs-subsite.Remove#</a>)
                </if>
            }
        }
    } -filters {
        member_state {
            label "[_ acs-subsite.Member_State]"
            values $member_state_options
            where_clause {
                mr.member_state = :member_state
            }
            has_default_p 1
        }
    } -orderby {
        name {
            label "[_ acs-subsite.Name]"
            orderby "lower(u.first_names || ' ' || u.last_name)"
        }
        email {
            label "[_ acs-subsite.Email]"
            orderby "u.email"
        }
        rel_role {
            label "[_ acs-subsite.Role]"
            orderby "role.pretty_name"
        }
    }


# Pull out all the relations of the specified type

set show_partial_email_p [expr $user_id == 0]

db_multirow -extend { 
    email_url
    member_state_pretty
    remove_url
    approve_url
    reject_url
    ban_url
    delete_url
    make_admin_url
    make_member_url
} -unclobber members relations_query "
    select r.rel_id, 
           u.user_id,
           u.first_names || ' ' || u.last_name as name,
           u.email,
           r.rel_type,
           rt.role_two as rel_role,
           role.pretty_name as rel_role_pretty,
           mr.member_state
    from   acs_rels r,
           membership_rels mr,
           cc_users u,
           acs_rel_types rt,
           acs_rel_roles role
    where  r.object_id_one = :group_id
    and    mr.rel_id = r.rel_id
    and    u.user_id = r.object_id_two
    and    rt.rel_type = r.rel_type
    and    role.role = rt.role_two
    [template::list::filter_where_clauses -and -name "members"]
    [template::list::orderby_clause -orderby -name "members"]
" {
    set rel_role_pretty [lang::util::localize $rel_role_pretty]
    set member_state_pretty [group::get_member_state_pretty -member_state $member_state]

    if { $admin_p } {
        switch $member_state {
            approved {
                switch $rel_role {
                    member {
                        set make_admin_url [export_vars -base make-admin { rel_id }]
                    }
                    admin {
                        set make_member_url [export_vars -base make-member { rel_id }]
                    }
                }
                set remove_url [export_vars -base member-remove { rel_id }]
            }
            "needs approval" {
                set approve_url [export_vars -base member-state-change { rel_id { member_state approved } }]
                set remove_url [export_vars -base member-remove { rel_id }]
            }
            "rejected" - "deleted" - "banned" {
                set approve_url [export_vars -base member-state-change { rel_id { member_state approved } }]
                set remove_url [export_vars -base member-remove { rel_id }]
            }
        }
    }

    if { [ad_conn user_id] == 0 } {
        set email [string replace $email \
                       [expr [string first "@" $email]+3] end "..."]
    } else {
        set email_url "mailto:$email"
    }
}

