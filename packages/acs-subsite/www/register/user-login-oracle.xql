<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="user_login_user_id_from_email">      
      <querytext>
      
          select user_id, 
                 member_state, 
                 email_verified_p, 
                 trunc(sysdate - password_changed_date) as password_age_days
          from   cc_users
          where  email = :email      

      </querytext>
</fullquery>

 
</queryset>
