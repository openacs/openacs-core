<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

   <fullquery name="auth::create_local_account_helper.user_insert">   
      <querytext>
      
	begin
	    :1 := acs.add_user(
                user_id => :user_id,
		email => :email,
		url => :url,
                authority_id => :authority_id,
		username => :username,
		first_names => :first_names,
		last_name => :last_name,
		screen_name => :screen_name,
		password => :hashed_password,
	        salt => :salt,
                creation_user => :creation_user,
	        creation_ip => :peeraddr,
	        email_verified_p => :email_verified_p,
	        member_state => :member_state
            );
	end;
	
      </querytext>
    </fullquery>
</queryset>
