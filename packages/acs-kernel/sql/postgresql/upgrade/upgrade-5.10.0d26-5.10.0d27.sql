--
-- function site_node__url/1
--

CREATE OR REPLACE FUNCTION site_node__url(
      url__node_id integer
) RETURNS varchar AS $$

    WITH RECURSIVE site_nodes_path(parent_id, path, directory_p, node_id) as (

	select parent_id, ARRAY[name || case when directory_p then '/' else ' ' end]::text[] as path, directory_p, node_id
	from site_nodes where node_id = url__node_id

	UNION ALL

	select sn.parent_id, sn.name::text || snr.path , sn.directory_p, snr.parent_id
	from site_nodes sn join site_nodes_path snr on sn.node_id = snr.parent_id
	where snr.parent_id is not null

    ) select array_to_string(path,'/') from site_nodes_path where parent_id is null

$$ LANGUAGE sql strict stable;




--
-- function acs_group__member_p/3
--

CREATE OR REPLACE FUNCTION acs_group__member_p(
   p_party_id integer,
   p_group_id integer,
   p_cascade_membership boolean
) RETURNS boolean AS $$

  SELECT CASE
  WHEN p_cascade_membership = true then
    --
    -- Direct and indirect memberships
    --
    EXISTS (
      select 1 from group_member_map
      where group_id = p_group_id
	and member_id = p_party_id
    )
  ELSE
    --
    -- Only direct memberships
    --
    EXISTS (
      select 1 from acs_rels rels
      where rels.rel_type = 'membership_rel'
	and rels.object_id_one = p_group_id
	and rels.object_id_two = p_party_id
    )
  END;

$$ LANGUAGE sql strict stable;
