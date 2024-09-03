<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

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

</queryset>
