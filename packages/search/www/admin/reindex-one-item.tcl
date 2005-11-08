ad_page_contract {
    Reindex one item

    @author openacs@dirkgomez.de
} {
  object_id
} -properties {
}                                                                                                                           
db_dml reindex_forums_message {
    insert into search_observer_queue (object_id, event) values (:object_id, 'UPDATE')}

ad_returnredirect ./index
