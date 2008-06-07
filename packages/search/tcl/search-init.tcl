nsv_set search_static_variables item_counter 0

ad_schedule_proc -thread t [parameter::get_from_package_key -package_key search -parameter SearchIndexerInterval -default 60 ] search::indexer


