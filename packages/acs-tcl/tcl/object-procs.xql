<?xml version="1.0"?>
<queryset>

<fullquery name="acs_lookup_magic_object.magic_object_select">      
      <querytext>
      
	select object_id from acs_magic_objects where name = :name
    
      </querytext>
</fullquery>

 
<fullquery name="acs_object_type.object_type_select">      
      <querytext>
      
        select object_type
        from acs_objects
        where object_id = :object_id
    
      </querytext>
</fullquery>

 
</queryset>
