<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="auth::driver::set_parameter_value.set_parameter">
        <querytext>            
            update auth_driver_params
            set    value = empty_clob()
            where  key = :parameter
            and    impl_id = :impl_id
            and    authority_id = :authority_id
            returning value into :1
        </querytext>
    </fullquery>

</queryset>
