<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="auth::get_user_secret_token.select_secret_token">
        <querytext>
             select oid from users where user_id = :user_id
        </querytext>
    </fullquery>

</queryset>
