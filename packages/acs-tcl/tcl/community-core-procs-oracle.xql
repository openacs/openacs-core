<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="ad_user_new.user_insert">      
      <querytext>
      
	begin
	    :1 := acs.add_user(
                user_id => :user_id,
		email => :email,
		url => :url,
		first_names => :first_names,
		last_name => :last_name,
		password => :hashed_password,
	        salt => :salt,
	        password_question => :password_question,
	        password_answer => :password_answer,
	        creation_ip => :peeraddr,
	        email_verified_p => :email_verified_p,
	        member_state => :member_state
            );
	end;
	
      </querytext>
</fullquery>

<fullquery name="person::delete.delete_person">      
      <querytext>

	    select person.delete(:person_id);
	
      </querytext>
</fullquery>

 
</queryset>
