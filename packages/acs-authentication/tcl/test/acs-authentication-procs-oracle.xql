<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="auth::test::get_admin_user_id.select_user_id">
        <querytext>
            select q.user_id from
            (select user_id
            from users
            where acs_permission.permission_p(:context_root_id, user_id, 'admin') = 't') q where rownum = 1
        </querytext>
    </fullquery>

    <fullquery name="auth::test::get_password_vars.select_vars">
        <querytext>
            select q.* from
            (select u.user_id,
                    aa.authority_id,
                    u.username 
            from users u,
                       auth_authorities aa
            where u.authority_id = aa.authority_id
            and aa.short_name = 'local') q where rownum = 1
        </querytext>
    </fullquery>

</queryset>
