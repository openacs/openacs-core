<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql></type><version>7.1</version></rdbms>

    <fullquery name="search_indexer.search_observer_dequeue_entry">
        <querytext>
            declare
            begin
                search_observer.dequeue(
                    object_id => :object_id,
                    date => :date,
                    event => :event
                );
            end;
        </querytext>
    </fullquery>

</queryset>
