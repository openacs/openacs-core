<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="ad_user_new.user_insert">      
      <querytext>
      
	begin
	    :1 := acs.add_user(
                user_id => :user_id,
                object_type => 'user',
                creation_user => :creation_user,
                creation_ip => :peeraddr,
                username => :username,
                email => :email,
                url => :url,
                first_names => :first_names,
                last_name => :last_name,
                password => :password,
                salt => :salt,
                email_verified_p => :email_verified_p,
                member_state => :member_state
            );
	end;
	
      </querytext>
</fullquery>

<fullquery name="acs_user::delete.permanent_delete">
      <querytext>
          begin
              acs_user.delete(
                  user_id => :user_id
              );
          end;
      </querytext>
</fullquery>

<fullquery name="person::delete.delete_person">      
      <querytext>

	    select person.delete(:person_id) from dual;
	
      </querytext>
</fullquery>

 
</queryset>
