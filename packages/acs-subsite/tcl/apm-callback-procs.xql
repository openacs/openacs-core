<?xml version="1.0"?>
<queryset>

  <fullquery name="subsite::after_upgrade.get_subsite_ids">      
    <querytext>
        select package_id
        from apm_packages
        where package_key in $package_keys
    </querytext>
  </fullquery>

</queryset>
