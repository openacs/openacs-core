<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rel_id">      
      <querytext>
      select rel_id
from group_member_map
where group_id = acs__magic_object_id('registered_users')
  and member_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      FIX ME PLSQL

begin
  membership_rel__deleted( rel_id => :rel_id );
end;
      </querytext>
</fullquery>

 
</queryset>
