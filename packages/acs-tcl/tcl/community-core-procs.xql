<?xml version="1.0"?>
<queryset>

<fullquery name="cc_lookup_screen_name_user.user_select">      
      <querytext>
      
	select user_id from cc_users where upper(screen_name) = upper(:screen_name)
    
      </querytext>
</fullquery>

 
<fullquery name="cc_lookup_screen_name_user.user_select">      
      <querytext>
      
	select user_id from cc_users where upper(screen_name) = upper(:screen_name)
    
      </querytext>
</fullquery>

 
<fullquery name="cc_email_from_party.email_from_party">      
      <querytext>
      
	select email from parties where party_id = :party_id
    
      </querytext>
</fullquery>

 
<fullquery name="cc_lookup_name_group.group_select">      
      <querytext>
      
	select group_id from groups where group_name = :name
    
      </querytext>
</fullquery>

<fullquery name="person::get.get_person">      
      <querytext>
      
	select first_names, last_name
          from persons 
         where person_id = :person_id
    
      </querytext>
</fullquery>

<fullquery name="person::update.update_person">      
      <querytext>
      
	update persons
           set first_names = :first_names, 
               last_name = :last_name
         where person_id = :person_id
    
      </querytext>
</fullquery>

<fullquery name="person::name_not_cached.get_person_name">      
      <querytext>
      
          select first_names||' '||last_name as person_name
            from persons
           where person_id = :person_id
          
      </querytext>
</fullquery>

 
</queryset>
