ad_page_contract {
    List and manage subsite members.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
} {
    {member_state "approved"}
    {orderby "name,asc"}
}

set page_title "Members"
set context [list $page_title]

set group_id [application_group::group_id_from_package_id]

set rel_type "membership_rel"

set user_id [ad_conn user_id]

# We need to know both: 
#    - does user have admin on group?
#    - does user have delete on group?
set admin_p [ad_permission_p -user_id $user_id $group_id "admin"]

set show_member_list_to [parameter::get -parameter "ShowMembersListTo" -default 2]
if { $admin_p || ($user_id != 0 && $show_member_list_to == 1) || \
    $show_member_list_to == 0} {
    set show_members_list_p 1
} else {
    set show_members_list_p 0
    set title "Cannot see the members list"
}

if { $admin_p } {
    # We can skip the permissions check for "delete" because user had admin.
    set delete_p 1
} else {
    # user doesn't have admin -- now find out if they have delete.
    set delete_p [ad_permission_p -user_id $user_id $group_id "delete"]
}

set actions {}
set bulk_actions {}

if { $admin_p } {
    set bulk_actions { 
        "Remove" member-remove "Remove the checked members from this group" 
        "Make administrator" make-admin "Make checked members administrators of this group"
        "Make normal member" make-member "Make checked administrators normal of this group"
    }
}

if { $admin_p || [parameter::get -parameter "MembersCanInviteMembersP" -default 0] } {
    set actions { "Invite" member-invite }
}

# TODO: Pagination

list::create \
    -name "members" \
    -multirow "members" \
    -key rel_id \
    -row_pretty_plural "members" \
    -bulk_actions $bulk_actions \
    -actions $actions \
    -elements {
        name {
            label "Name"
            link_url_eval {[acs_community_member_url -user_id $user_id]}
            orderby "lower(u.first_names || ' ' || u.last_name)"
        }
        email {
            label "Email"
            link_url_eval {mailto:$email}
            link_html { title "Send email to this user" }
            orderby "u.email"
            hide_p {[ad_decode [ad_conn user_id] 0 1 0]}
        }
        rel_role {
            label "Role"
            display_col rel_role_pretty
            orderby "role.pretty_name"
        }
    }


# Pull out all the relations of the specified type

db_multirow members relations_query "
    select r.rel_id, 
           u.user_id,
           u.first_names || ' ' || u.last_name as name,
           u.email,
           r.rel_type,
           rt.role_two as rel_role,
           role.pretty_name as rel_role_pretty
    from   acs_rels r,
           membership_rels mr,
           cc_users u,
           acs_rel_types rt,
           acs_rel_roles role
    where  r.object_id_one = :group_id
    and    mr.rel_id = r.rel_id
    and    mr.member_state = 'approved'
    and    u.user_id = r.object_id_two
    and    rt.rel_type = r.rel_type
    and    role.role = rt.role_two
    [template::list::orderby_clause -orderby -name "members"]
" {
    set rel_role_pretty [lang::util::localize $rel_role_pretty]
}

