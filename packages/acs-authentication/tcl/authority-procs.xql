<?xml version="1.0"?>

<queryset>

    <fullquery name="auth::authority::get_authority_options.select_authorities">
        <querytext>
             select pretty_name,
                    authority_id
             from   auth_authorities
             where  enabled_p = 't'
        </querytext>
    </fullquery>

</queryset>
