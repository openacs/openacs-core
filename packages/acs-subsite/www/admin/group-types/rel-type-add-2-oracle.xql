<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="types_match_p">      
      <querytext>
      
	    select count(*)
	      from acs_rel_types t
	     where (t.object_type_one = :group_type 
                    or acs_object_type.is_subtype_p(t.object_type_one, :group_type) = 't')
               and t.rel_type = :rel_type
	
      </querytext>
</fullquery>

 
</queryset>
