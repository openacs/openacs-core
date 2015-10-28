<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="drop_relationship_type">      
      <querytext>
      
	    BEGIN
	      acs_rel_type.drop_type( rel_type  => :rel_type,
                                      cascade_p => 't' );
	    END;
	
      </querytext>
</fullquery>

<fullquery name="select_rel_ids">      
      <querytext>
        select r.rel_id
          from acs_rels r, acs_object_party_privilege_map perm
        where perm.object_id = r.rel_id
          and perm.party_id = :user_id
          and perm.privilege = 'delete'
          and r.rel_type = :rel_type    
      </querytext>
</fullquery>


<fullquery name="select_segment_id">      
      <querytext>
	select s.segment_id
	  from rel_segments s, acs_object_party_privilege_map perm
	 where perm.object_id = s.segment_id
 	   and perm.party_id = :user_id
	   and perm.privilege = 'delete'
	   and s.rel_type = :rel_type
      </querytext>
</fullquery>

 
<fullquery name="drop_type_table">      
      <querytext>
      drop table $table_name
      </querytext>
</fullquery>

 
</queryset>
