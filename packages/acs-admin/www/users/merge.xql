<?xml version="1.0"?>
  <queryset>

    <fullquery name="one_user_portrait">      
      <querytext>

	select 
	  c.item_id
	from acs_rels a, cr_items c
	where a.object_id_two = c.item_id
          and a.object_id_one = :user_id
	  and a.rel_type = 'user_portrait_rel'

      </querytext>
    </fullquery>

    <fullquery name="one_get_info">
      <querytext>
	select 
	  first_names as one_first_names,
	  last_name as one_last_name,
  	  creation_user as one_creation_user,
	  to_char(creation_date,'month DD, yyyy') as one_creation_date,
	  creation_ip as one_creation_ip,
	  to_char(last_modified,'month DD, yyyy') as one_last_modified,
	  email as one_email,
	  url as one_url,
	  modifying_user as one_modifying_user,
	  modifying_ip as one_modifying_ip,
	  username as one_username,
	  screen_name as one_screen_name,
	  to_char(last_visit,'month DD, yyyy') as one_last_visit,
	  member_state as one_member_state
	from cc_users
	where user_id = :user_id
      </querytext>
    </fullquery>

    <fullquery name="two_user_portrait">      
      <querytext>

	select 
	  c.item_id
	from acs_rels a, cr_items c
	where a.object_id_two = c.item_id
	  and a.object_id_one = :user_id_from_search
	  and a.rel_type = 'user_portrait_rel'

      </querytext>
    </fullquery>    

    <fullquery name="two_get_info">
      <querytext>
	select 
	first_names as two_first_names,
	last_name as two_last_name,
	creation_user as two_creation_user,
	to_char(creation_date,'month DD, yyyy') as two_creation_date,
	creation_ip as two_creation_ip,
	to_char(last_modified,'month DD, yyyy') as two_last_modified,
	email as two_email,
	url as two_url,
	modifying_user as two_modifying_user,
	modifying_ip as two_modifying_ip,
	username as two_username,
	screen_name as two_screen_name,
	to_char(last_visit,'month DD, yyyy') as two_last_visit,
	member_state as two_member_state
	from cc_users
	where user_id = :user_id_from_search
      </querytext>
    </fullquery>

  </queryset>

