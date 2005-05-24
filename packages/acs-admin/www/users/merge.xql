<?xml version="1.0"?>
  <queryset>

    <fullquery name="one_select_member_clubs">
        <querytext>
            select dotlrn_clubs_full.*,
                   dotlrn_member_rels_approved.rel_type,
                   dotlrn_member_rels_approved.role,
                   '' as role_pretty_name
            from dotlrn_clubs_full,
                 dotlrn_member_rels_approved
            where dotlrn_member_rels_approved.user_id = :user_id
            and dotlrn_member_rels_approved.community_id = dotlrn_clubs_full.club_id
            order by dotlrn_clubs_full.pretty_name,
                     dotlrn_clubs_full.community_key
        </querytext>
    </fullquery>

    <fullquery name="two_select_dotlrn_user_info">
      <querytext>
	select 
	  dotlrn_users.id as two_id, 
	  dotlrn_users.pretty_type as two_pretty_type, 
	  guest_p as two_guest_p
	from dotlrn_users left outer join dotlrn_guest_status
	on dotlrn_guest_status.user_id = dotlrn_users.user_id
	where dotlrn_users.user_id = :user_id_from_search
      </querytext>
    </fullquery>

    <fullquery name="two_select_member_classes">
      <querytext>
	select dotlrn_class_instances_full.*,
    	  dotlrn_member_rels_approved.rel_type,
	  dotlrn_member_rels_approved.role,
	  '' as role_pretty_name
	from dotlrn_class_instances_full,
	dotlrn_member_rels_approved
	where dotlrn_member_rels_approved.user_id = :user_id_from_search
	and dotlrn_member_rels_approved.community_id = dotlrn_class_instances_full.class_instance_id
	order by dotlrn_class_instances_full.department_name,
	dotlrn_class_instances_full.department_key,
	dotlrn_class_instances_full.pretty_name,
	dotlrn_class_instances_full.community_key
      </querytext>
    </fullquery>

    <fullquery name="two_select_member_clubs">
        <querytext>
            select dotlrn_clubs_full.*,
                   dotlrn_member_rels_approved.rel_type,
                   dotlrn_member_rels_approved.role,
                   '' as role_pretty_name
            from dotlrn_clubs_full,
                 dotlrn_member_rels_approved
            where dotlrn_member_rels_approved.user_id = :user_id_from_search
            and dotlrn_member_rels_approved.community_id = dotlrn_clubs_full.club_id
            order by dotlrn_clubs_full.pretty_name,
                     dotlrn_clubs_full.community_key
        </querytext>
    </fullquery>

    <fullquery name="one_select_dotlrn_user_info">
      <querytext>
	select 
	  dotlrn_users.id as one_id, 
	  dotlrn_users.pretty_type as one_pretty_type, 
	  guest_p as one_guest_p
	from dotlrn_users left outer join dotlrn_guest_status
	on dotlrn_guest_status.user_id = dotlrn_users.user_id
	where dotlrn_users.user_id = :user_id
      </querytext>
    </fullquery>

    <fullquery name="one_select_member_classes">
      <querytext>
	select dotlrn_class_instances_full.*,
    	  dotlrn_member_rels_approved.rel_type,
	  dotlrn_member_rels_approved.role,
	  '' as role_pretty_name
	from dotlrn_class_instances_full,
	dotlrn_member_rels_approved
	where dotlrn_member_rels_approved.user_id = :user_id
	and dotlrn_member_rels_approved.community_id = dotlrn_class_instances_full.class_instance_id
	order by dotlrn_class_instances_full.department_name,
	dotlrn_class_instances_full.department_key,
	dotlrn_class_instances_full.pretty_name,
	dotlrn_class_instances_full.community_key
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
    
    <fullquery name="one_user_portrait">      
      <querytext>

	select c.item_id
	from acs_rels a, cr_items c
	where a.object_id_two = c.item_id
	and a.object_id_one = :user_id
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

    <fullquery name="two_user_portrait">      
      <querytext>

	select c.item_id
	from acs_rels a, cr_items c
	where a.object_id_two = c.item_id
	and a.object_id_one = :user_id_from_search
	and a.rel_type = 'user_portrait_rel'

      </querytext>
    </fullquery>

    <fullquery name="one_user_contributions">
      <querytext>
      select at.pretty_name, at.pretty_plural, to_char(a.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date,
          acs_object__name(a.object_id) as object_name
      from acs_objects a, acs_object_types at
      where a.object_type = at.object_type
          and a.creation_user = :user_id
      order by pretty_name, creation_date desc, object_name
      </querytext>
    </fullquery>

    <fullquery name="two_user_contributions">
      <querytext>
      select at.pretty_name, at.pretty_plural, to_char(a.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date,
          acs_object__name(a.object_id) as object_name
      from acs_objects a, acs_object_types at
      where a.object_type = at.object_type
          and a.creation_user = :user_id_from_search
      order by pretty_name, creation_date desc, object_name
      </querytext>
    </fullquery>

  </queryset>

