<?xml version="1.0"?>
<queryset>

<fullquery name="subsite_info">      
      <querytext>
      
    select ag.group_id as subsite_group_id, ap.instance_name
    from application_groups ag, apm_packages ap
    where ag.package_id = ap.package_id
      and ag.package_id = :package_id

      </querytext>
</fullquery>

 
</queryset>
