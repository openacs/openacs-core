<?xml version="1.0"?>
<queryset>

<fullquery name="subsite_callback.select_object_type">      
      <querytext>
      
	    select object_type
	      from acs_objects 
	     where object_id = :object_id
	
      </querytext>
</fullquery>

 
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
