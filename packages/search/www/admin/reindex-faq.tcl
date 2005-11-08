ad_page_contract {
    Reindex FAQ

    @author openacs@dirkgomez.de
} {
} -properties {
}                                                                                                                           
db_dml delete_faq_from_index {delete from site_wide_index where object_id in (select object_id from acs_objects where object_type='faq')}
db_dml reindex_faq {
    insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects where object_type in ('faq')}

ad_returnredirect ./index
