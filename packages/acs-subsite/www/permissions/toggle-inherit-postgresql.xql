<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="dbqd.acs-subsite.www.permissions.toggle-inherit.toggle_inherit">
  <querytext>
  update acs_objects
  set security_inherit_p = case when security_inherit_p = 't' then 'f' else 't' end
  where object_id = :object_id
  </querytext>
</fullquery>

</queryset>
