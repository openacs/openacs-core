ad_page_contract {
    Search admin index page

    @author openacs@dirkgomez.de
} -properties {
}                                                                                                                           
set context [list "Search Admin Page"]

db_multirow object_type_count object_type_count {
  select object_type, 
    count(swi.object_id) as count_object_type 
  from acs_objects ao, site_wide_index swi 
  where swi.object_id=ao.object_id 
  group by object_type
  order by object_type}

db_1row get_cal_item {select count(*) as count_cal_item from acs_objects where object_type in ('cal_item') }
   
db_1row get_file_storage_object {select count(*) as count_file_storage_object from acs_objects, cr_items where object_id=live_revision and object_type in ('file_storage_object') }

db_1row get_static_portal_content {select count(*) as count_static_portal_content from acs_objects where object_type in ('static_portal_content')}

db_1row get_forums_message {select count(*) as count_forums_message from acs_objects where object_type in ('forums_message') }

db_1row get_forums_forums {select count(*) as count_forums_forum from acs_objects where object_type in ('forums_forum') }

db_1row get_news {select count(*) as count_news from acs_objects, cr_items, cr_news where news_id=live_revision and object_id=live_revision and object_type in ('news')}

db_1row get_faq {select count(*) as count_faq from acs_objects where object_type in ('faq') }

db_1row get_survey {select count(*) as count_survey from acs_objects where object_type in ('survey')}

db_1row get_phb_person {select count(*) as count_phb_person from acs_objects,cr_items where object_type in ('phb_person') and object_id=live_revision }

db_1row get_search_observer_queue_count {
    select count(*) as search_observer_queue_count
      from search_observer_queue
}