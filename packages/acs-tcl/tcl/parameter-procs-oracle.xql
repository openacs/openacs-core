<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="parameter::set_global_value.set_parameter_value">
        <querytext>
            begin
                apm.set_value(
                    package_key => :package_key,
                    parameter_name => :parameter,
                    attr_value => :value
                );
            end;
        </querytext>
    </fullquery>

    <fullquery name="parameter::set_value.set_parameter_value">
        <querytext>
            begin
                apm.set_value(
                    package_id => :package_id,
                    parameter_name => :parameter,
                    attr_value => :value
                );
            end;
        </querytext>
    </fullquery>

</queryset>
