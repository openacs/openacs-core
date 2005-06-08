<?xml version="1.0"?>

<queryset>

    <fullquery name="auth::local::authentication::MergeUser.to_user_portrait">
      <querytext>
	select c.item_id
	from acs_rels a, cr_items c
	where a.object_id_two = c.item_id
	and a.object_id_one = :to_user_id
	and a.rel_type = 'user_portrait_rel' 
      </querytext>
    </fullquery>

    <fullquery name="auth::local::authentication::MergeUser.from_user_portrait">
      <querytext>
	select c.item_id
	from acs_rels a, cr_items c
	where a.object_id_two = c.item_id
	and a.object_id_one = :from_user_id
	and a.rel_type = 'user_portrait_rel' 
      </querytext>
    </fullquery>

    <fullquery name="auth::local::authentication::MergeUser.upd_portrait">
      <querytext>
	update acs_rels
	set object_id_one = :to_user_id
	where object_id_one = :from_user_id
	and rel_type = 'user_portrait_rel' 
      </querytext>
    </fullquery>
    
    <fullquery name="auth::local::authentication::MergeUser.getfromobjs">
      <querytext>
	select object_id as from_oid, privilege as from_priv from acs_permissions where grantee_id = :from_user_id
      </querytext>
    </fullquery>
    
    <fullquery name="auth::local::authentication::MergeUser.touserhas">
      <querytext>
	select count(*) from acs_permissions where object_id = :from_oid and grantee_id = :to_user_id	
      </querytext>
    </fullquery>
    
    <fullquery name="auth::local::authentication::MergeUser.acs_objs_upd">
      <querytext>
	update acs_objects
	set creation_user = :to_user_id
	where creation_user = :from_user_id 
      </querytext>
    </fullquery>

    <fullquery name="auth::local::authentication::MergeUser.getrelid">
      <querytext>
	select rel_id from cc_users where user_id = :from_user_id      
      </querytext>
    </fullquery>

</queryset>


