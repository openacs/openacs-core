nsv_set search_static_variables item_counter 0

ad_schedule_proc -thread t [parameter::get_from_package_key -package_key search -parameter SearchIndexerInterval -default 60 ] search::indexer

if {[ns_config "ns/db/drivers" oracle] ne ""} {
    ad_schedule_proc -thread t 14400 db_dml optimize_intermedia_index {Ctx_Ddl.Optimize_Index ('swi_index','FAST', 60)}
}

