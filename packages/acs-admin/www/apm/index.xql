<?xml version="1.0"?>
<queryset>

  <fullquery name="email_by_user_id">
    <querytext>
      select email  
      from parties 
      where party_id = :user_id
    </querytext>
  </fullquery>

  <partialquery name="apm_application">
    <querytext>
      t.package_type = 'apm_application'
    </querytext>
  </partialquery>

  <partialquery name="everyone">
    <querytext>
      exists (select 1 from apm_package_owners o where o.version_id = v.version_id and owner_uri='mailto:$my_email')
    </querytext>
  </partialquery>
  
</queryset>
