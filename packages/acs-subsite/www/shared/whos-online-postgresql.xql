<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="dbqd.acs-subsite.www.shared.whos-online.grab_users">
  <querytext>
select user_id, first_names, last_name, email
from cc_users
where last_visit > now() - '[ad_parameter LastVisitUpdateInterval "" 600] seconds'::interval
order by upper(last_name), upper(first_names), email
  </querytext>
</fullquery>

</queryset>
