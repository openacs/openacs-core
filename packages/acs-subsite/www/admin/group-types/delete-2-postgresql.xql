<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="package_exists">      
      <querytext>
      
    select case when exists (select 1 
                               from pg_proc
                              where proname like :package_name || '%')
           then 1 else 0 end
      

      </querytext>
</fullquery>

 
<fullquery name="type_exists">      
      <querytext>
      
    select case when exists (select 1 from acs_object_types t where t.object_type = :group_type)
                then 1
                else 0
           end
      

      </querytext>
</fullquery>

 
<partialquery name="package_drop">
  <querytext>
    select drop_package('[DoubleApos $group_type]')
  </querytext>
</partialquery>

 
<partialquery name="delete_rel_types">
  <querytext>
begin
  delete from group_type_rels where group_type = :group_type;
  return 1;
end;
  </querytext>
</partialquery>

 
<partialquery name="drop_type">
  <querytext>
select acs_object_type__drop_type(:group_type, 'f')
  </querytext>
</partialquery>

 
<partialquery name="drop_table">
  <querytext>
begin
  drop table $table_name;
  return 1;
end;
  </querytext>
</partialquery>

 
<partialquery name="delete_group_type">
<querytext>
begin
delete from group_types where group_type=:group_type;
return 1;
end;
</querytext>
</partialquery> 

</queryset>
