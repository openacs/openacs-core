<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="package_types">
        <querytext>

    select pretty_name, package_key
    from   apm_package_types
    where  not (apm_package.singleton_p(package_key) = 1 and
                apm_package.num_instances(package_key) >= 1)
    order  by upper(pretty_name)

        </querytext>
    </fullquery>

</queryset>
