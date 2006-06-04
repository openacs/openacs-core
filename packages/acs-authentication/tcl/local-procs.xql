<?xml version="1.0"?>

<queryset>

    <fullquery name="auth::local::authentication::MergeUser.getrelid">
      <querytext>
	select rel_id from cc_users where user_id = :from_user_id      
      </querytext>
    </fullquery>

</queryset>


