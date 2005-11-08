ad_page_contract {
    index items of an object type which are not yet indexed

    @author openacs@dirkgomez.de
} {
  object_type
} -properties {
}

if {[string equal $object_type "file_storage_object"]} {
    db_dml reindex_file_storage_object {
      insert into search_observer_queue (object_id, event) 
        select object_id, 'INSERT' from acs_objects, cr_items 
        where object_id=live_revision and 
        object_type in ('file_storage_object') and 
        object_id 
          not in (select object_id from site_wide_index)}
}

ad_returnredirect ./index
