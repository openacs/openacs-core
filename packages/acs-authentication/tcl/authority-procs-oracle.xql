<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="auth::authority::create.create_authority">
        <querytext>
            begin
            :1 := authority.new(
                authority_id => :authority_id,
                short_name => :short_name,
                pretty_name => :pretty_name,
                enabled_p => :enabled_p,
                sort_order => :sort_order,
                auth_impl_id => :auth_impl_id,
                pwd_impl_id => :pwd_impl_id,
                forgotten_pwd_url => :forgotten_pwd_url,
                change_pwd_url => :change_pwd_url,
                register_impl_id => :register_impl_id,
                register_url => :register_url,
                help_contact_text => :help_contact_text,
                creation_user => :creation_user,
                creation_ip => :creation_ip,
                context_id => :context_id
            );   
            end;                 
        </querytext>
    </fullquery>

    <fullquery name="auth::authority::delete.delete_authority">
        <querytext>
            begin
                :1 := authority.del(
                    delete_authority_id => :authority_id
                );
            end;
        </querytext>
    </fullquery>

</queryset>
