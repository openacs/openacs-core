<?xml version="1.0"?>
<queryset>

<fullquery name="ds_user_select_widget.users">      
      <querytext>
       
	select u.user_id as user_id_from_db, 
	       acs_object.name(user_id) as name, 
	       p.email 
	from   users u, 
	       parties p 
	where  u.user_id = p.party_id 
	order by name    
      </querytext>
</fullquery>

 
</queryset>
