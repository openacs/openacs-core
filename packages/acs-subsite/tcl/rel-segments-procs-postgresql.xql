<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rel_segments_new.create_rel_segment">      
      <querytext>

	select rel_segment__new(
		null,
		'rel_segment',
		now(),
		:creation_user,
		:creation_ip,
		null,
		null,
		:segment_name,
		:group_id,
		:rel_type,
		:context_id
)
    
      </querytext>
</fullquery>

 
<fullquery name="rel_segments_delete.constraint_delete">      
      <querytext>

	    select rel_constraint__delete(:constraint_id)
	
      </querytext>
</fullquery>

 
<fullquery name="rel_segments_delete.rel_segment_delete">      
      <querytext>

	select rel_segment__delete(:segment_id)
    
      </querytext>
</fullquery>

 
</queryset>
