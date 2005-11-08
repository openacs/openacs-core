ad_page_contract {
    Reindex NEWS

    @author openacs@dirkgomez.de
} {
} -properties {
}                                                                                                                           
db_dml delete_news_from_index {delete from site_wide_index where object_id in (select object_id from acs_objects where object_type='news')}
db_dml reindex_news {
insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects, cr_items, cr_news where news_id=live_revision and object_id=live_revision and object_type in ('news')}
# and archive_date is null
ad_returnredirect ./index
