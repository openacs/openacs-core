<?xml version="1.0"?>
<queryset>

<fullquery name="unused">      
      <querytext>
      select count(email)
from parties where email = lower(:email)
and party_id <> :user_id
      </querytext>
</fullquery>

 
</queryset>
