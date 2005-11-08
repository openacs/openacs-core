ad_page_contract {
    Reindex FORUMS_FORUM

    @author openacs@dirkgomez.de
} {
} -properties {
}                                                                                                                           
db_dml delete_forums_forum_from_index {delete from site_wide_index where object_id in (select object_id from acs_objects where object_type='forums_forum')}
db_dml reindex_forums_forum {
    insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects where object_type in ('forums_forum')}

ad_returnredirect ./index
