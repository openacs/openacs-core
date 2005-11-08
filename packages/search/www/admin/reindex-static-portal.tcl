ad_page_contract {
    Reindex STATIC_PORTAL_CONTENT

    @author openacs@dirkgomez.de
} {
} -properties {
}                                                                                                                           
db_dml delete_static_portal_content_from_index {delete from site_wide_index where object_id in (select object_id from acs_objects where object_type='static_portal_content')}
db_dml reindex_static_portal_content {
    insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects where object_type in ('static_portal_content')}

ad_returnredirect ./index
