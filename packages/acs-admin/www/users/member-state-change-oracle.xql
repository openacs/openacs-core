<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="get_states">
        <querytext>
            select email_verified_p as email_verified_p_old,
                   member_state as member_state_old,
                   first_names || ' ' || last_name as name,
                   email,
                   rel_id
            from cc_users
            where user_id = :user_id
        </querytext>
    </fullquery>


<fullquery name="approve_email">
      <querytext>
                       begin acs_user.approve_email ( user_id => :user_id ); end;
      </querytext>
</fullquery>


<fullquery name="unapprove_email">
      <querytext>
                       begin acs_user.unapprove_email ( user_id => :user_id ); end;
      </querytext>
</fullquery>


</queryset>
