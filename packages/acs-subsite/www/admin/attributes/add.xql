<?xml version="1.0"?>
<queryset>

<fullquery name="object_pretty_name">      
      <querytext>
      
    select t.pretty_name 
      from acs_object_types t
     where t.object_type = :object_type

      </querytext>
</fullquery>

 
<fullquery name="select_datatypes">      
      <querytext>
      
    select d.datatype
      from acs_datatypes d
     order by lower(d.datatype)

      </querytext>
</fullquery>

 
</queryset>
