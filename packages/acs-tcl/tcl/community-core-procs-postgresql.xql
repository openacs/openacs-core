<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="ad_user_new.user_insert">      
      <querytext>

	    select acs__add_user(
                         :user_id,
                         'user',
                         now(),
                         null,
	                 :peeraddr,
			 :email,
			 :url,
			 :first_names,
			 :last_name,
			 :hashed_password,
	                 :salt,
	                 :password_question,
	                 :password_answer,
                         null,
	                 :email_verified_p,
	                 :member_state);
	
      </querytext>
</fullquery>

    <fullquery name="acs_user::change_state.member_approve">
        <querytext>
            select membership_rel__approve(:rel_id)
        </querytext>
    </fullquery>

    <fullquery name="acs_user::change_state.member_ban">
        <querytext>
            select membership_rel__ban(:rel_id)
        </querytext>
    </fullquery>

    <fullquery name="acs_user::change_state.member_reject">
        <querytext>
            select membership_rel__reject(:rel_id)
        </querytext>
    </fullquery>

    <fullquery name="acs_user::change_state.member_delete">
        <querytext>
            select membership_rel__delete(:rel_id)
        </querytext>
    </fullquery>

    <fullquery name="acs_user::change_state.member_unapprove">
        <querytext>
            select membership_rel__unapprove(:rel_id)
        </querytext>
    </fullquery>
 
</queryset>
