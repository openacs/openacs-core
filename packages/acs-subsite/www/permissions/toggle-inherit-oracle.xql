<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="toggle_inherit">      
      <querytext>

  update acs_objects
  set security_inherit_p = decode(security_inherit_p, 't', 'f', 'f', 't')
  where object_id = :object_id

      </querytext>
</fullquery>

 
</queryset>
