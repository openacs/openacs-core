<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="auth::authority::create.create_authority">
        <querytext>
            select authority__new(
                :authority_id,
                null, -- object_type
                :short_name,
                :pretty_name,
                :enabled_p,
                :sort_order,
                :auth_impl_id,
                :pwd_impl_id,
                :forgotten_pwd_url,
                :change_pwd_url,
                :register_impl_id,
                :register_url,
                :help_contact_text,
                :creation_user,
                :creation_ip,
                :context_id
            );                    
        </querytext>
    </fullquery>

    <fullquery name="auth::authority::delete.delete_authority">
        <querytext>
            select authority__del(
                :authority_id
            );
        </querytext>
    </fullquery>

</queryset>
