--
-- procedure acs_group__member_p/3
--
CREATE OR REPLACE FUNCTION acs_group__member_p(
   p_party_id integer,
   p_group_id integer,
   p_cascade_membership boolean
) RETURNS boolean AS $$
DECLARE
BEGIN
  if p_cascade_membership then
    --
    -- Direct and indirect memberships
    --
    return count(*) > 0
      from group_member_map
      where group_id = p_group_id
        and member_id = p_party_id;
  else
    --
    -- Only direct memberships
    --
    return count(*) > 0
      from acs_rels rels
    where rels.rel_type = 'membership_rel'
      and rels.object_id_one = p_group_id
      and rels.object_id_two = p_party_id
      and acs_permission.permission_p(rels.rel_id, p_party_id, 'read');
  end if;
END;
$$ LANGUAGE plpgsql stable;
