<?xml version="1.0"?>
<queryset>

<fullquery name="user_info">      
      <querytext>
      
                        select first_names, last_name, email
                        from users
                        where user_id = $conn(user_id)
		    
      </querytext>
</fullquery>

 
</queryset>
