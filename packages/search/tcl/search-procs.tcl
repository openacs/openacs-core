ad_proc search_indexer {} {
    @author Neophytos Demetriou
} {

    set driver [ad_parameter -package_id [apm_package_id_from_key search] FtsEngineDriver]

    db_foreach search_observer_queue_entry {
	select object_id, date, event
	from search_observer_queue
	order by date asc
    } {

	switch $event {
	    INSERT {
		set object_type [db_exec_plsql get_object_type "select acs_object_util__get_object_type($object_id)"]
		if [acs_sc_binding_exists_p FtsContentProvider $object_type] {
		    array set datasource [acs_sc_call FtsContentProvider datasource [list $object_id] $object_type]
		    search_content_get txt $datasource(content) $datasource(mime) $datasource(storage_type)
		    acs_sc_call FtsEngineDriver index [list $datasource(object_id) $txt $datasource(title) $datasource(keywords)] $driver
		}
		# Remember seeing this object so we can avoid reindexing it later
		set seen($object_id) 1
	    } 
	    DELETE {
		acs_sc_call FtsEngineDriver unindex [list $object_id] $driver
	    } 
	    UPDATE {
		# Don't bother reindexing if we've already inserted/updated this object in this run
		if { ![info exists seen($object_id)] } {
		    set object_type [db_exec_plsql get_object_type "select acs_object_util__get_object_type($object_id)"]
		    if [acs_sc_binding_exists_p FtsContentProvider $object_type] {
			array set datasource [acs_sc_call FtsContentProvider datasource [list $object_id] $object_type] 
			search_content_get txt $datasource(content) $datasource(mime) $datasource(storage_type)
			acs_sc_call FtsEngineDriver update_index [list $datasource(object_id) $txt $datasource(title) $datasource(keywords)] $driver
		    }
		    # Remember seeing this object so we can avoid reindexing it later
		    set seen($object_id) 1
		}
	    }
	}

	db_exec_plsql search_observer_dequeue_entry {
	    select search_observer__dequeue(
	        :object_id,
	        :date,
	        :event
	    );
	}
    }
}


ad_proc search_content_get {
    _txt
    content
    mime
    storage_type
} {
    @author Neophytos Demetriou

    @param content 
    holds the filename if storage_type=file
    holds the text data if storage_type=text
    holds the lob_id if storage_type=lob
} {
    upvar $_txt txt

    set txt ""

    switch $storage_type {
	text {
	    set data $content
	}
	file {
	    set data [db_blob_get data "select '$content' as content, 'file' as storage_type"]
	}
	lob {
            db_transaction {
	        set data [db_blob_get data "select $content as content, 'lob' as storage_type"]
            }
	}
    }

    search_content_filter txt data $mime

}



ad_proc search_content_filter {
    _txt
    _data
    mime
} {
    @author Neophytos Demetriou
} {
    upvar $_txt txt
    upvar $_data data

    switch $mime {
	{text/plain} {
	    set txt $data 
	}
	{text/html} {
	    set txt $data
	}
    }
}





ad_proc search_choice_bar { items links values {default ""} } {
    @author Neophytos Demetriou
} {

    set count 0
    set return_list [list]

    foreach value $values {
        if { [string compare $default $value] == 0 } {
                lappend return_list "<font color=a90a08><strong>[lindex $items $count]</strong></font>"
        } else {
                lappend return_list "<a href=\"[lindex $links $count]\"><font color=000000>[lindex $items $count]</font></a>"
        }

        incr count
    }

    if { [llength $return_list] > 0 } {
        return "[join $return_list " "]"
    } else {
        return ""
    }
    
}




