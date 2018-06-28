<?xml version="1.0"?>
<queryset>

<fullquery name="person::update.update_person">      
      <querytext>
      
	update persons
         set    [join $cols ", "]
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

<fullquery name="party::get_by_email_not_cached.select_party_id">
      <querytext>
      
        select party_id 
        from   parties 
        where  lower(email) = lower(:email)

      </querytext>
</fullquery>

<fullquery name="party::name.get_org_name">
    <querytext>
	select
		name
	from 
		organizations
	where
		organization_id = :party_id
    </querytext>
</fullquery>

<fullquery name="party::name.get_group_name">
    <querytext>
	select
		group_name
	from 
		groups
	where
		group_id = :party_id
    </querytext>
</fullquery>

<fullquery name="party::name.get_party_name">
    <querytext>
	select
		party_name
	from 
		party_names
	where
		party_id = :party_id
    </querytext>
</fullquery>

<fullquery name="acs_user::get_user_id_by_screen_name.select_user_id_by_screen_name">
      <querytext>

	select user_id from users where lower(screen_name) = lower(:screen_name)

      </querytext>
</fullquery>

</queryset>
