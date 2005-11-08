ad_page_contract {
    Reindex PHB_PERSON

    @author openacs@dirkgomez.de
} {
} -properties {
}                                                                                                                           
db_dml delete_phb_person_from_index {delete from site_wide_index where object_id in (select object_id from acs_objects where object_type='phb_person')}
db_dml reindex_phb_person {
insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects,cr_items where object_type in ('phb_person') and object_id=live_revision }

ad_returnredirect ./index
