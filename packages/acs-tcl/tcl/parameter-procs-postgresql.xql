<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="parameter::set_global_value.set_parameter_value">
        <querytext>
            select apm__set_value(
                :package_key::varchar,
                :parameter,
                :value
            );
        </querytext>
    </fullquery>

    <fullquery name="parameter::set_value.set_parameter_value">
        <querytext>
            select apm__set_value(
                :package_id::integer,
                :parameter,
                :value
            );
        </querytext>
    </fullquery>

</queryset>
