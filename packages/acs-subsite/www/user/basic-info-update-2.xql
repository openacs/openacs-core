<?xml version="1.0"?>
<queryset>

<fullquery name="screen_name_unique_count">      
      <querytext>
      
    select count(*) from users where screen_name = :screen_name and user_id != :user_id
      </querytext>
</fullquery>

 
<fullquery name="email_unique_count">      
      <querytext>
      select count(party_id) from parties where email = lower(:email) and party_id <> :user_id
      </querytext>
</fullquery>

 
<fullquery name="grab_bio">      
      <querytext>
      select attr_value as bio_old
    from acs_attribute_values
    where object_id = :user_id
    and attribute_id =
      (select attribute_id
      from acs_attributes
      where object_type = 'person'
      and attribute_name = 'bio')
      </querytext>
</fullquery>

 
<fullquery name="update_parties">      
      <querytext>
      update parties
      set email = :email,
      url = :url
      where party_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="update_persons">      
      <querytext>
      update persons
      set first_names = :first_names,
      last_name = :last_name
      where person_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="update_users">      
      <querytext>
      update users
      set screen_name=:screen_name
      where user_id = :user_id
      </querytext>
</fullquery>

 
<fullquery name="insert_bio">      
      <querytext>
      insert into acs_attribute_values
	(object_id, attribute_id, attr_value)
	values 
	(:user_id, (select attribute_id
          from acs_attributes
          where object_type = 'person'
          and attribute_name = 'bio'), :bio)
      </querytext>
</fullquery>

 
<fullquery name="update_bio">      
      <querytext>
      update acs_attribute_values
	set attr_value = :bio
	where object_id = :user_id
	and attribute_id =
          (select attribute_id
          from acs_attributes
          where object_type = 'person'
          and attribute_name = 'bio')
      </querytext>
</fullquery>

 
</queryset>
