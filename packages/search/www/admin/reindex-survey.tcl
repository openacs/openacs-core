ad_page_contract {
    Reindex SURVEY

    @author openacs@dirkgomez.de
} {
} -properties {
}                                                                                                                           
db_dml delete_survey_from_index {delete from site_wide_index where object_id in (select object_id from acs_objects where object_type='survey')}
db_dml reindex_survey {
    insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects where object_type in ('survey')}

ad_returnredirect ./index
