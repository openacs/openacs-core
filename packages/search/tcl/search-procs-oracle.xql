<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="search::indexer.search_observer_queue_entry">
        <querytext>
            select object_id, event_date, event
            from search_observer_queue
	    where rownum < 100
            order by event_date asc
        </querytext>
    </fullquery>

</queryset>

