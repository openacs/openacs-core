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

<fullquery name="person::name_not_cached.get_person_name">      
      <querytext>
      
          select first_names||' '||last_name as person_name
            from persons
           where person_id = :person_id
          
      </querytext>
</fullquery>

<fullquery name="person::get_bio.select_bio">      
      <querytext>
          select attr_value as bio
          from acs_attribute_values
          where object_id = :person_id
          and attribute_id =
             (select attribute_id
              from acs_attributes
              where object_type = 'person'
              and attribute_name = 'bio')
      </querytext>
</fullquery>

<fullquery name="person::update_bio.insert_bio">      
      <querytext>
        insert into acs_attribute_values
	(object_id, attribute_id, attr_value)
	values 
	(:person_id, (select attribute_id
          from acs_attributes
          where object_type = 'person'
          and attribute_name = 'bio'), :bio)
      </querytext>
</fullquery>

<fullquery name="person::update_bio.update_bio">      
      <querytext>
        update acs_attribute_values
	set attr_value = :bio
	where object_id = :person_id
	and attribute_id =
          (select attribute_id
          from acs_attributes
          where object_type = 'person'
          and attribute_name = 'bio')
      </querytext>
</fullquery>

 
<fullquery name="acs_user::update.user_update">      
      <querytext>
      
	update users
        set    [join $cols ", "]
        where  user_id = :user_id
    
      </querytext>
</fullquery>

<fullquery name="acs_user::get_by_username.user_id_from_username">      
      <querytext>

            select user_id
            from   users
            where  lower(username) = lower(:username)
            and    authority_id =:authority_id

      </querytext>
</fullquery>

<fullquery name="party::update.party_update">      
      <querytext>
      
	update parties
        set    [join $cols ", "]
        where  party_id = :party_id

      </querytext>
</fullquery>

<fullquery name="party::get_by_email.select_party_id">
      <querytext>
      
        select party_id 
        from   parties 
        where  lower(email) = lower(:email)

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

<fullquery name="ad_user_new.update_question_answer">
      <querytext>

            update users
            set    password_question = :password_question,
                   password_answer = :password_answer
            where  user_id = :user_id

      </querytext>
</fullquery>

</queryset>
