<?xml version="1.0"?>

<queryset>

    <fullquery name="auth::driver::set_parameter_value.param_exists_p">
        <querytext>
            select count(*) 
            from   auth_driver_params
            where  impl_id = :impl_id
            and    authority_id = :authority_id
            and    key = :parameter
        </querytext>
    </fullquery>

</queryset>
