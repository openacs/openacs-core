<?xml version="1.0"?>
<queryset>

<fullquery name="select_pretty_name">      
      <querytext>
      
    select t.pretty_name
      from acs_object_types t
     where t.object_type = :rel_type

      </querytext>
</fullquery>

 
<fullquery name="select_subtypes">      
      <querytext>
      
	select t.object_type as rel_type, t.pretty_name
          from acs_object_types t
         where t.supertype = :rel_type
    
      </querytext>
</fullquery>

 
</queryset>
