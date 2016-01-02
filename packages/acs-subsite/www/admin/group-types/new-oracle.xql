<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="pretty_name_unique">      
<querytext>
	  select case when exists (select 1 from acs_object_types t where t.pretty_name = :pretty_name)
                 then 1 else 0 end
	  from dual
</querytext>
</fullquery>

<fullquery name="select_group_supertypes">      
<querytext>
   select replace(lpad(' ', (level - 1) * 4), ' ', '&nbsp;') || t.pretty_name, t.object_type
   from acs_object_types t
   connect by prior t.object_type = t.supertype
   start with t.object_type = 'group'
</querytext>
</fullquery>

</queryset>
