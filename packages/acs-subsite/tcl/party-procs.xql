<?xml version="1.0"?>
<queryset>

<fullquery name="new.package_select">      
      <querytext>
      
	    select t.package_name, lower(t.id_column) as id_column
	      from acs_object_types t
	     where t.object_type = :party_type
	
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

<fullquery name="party::party_p.party_p">
    <querytext>
	select
		1
	from 
		parties
	where
		party_id = :object_id
    </querytext>
</fullquery>
 
</queryset>
