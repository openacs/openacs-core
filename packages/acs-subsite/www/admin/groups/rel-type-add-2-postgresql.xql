<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="types_match_p">      
      <querytext>
      
	    select count(*)
	      from acs_rel_types t
	     where (t.object_type_one = :group_type 
                    or acs_object_type__is_subtype_p(t.object_type_one, :group_type) = 't')
               and t.rel_type = :rel_type
	
      </querytext>
</fullquery>

 
<fullquery name="exists_p">      
      <querytext>
      
	select case when exists (select 1 
                                   from group_rels 
                                  where group_id = :group_id
                                    and rel_type = :rel_type)
                    then 1 else 0 end
	  
    
      </querytext>
</fullquery>

 
<fullquery name="segment_exists_p">      
      <querytext>
      
    select case when exists (select 1 
                               from rel_segments s 
                              where s.group_id = :group_id
                                and s.rel_type = :rel_type)
                then 1 else 0 end
      

      </querytext>
</fullquery>

 
</queryset>
