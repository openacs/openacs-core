<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="auth::test::get_admin_user_id.select_user_id">
        <querytext>
            select user_id
            from users
            where acs_permission__permission_p(:context_root_id, user_id, 'admin') = 't'
            limit 1  
        </querytext>
    </fullquery>


    <fullquery name="auth::test::get_password_vars.select_vars">
        <querytext>
            select u.user_id,
                   aa.authority_id,
                   u.username 
            from users u,
                       auth_authorities aa
            where u.authority_id = aa.authority_id
            and aa.short_name = 'local'
            limit 1
        </querytext>
    </fullquery>
    
</queryset>
