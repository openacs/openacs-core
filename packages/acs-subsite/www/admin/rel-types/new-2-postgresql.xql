<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_object_types">      
      <querytext>

    select lpad('&nbsp;', (level - 1) * 4) || t.pretty_name, 
           t.object_type as rel_type
      from acs_object_types t
     where tree_sortkey like (select tree_sortkey || '%' from acs_object_types
				where object_type= :max_object_type_one)

      </querytext>
</fullquery>

 
<fullquery name="select_object_types">      
      <querytext>

    select lpad('&nbsp;', (level - 1) * 4) || t.pretty_name, 
           t.object_type as rel_type
      from acs_object_types t
     where tree_sortkey like (select tree_sortkey || '%' from acs_object_types
				where object_type = :max_object_type_one)

      </querytext>
</fullquery>

 
<fullquery name="pretty_name_unique">      
      <querytext>
      
	    select case when exists (select 1 from acs_object_types t where t.pretty_name = :pretty_name)
                    then 1 else 0 end
	      
	
      </querytext>
</fullquery>

 
<fullquery name="pretty_name_unique">      
      <querytext>
      
	    select case when exists (select 1 from acs_object_types t where t.pretty_name = :pretty_name)
                    then 1 else 0 end
	      
	
      </querytext>
</fullquery>

 
</queryset>
