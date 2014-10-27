<?xml version="1.0"?>
<queryset>

<fullquery name="cc_lookup_screen_name_user.user_select">      
      <querytext>
      
	select user_id from acs_users_all where lower(screen_name) = lower(:screen_name)
    
      </querytext>
</fullquery>

<fullquery name="cc_lookup_email_user.user_select">      
      <querytext>
      
	select user_id from acs_users_all where lower(email) = lower(:email)
    
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

<fullquery name="person::update.update_object_title">      
      <querytext>
      
	update acs_objects
	set title = :first_names || ' ' || :last_name
	where object_id = :person_id
    
      </querytext>
</fullquery>

<fullquery name="person::name_not_cached.get_person_name">      
      <querytext>
      
          select distinct first_names||' '||last_name as person_name
            from persons
           where person_id = :person_id
          
      </querytext>
</fullquery>

<fullquery name="person::name_not_cached.get_party_name">      
      <querytext>
      
          select distinct first_names||' '||last_name as person_name
            from persons, parties
           where person_id = party_id 
             and email = :email
             
          
      </querytext>
</fullquery>

<fullquery name="person::get_bio.select_bio">      
      <querytext>
          select bio
          from persons
          where person_id = :person_id
      </querytext>
</fullquery>

<fullquery name="person::update_bio.update_bio">      
      <querytext>
        update persons
	set bio = :bio
	where person_id = :person_id
      </querytext>
</fullquery>

 
<fullquery name="acs_user::update.user_update">      
      <querytext>
      
	update users
        set    [join $cols ", "]
        where  user_id = :user_id
    
      </querytext>
</fullquery>

<fullquery name="acs_user::get_by_username_not_cached.user_id_from_username">      
      <querytext>

            select user_id
            from   users
            where  lower(username) = lower(:username)
            and    authority_id =:authority_id

      </querytext>
</fullquery>

<fullquery name="acs_user::registered_user_p.registered_user_p">
      <querytext>

            select 1
            from   registered_users
            where  user_id = :user_id

      </querytext>
</fullquery>

<fullquery name="party::update.party_update">      
      <querytext>
      
	update parties
        set    [join $cols ", "]
        where  party_id = :party_id

      </querytext>
</fullquery>

<fullquery name="party::update.object_title_update">      
      <querytext>
      
	    update acs_objects
	    set title = :email
	    where object_id = :party_id
	    and object_type = 'party'

      </querytext>
</fullquery>


<fullquery name="party::get_by_email.select_party_id">
      <querytext>
      
        select party_id 
        from   parties 
        where  lower(email) = lower(:email)

      </querytext>
</fullquery>

<fullquery name="acs_user::get_user_id_by_screen_name.select_user_id_by_screen_name">
      <querytext>

	select user_id from users where lower(screen_name) = lower(:screen_name)

      </querytext>
</fullquery>

<fullquery name="acs_user::change_state.select_rel_id">
      <querytext>

	select rel_id
        from cc_users
        where user_id = :user_id

      </querytext>
</fullquery>


   <fullquery name="acs_user::get_portrait_id_not_cached.get_item_id">
      <querytext>
         select c.item_id
         from acs_rels a, cr_items c
         where a.object_id_two = c.item_id
           and a.object_id_one = :user_id
           and a.rel_type = 'user_portrait_rel'
      </querytext>
   </fullquery>


</queryset>
