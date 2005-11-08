ad_page_contract {
    Reindex CAL_ITEM

    @author openacs@dirkgomez.de
} {
} -properties {
}                                                                                                                           
db_dml delete_cal_item_from_index {delete from site_wide_index where object_id in (select object_id from acs_objects where object_type='cal_item')}
db_dml reindex_cal_item {
    insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects where object_type in ('cal_item')}

ad_returnredirect ./index
