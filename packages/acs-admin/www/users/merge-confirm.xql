<?xml version="1.0"?>
  <queryset>

    <fullquery name="from_get_info">
      <querytext>
	select 
	first_names as from_first_names,
	last_name as from_last_name,
	email as from_email
	from cc_users
	where user_id = :from_user_id
      </querytext>
    </fullquery>
    
    <fullquery name="to_get_info">
      <querytext>
	select 
	first_names as to_first_names,
	last_name as to_last_name,
	email as to_email
	from cc_users
	where user_id = :to_user_id
      </querytext>
    </fullquery>

    <fullquery name="to_user_portrait">      
      <querytext>

	select c.item_id
	from acs_rels a, cr_items c
	where a.object_id_two = c.item_id
	and a.object_id_one = :to_user_id
	and a.rel_type = 'user_portrait_rel'

      </querytext>
    </fullquery>

  </queryset>
