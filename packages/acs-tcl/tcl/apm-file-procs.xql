<?xml version="1.0"?>
<queryset>

<fullquery name="apm_generate_tarball.item_exists_p">      
      <querytext>

        select case when item_id is null then 0 else item_id end as item_id
          from apm_package_versions 
         where version_id = :version_id

      </querytext>
</fullquery>

<fullquery name="apm_generate_tarball.set_item_id">      
      <querytext>

        update apm_package_versions 
        set item_id = :item_id 
        where version_id = :version_id

      </querytext>
</fullquery>

<fullquery name="apm_db_type_keys.db_type_keys">      
      <querytext>
      select db_type_key from apm_package_db_types
      </querytext>
</fullquery>

 
<fullquery name="apm_generate_tarball.package_key_select">      
      <querytext>
      select package_key from apm_package_version_info where version_id = :version_id
      </querytext>
</fullquery>
 
</queryset>
