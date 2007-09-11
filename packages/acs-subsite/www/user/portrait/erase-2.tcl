ad_page_contract {
    erase's a user's portrait (NULLs out columns in the database)

    the key here is to null out live_revision, which is 
    used by pages to determine portrait existence

    @cvs-id $Id$
} {
    {return_url "/pvt/home" }
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

set item_id [db_string item_id "select object_id_two
   from acs_rels
   where object_id_one = :user_id
   and rel_type = 'user_portrait_rel'" -default ""]

if {$item_id eq ""} {
    ad_returnredirect $return_url
    ad_script_abort
}

set resized_item_id [image::get_resized_item_id -item_id $item_id]

# Delete the resized version
if {$resized_item_id ne ""} {
    content::item::delete -item_id $resized_item_id
}

# Delete all previous images
db_foreach image "select object_id from acs_objects where object_type in ('cr_item_child_rel','image') and context_id = :item_id and object_id not in (select live_revision from cr_items where item_id = :item_id)" {
    package_exec_plsql -var_list [list [list delete__object_id $object_id]] acs_object delete
}

db_foreach old_item_id "select object_id from acs_objects where object_type = 'content_item' and context_id = :item_id" {
    content::item::delete -item_id $object_id
}

# Delete the relationship
db_dml delete_rel "delete from acs_rels where object_id_two = :item_id and object_id_one = :user_id and rel_type = 'user_portrait_rel'"

# Delete the item
content::item::delete -item_id $item_id

# Flush the portrait cache
util_memoize_flush [list acs_user::get_portrait_id_not_cached -user_id $user_id]

ad_returnredirect $return_url
