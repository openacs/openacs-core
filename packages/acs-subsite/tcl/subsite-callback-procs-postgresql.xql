<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="subsite_callback.select_callbacks">      
      <querytext>

	select distinct callback, callback_type
	  from subsite_callbacks
	 where object_type in (select t2.object_type
	                         from acs_object_types t1, acs_object_types t2
	                        where t2.tree_sortkey <= t1.tree_sortkey
				  and t1.tree_sortkey between t2.tree_sortkey and tree_right(t2.tree_sortkey)
				  and t1.object_type = :object_type)
	   and event_type = :event_type
    
      </querytext>
</fullquery>

 
</queryset>
