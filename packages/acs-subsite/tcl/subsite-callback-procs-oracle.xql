<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="subsite_callback.select_callbacks">      
      <querytext>
      
	select distinct callback, callback_type
	  from subsite_callbacks
	 where object_type in (select t.object_type
	                        from acs_object_types t
	                     connect by prior t.supertype = t.object_type
	                       start with t.object_type = :object_type)
	   and event_type = :event_type
    
      </querytext>
</fullquery>

 
</queryset>
