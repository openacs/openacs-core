<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="auth::driver::set_parameter_value.set_parameter">
        <querytext>            
            update auth_driver_params
            set    value = :value
            where  key = :parameter
            and    impl_id = :impl_id
            and    authority_id = :authority_id
        </querytext>
    </fullquery>

</queryset>
