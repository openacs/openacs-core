<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

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
