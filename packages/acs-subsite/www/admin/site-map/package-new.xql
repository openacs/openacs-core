<?xml version="1.0"?>

<queryset>

    <fullquery name="package_new_doubleclick_ck">
        <querytext>
            select case when count(*) = 0 then 0 else 1 end
            from apm_packages
            where package_id = :new_package_id
        </querytext>
    </fullquery>

</queryset>
