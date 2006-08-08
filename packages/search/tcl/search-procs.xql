<?xml version="1.0"?>

<queryset>

    <fullquery name="search::queue.insert">
        <querytext>
        insert into search_observer_queue (object_id, event_date, event) values (:object_id, now(), :event)
        </querytext>
    </fullquery>
 
    <fullquery name="search::indexer.search_observer_queue_entry">
        <querytext>
            select object_id, event_date, event
            from search_observer_queue
            order by event_date asc
        </querytext>
    </fullquery>

    <fullquery name="search::content_get.get_file_data">
        <querytext>
	    select :content as content,
                   'file' as storage_type
            from dual
        </querytext>
    </fullquery>

    <fullquery name="search::content_get.get_lob_data">
        <querytext>
            select :content as content,
                   'lob' as storage_type
            from dual
        </querytext>
    </fullquery>

</queryset>
