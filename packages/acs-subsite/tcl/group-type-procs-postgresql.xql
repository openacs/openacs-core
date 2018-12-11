<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="group_type::drop_all_groups_p.group_exists_p">      
      <querytext>
      
	    select case when exists (select 1 
                                       from acs_objects o
                                      where acs_permission__permission_p(o.object_id, :user_id, 'delete') = 'f'
                                        and o.object_type = :group_type)
                        then 0 else 1 end
              
	
      </querytext>
</fullquery>

 
<partialquery name="group_type::new.drop_type">      
      <querytext>

	  select acs_object_type__drop_type('$group_type', 'f');
      
      </querytext>
</partialquery>

 
<partialquery name="group_type::new.create_type">      
      <querytext>

 select acs_object_type__create_type (
   :group_type,
   :pretty_name,
   :pretty_plural,
   :supertype,
   :table_name,
   :id_column,
   :package_name,
   'f',
   null,
   null
 )
      
      </querytext>
</partialquery>

 
<partialquery name="group_type::new.update_type">      
      <querytext>
      
      begin
        update acs_object_types set dynamic_p='t' where object_type = :group_type;
	return null;
      end;

      </querytext>
</partialquery>

 
<partialquery name="group_type::new.copy_rel_types">      
      <querytext>
      
      begin
        insert into group_type_rels 
	       (group_rel_type_id, rel_type, group_type)
	       select nextval('t_acs_object_id_seq'), r.rel_type, :group_type
	         from group_type_rels r
	        where r.group_type = :supertype;
        return null;
      end;

      </querytext>
</partialquery>

<partialquery name="group_type::delete.package_exists">
  <querytext>
    select case when exists (select 1
    from pg_proc
    where proname like :package_name || '%')
    then 1 else 0 end
  </querytext>
</partialquery>

<partialquery name="group_type::delete.package_drop">
  <querytext>
    select drop_package(:group_type)
  </querytext>
</partialquery>

<partialquery name="group_type::delete.drop_type">
  <querytext>
    select acs_object_type__drop_type(:group_type, 'f')
  </querytext>
</partialquery>

<fullquery name="group_type::delete.select_group_ids">
  <querytext>
    select o.object_id
    from acs_objects o
    where o.object_type = :group_type
    and   acs_permission__permission_p(o.object_id, :user_id, 'delete')
  </querytext>
</fullquery>

</queryset>
