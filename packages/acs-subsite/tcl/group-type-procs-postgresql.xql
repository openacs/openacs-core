<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="drop_all_groups_p.group_exists_p">      
      <querytext>
      
	    select case when exists (select 1 
                                       from acs_objects o
                                      where acs_permission__permission_p(o.object_id, :user_id, 'delete') = 'f'
                                        and o.object_type = :group_type)
                        then 0 else 1 end
              
	
      </querytext>
</fullquery>

 
</queryset>
