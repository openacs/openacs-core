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

 
</queryset>
