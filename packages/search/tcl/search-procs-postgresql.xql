<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="search_indexer.search_observer_dequeue_entry">
        <querytext>
	    select search_observer__dequeue(
	        :object_id,
	        :event_date,
	        :event
	    );
        </querytext>
    </fullquery>

</queryset>
