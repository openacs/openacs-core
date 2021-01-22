<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="rel_id">      
      <querytext>
      select rel_id
from group_member_map
where group_id = acs.magic_object_id('registered_users')
  and member_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      
begin
  membership_rel.del( rel_id => :rel_id );
end;
      </querytext>
</fullquery>

 
</queryset>
