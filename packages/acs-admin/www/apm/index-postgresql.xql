<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="apm_table">      
      <querytext>

        select  v.version_id, v.package_key, t.pretty_name, v.version_name, 
		to_char(v.release_date, 'YYYY-MM-DD') as release_date, 
		v.enabled_p, v.installed_p, v.distribution_uri,
            (select count(*) from apm_package_versions v2
             where v2.package_key = v.package_key
             and   v2.installed_p
             and   apm_package_version__sortable_version_name(v2.version_name) >
                   apm_package_version__sortable_version_name(v.version_name)) as  superseded_p,
             case
               when content_item__get_latest_revision(item_id) is null
               then 0
               else 1
             end as tarball_p
        from    apm_package_versions v, apm_package_types t
        where  t.package_key = v.package_key
        $filter_where_clause
        [template::list::orderby_clause -orderby -name package_list]
      </querytext>
</fullquery>

<partialquery name="latest">
   <querytext>
     (installed_p = 't' or enabled_p = 't' or not exists (
        select 1 from apm_package_versions v2
        where v2.package_key = v.package_key
          and (v2.installed_p = 't' or v2.enabled_p = 't')
         and apm_package_version__sortable_version_name(v2.version_name) >
             apm_package_version__sortable_version_name(v.version_name)))
   </querytext>
</partialquery>
 
</queryset>
