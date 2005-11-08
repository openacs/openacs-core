ad_page_contract {
    Reindex FILE_STORAGE_OBJECT

    @author openacs@dirkgomez.de
} {
} -properties {
}                                                                                                                           
db_dml delete_file_storage_object_from_index {delete from site_wide_index where object_id in (select object_id from acs_objects where object_type='file_storage_object')}
db_dml reindex_file_storage_object {
insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects, cr_items where object_id=live_revision and object_type in ('file_storage_object') }

ad_returnredirect ./index
