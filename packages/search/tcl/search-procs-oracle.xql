<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="search_indexer.search_observer_dequeue_entry">
        <querytext>
            declare
            begin
                search_observer.dequeue(
                    object_id => :object_id,
                    event_date => :date,
                    event => :event
                );
            end;
        </querytext>
    </fullquery>

</queryset>
