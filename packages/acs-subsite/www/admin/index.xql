<?xml version="1.0"?>
<queryset>

<fullquery name="subsite_name">      
      <querytext>
      
    select p.instance_name 
      from apm_packages p
     where p.package_id = :package_id

      </querytext>
</fullquery>

 
</queryset>
