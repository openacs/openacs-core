<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="auth::driver::set_parameter_value.update_parameter">
        <querytext>            
            update auth_driver_params
            set    value = :value
            where  authority_id = :authority_id
            and    impl_id = :impl_id
            and    key = :parameter
        </querytext>
    </fullquery>

    <fullquery name="auth::driver::set_parameter_value.insert_parameter">
        <querytext>            
            insert into auth_driver_params (authority_id, impl_id, key, value)
            values (:authority_id, :impl_id, :parameter, :value)
        </querytext>
    </fullquery>

</queryset>
