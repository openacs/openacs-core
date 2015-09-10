ad_page_contract {
    List and manage subsite members.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
} {
    {member_state "approved"}
    {orderby:token "name,asc"}
    page:naturalnum,optional
} -validate {
    member_state_valid -requires { member_state } {
        if { $member_state ni [group::possible_member_states] } {
            ad_complain "Invalid member_state"
        }
    }
}

set page_title [_ acs-subsite.Members]
set context [list $page_title]

set group_id [application_group::group_id_from_package_id]

# Is this the main site? In that case, we don't offer to remove users completely,
# only to ban/delete them.
set main_site_p [string equal [site_node::get_url -node_id [ad_conn node_id]] "/"]

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
    set delete_p [permission::permission_p -party_id $user_id -object_id $group_id -privilege "delete"]
}

set actions {}
set bulk_actions {}

if { $admin_p || [parameter::get -parameter "MembersCanInviteMembersP" -default 0] } {
    set actions [_ acs-subsite.Invite]
    lappend actions { member-invite }
}

if { $admin_p } {
    
}

set member_state_options [list]
db_foreach select_member_states {} {
    lappend member_state_options \
        [list \
             [group::get_member_state_pretty -member_state $state] \
             $state \
             [lc_numeric $num_members]]
}

db_1row pretty_roles {}

template::list::create \
    -name "members" \
    -multirow "members" \
    -row_pretty_plural "members" \
    -page_size 50 \
    -page_flush_p t \
    -page_query_name members_pagination \
    -actions $actions \
    -bulk_actions $bulk_actions \
    -elements {
        name {
            label "[_ acs-subsite.Name]"
            link_url_eval {[acs_community_member_url -user_id $user_id]}
        }
        email {
           label "[_ acs-subsite.Email]"
	    display_template {
		@members.user_email;noquote@
	    }
        }
        rel_role {
            label "[_ acs-subsite.Role]"
            display_template {
                @members.rel_role_pretty@
            }
        }
        member_state_pretty {
            label "[_ acs-subsite.Member_State]"
        }
        member_state_change {
            label {Action}
            display_template {
                <if @members.approve_url@ not nil>
                  <a href="@members.approve_url@" class="button">#acs-subsite.Approve#</a>
                </if>
                <if @members.reject_url@ not nil>
                  <a href="@members.reject_url@" class="button">#acs-subsite.Reject#</a>
                </if>
                <if @members.ban_url@ not nil>
                  <a href="@members.ban_url@" class="button">#acs-subsite.Ban#</a>
                </if>
                <if @members.delete_url@ not nil>
                  <a href="@members.delete_url@" class="button">#acs-subsite.Delete#</a>
                </if>
                <if @members.remove_url@ not nil>
                  <a href="@members.remove_url@" class="button">#acs-subsite.Remove#</a>
                </if>
                <if @members.make_admin_url@ not nil>
                  <a href="@members.make_admin_url@" class="button">#acs-subsite.Make_administrator#</a>
                </if>
                <if @members.make_member_url@ not nil>
                  <a href="@members.make_member_url@" class="button">#acs-subsite.Make_member#</a>
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
    }


# Pull out all the relations of the specified type

set show_partial_email_p [expr {$user_id == 0}]

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
    rel_role_pretty
    user_email
} -unclobber members members_select {} {
    if { $member_admin_p > 0 } {
        set rel_role_pretty [lang::util::localize $admin_role_pretty]
    } else {
        if { $other_role_pretty ne "" } {
            set rel_role_pretty [lang::util::localize $other_role_pretty]
        } else {
            set rel_role_pretty [lang::util::localize $member_role_pretty]
        }
    }
    set member_state_pretty [group::get_member_state_pretty -member_state $member_state]
    set user_email [email_image::get_user_email -user_id $user_id]
    if { $admin_p } {
        switch $member_state {
            approved {
                if { $member_admin_p == 0 } {
                    set make_admin_url [export_vars -base make-admin { user_id }]
                } else {
                    set make_member_url [export_vars -base make-member { user_id }]
                }
                if { $main_site_p } {
                    set ban_url [export_vars -base member-state-change { rel_id {member_state banned} }]
                    set delete_url [export_vars -base member-state-change { rel_id {member_state deleted} }]
                } else {
                    set remove_url [export_vars -base member-remove { user_id }]
                }
            }
            "needs approval" {
                set approve_url [export_vars -base member-state-change { rel_id { member_state approved } }]
                if { $main_site_p } {
                    set reject_url [export_vars -base member-state-change { rel_id {member_state rejected} }]
                } else {
                    set remove_url [export_vars -base member-remove { user_id }]
                }
            }
            "rejected" - "deleted" - "banned" {
                set approve_url [export_vars -base member-state-change { rel_id { member_state approved } }]
                if { !$main_site_p } {
                    set remove_url [export_vars -base member-remove { user_id }]
                }
            }
        }
    }

    if { [ad_conn user_id] == 0 } {
        set email [string replace $email \
                       [expr {[string first "@" $email]+3}] end "..."]
    } else {
        set email_url "mailto:$email"
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
