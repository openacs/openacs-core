<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rel_type_info">      
      <querytext>

    select object_type as ancestor_rel_type
      from acs_object_types
     where supertype = 'relationship'
       and object_type in (
               select t1.object_type
	         from acs_object_types t1, acs_object_types t2
		where t2.tree_sortkey between t1.tree_sortkey and tree_right(t1.tree_sortkey)
		  and t2.object_type = :add_with_rel_type
	   )

      </querytext>
</fullquery>

 
<fullquery name="user_exists">      
      <querytext>
      
	select case when exists
	                 (select 1 from users where user_id = :user_id)
	       then 1 else 0 end
	
    
      </querytext>
</fullquery>

 
<fullquery name="user_new_2_rowid_for_email">      
      <querytext>
      select oid as rowid from users where user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
