ad_page_contract {
    erase's a user's portrait (NULLs out columns in the database)

    the key here is to null out live_revision, which is 
    used by pages to determine portrait existence

    @cvs-id $Id$
} {
    {return_url "" }
    {user_id ""}
}

auth::require_login


set current_user_id [ad_conn user_id]

if {$user_id eq ""} {
    set user_id $current_user_id
    set admin_p 0
} else {
    set admin_p 1
}

ad_require_permission $user_id "write"

db_dml portrait_delete "update cr_items
set live_revision = NULL
where item_id = (
   select object_id_two
   from acs_rels
   where object_id_one = :user_id
   and rel_type = 'user_portrait_rel')"

if {$return_url eq ""} {
    set return_url "/pvt/home"
}

ad_returnredirect $return_url
