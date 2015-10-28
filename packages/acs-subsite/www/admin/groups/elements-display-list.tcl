# /packages/acs-subsite/www/admin/groups/elements-display.tcl

if { ![info exists group_id] || $group_id eq "" } {
    error "Group must be specified"
}

if { ![info exists rel_type] || $rel_type eq "" } {
    error "Rel type must be specified"
}

if { ![info exists return_url_enc] || $return_url_enc eq "" } {
    # Default return url to the current page
    set return_url_enc [ad_urlencode "[ad_conn url]?[ad_conn query]"]
}

if {![info exists member_state]} {
    set member_state "approved"
}

set user_id [ad_conn user_id]

# We need to know both: 
#    - does user have admin on group?
#    - does user have delete on group?
set admin_p [permission::permission_p -party_id $user_id -object_id $group_id -privilege "admin"]
if {$admin_p} {
    # We can skip the permissions check for "delete" because user had admin.
    set delete_p 1
} else {
    # user doesn't have admin -- now find out if they have delete.
    set delete_p [permission::permission_p -party_id $user_id -object_id $group_id -privilege "delete"]
}

# Pull out all the relations of the specified type

db_1row rel_type_info {}

set extra_tables ""
set extra_where_clauses ""
if {$ancestor_rel_type eq "membership_rel"} {
    if {$member_state ne ""} {
	set extra_tables "membership_rels mr,"
	set extra_where_clauses "
        and mr.rel_id = rels.rel_id
        and mr.member_state = :member_state"
    }
}

db_multirow rels relations_query "
select r.rel_id, 
       party_names.party_name as element_name
from (select /*+ ORDERED */ DISTINCT rels.rel_id, object_id_two
      from $extra_tables acs_rels rels, all_object_party_privilege_map perm
      where perm.object_id = rels.rel_id
        and perm.party_id = :user_id
        and perm.privilege = 'read'
        and rels.rel_type = :rel_type
        and rels.object_id_one = :group_id $extra_where_clauses) r, 
     party_names 
where r.object_id_two = party_names.party_id
order by lower(element_name)
"

# Build the member state dimensional slider

set base_url [export_vars -base [ad_conn package_url]admin/groups/elements-display {group_id rel_type}]

template::multirow create possible_member_states \
	val label url

template::multirow append possible_member_states \
	"" "all" $base_url
foreach state [group::possible_member_states] {
    template::multirow append possible_member_states \
	    $state $state $base_url&member_state=[ad_urlencode $state]
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
