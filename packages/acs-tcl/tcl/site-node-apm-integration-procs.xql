<?xml version="1.0"?>
<queryset>

    <fullquery name="site_node_apm_integration::get_child_package_id.select_child_package_id">
        <querytext>
            select sn1.object_id
            from site_nodes sn1,
                 apm_packages
            where sn1.parent_id = (select sn2.node_id
                                   from site_nodes sn2
                                   where sn2.object_id = :package_id)
            and sn1.object_id = apm_packages.package_id
            and apm_packages.package_key = :package_key
        </querytext>
    </fullquery>

</queryset>
