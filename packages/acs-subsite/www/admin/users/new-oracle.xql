<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="rel_type_info">      
      <querytext>
      
    select object_type as ancestor_rel_type
      from acs_object_types
     where supertype = 'relationship'
       and object_type in (
               select object_type from acs_object_types
               start with object_type = :add_with_rel_type
               connect by object_type = prior supertype
           )

      </querytext>
</fullquery>

 
<fullquery name="user_exists">      
      <querytext>
      
	select case when exists
	                 (select 1 from users where user_id = :user_id)
	       then 1 else 0 end
	from dual
    
      </querytext>
</fullquery>

 
<fullquery name="user_new_2_rowid_for_email">      
      <querytext>
      select rowid from users where user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
