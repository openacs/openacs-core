<?xml version="1.0"?>
<queryset>

    <fullquery name="instance_delete_doubleclick_ck">
        <querytext>
            select case when count(*) = 0 then 0 else 1 end
            from apm_packages
            where package_id = :package_id
        </querytext>
    </fullquery>

</queryset>
