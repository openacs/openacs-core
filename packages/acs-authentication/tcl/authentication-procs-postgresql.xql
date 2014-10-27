<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

   <fullquery name="auth::create_local_account_helper.user_insert">   
      <querytext>
            select acs__add_user(
                :user_id,
                'user',
                now(),
                null,
                :peeraddr,
                :authority_id,
                :username,
                :email,
                :url,
                :first_names,
                :last_name,
                :hashed_password,
                :salt,
                :screen_name,
                :email_verified_p,
                :member_state
            );
      </querytext>
   </fullquery>
</queryset>
