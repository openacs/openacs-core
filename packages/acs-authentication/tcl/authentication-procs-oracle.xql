<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="auth::get_user_secret_token.select_secret_token">
        <querytext>
             select rowid from users where user_id = :user_id
        </querytext>
    </fullquery>

</queryset>
