<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="package_exists">      
      <querytext>
      
    select case when exists (select 1 
                               from user_objects o
                              where o.object_type='PACKAGE' 
                                and o.object_name = upper(:package_name))
           then 1 else 0 end
      from dual

      </querytext>
</fullquery>

 
<fullquery name="type_exists">      
      <querytext>
      
    select case when exists (select 1 from acs_object_types t where t.object_type = :group_type)
                then 1
                else 0
           end
      from dual

      </querytext>
</fullquery>

<partialquery name="package_drop">
  <querytext>
    drop package [DoubleApos $group_type]
  </querytext>
</partialquery>

 
<partialquery name="delete_rel_types">
  <querytext>
delete from group_type_rels where group_type = :group_type
  </querytext>
</partialquery>

 
<partialquery name="drop_type">
  <querytext>
begin acs_object_type.drop_type(:group_type); end;
  </querytext>
</partialquery>

 
<partialquery name="drop_table">
  <querytext>
drop table $table_name
  </querytext>
</partialquery>

<partialquery name="delete_group_type">
<querytext>
begin
delete from group_types where group_type=:group_type;
end;
</querytext>
</partialquery> 

</queryset>
