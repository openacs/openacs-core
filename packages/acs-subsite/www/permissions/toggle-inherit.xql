<?xml version="1.0"?>
<queryset>

<fullquery name="toggle_inherit">      
      <querytext>

  update acs_objects
  set security_inherit_p = not security_inherit_p
  where object_id = :object_id

      </querytext>
</fullquery>

 
</queryset>
