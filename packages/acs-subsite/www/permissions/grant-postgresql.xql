<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="dbqd.acs-subsite.www.permissions.grant.name">
  <querytext>
select acs_object__name(:object_id) from dual
  </querytext>
</fullquery>

<fullquery name="dbqd.acs-subsite.www.permissions.grant.parties">
  <querytext>
  select party_id, acs_object__name(party_id) as name
  from parties
  </querytext>
</fullquery>

</queryset>
