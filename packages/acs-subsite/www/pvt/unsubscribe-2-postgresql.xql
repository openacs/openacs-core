<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="dbqd.acs-subsite.www.pvt.unsubscribe-2.rel_id">
  <querytext>
select rel_id
from group_member_map
where group_id = acs__magic_object_id('registered_users')
  and member_id = :user_id
  </querytext>
</fullquery>

<fullquery name="dbqd.acs-subsite.www.pvt.unsubscribe-2.unused">
  <querytext>
  select membership_rel__deleted(:rel_id);
  </querytext>
</fullquery>

</queryset>
