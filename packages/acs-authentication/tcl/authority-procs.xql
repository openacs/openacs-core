<?xml version="1.0"?>

<queryset>

    <fullquery name="auth::authority::get_authority_options.select_authorities">
        <querytext>
            select pretty_name, authority_id
            from   auth_authorities
            where  enabled_p = 't'
            and    auth_impl_id is not null
            order  by sort_order
        </querytext>
    </fullquery>

</queryset>
