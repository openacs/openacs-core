<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="user_login_user_id_from_email">      
      <querytext>
          select user_id, 
                 member_state, 
                 email_verified_p, 
                 trunc(date_part('epoch', age(password_changed_date))/(60*60*24)) as password_age_days
          from   cc_users
          where  email = :email      
      </querytext>
</fullquery>

 
</queryset>
