<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="auth::driver::set_parameter_value.update_parameter">
        <querytext>            
            update auth_driver_params
            set    value = empty_clob()
            where  authority_id = :authority_id
            and    impl_id = :impl_id
            and    key = :parameter
            returning value into :1
        </querytext>
    </fullquery>

    <fullquery name="auth::driver::set_parameter_value.insert_parameter">
        <querytext>            
            insert into auth_driver_params (authority_id, impl_id, key, value)
            values (:authority_id, :impl_id, :parameter, empty_clob())
            returning value into :1
        </querytext>
    </fullquery>

</queryset>
