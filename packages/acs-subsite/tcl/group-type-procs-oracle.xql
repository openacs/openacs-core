<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="drop_all_groups_p.group_exists_p">      
      <querytext>
      
	    select case when exists (select 1 
                                       from acs_objects o
                                      where acs_permission.permission_p(o.object_id, :user_id, 'delete') = 'f'
                                        and o.object_type = :group_type)
                        then 0 else 1 end
              from dual
	
      </querytext>
</fullquery>

 
<partialquery name="group_type::new.drop_type">      
      <querytext>

begin acs_object_type.drop_type('$group_type'); end;
      
      </querytext>
</partialquery>

 
<partialquery name="group_type::new.create_type">      
      <querytext>

BEGIN
 acs_object_type.create_type (
   supertype     => :supertype,
   object_type   => :group_type,
   pretty_name   => :pretty_name,
   pretty_plural => :pretty_plural,
   table_name    => :table_name,
   id_column     => :id_column,
   package_name  => :package_name
 );
END;      

      </querytext>
</partialquery>

 
<partialquery name="group_type::new.update_type">      
      <querytext>

update acs_object_types set dynamic_p='t' where object_type = :group_type

      </querytext>
</partialquery>

 
<partialquery name="group_type::new.copy_rel_types">      
      <querytext>

	insert into group_type_rels 
	(group_rel_type_id, rel_type, group_type)
	select acs_object_id_seq.nextval, r.rel_type, :group_type
	  from group_type_rels r
	 where r.group_type = :supertype

      </querytext>
</partialquery>

 
</queryset>
