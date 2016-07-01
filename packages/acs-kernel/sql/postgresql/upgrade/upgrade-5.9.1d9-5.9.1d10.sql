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
  if p_cascade_membership  then
    return count(*) > 0
      from group_member_map
      where group_id = p_group_id and
            member_id = p_party_id;
  else
    return count(*) > 0
      from acs_rels rels, acs_object_party_privilege_map perm
    where perm.object_id = rels.rel_id
           and perm.privilege = 'read'
           and rels.rel_type = 'membership_rel'
	   and rels.object_id_one = p_group_id
           and rels.object_id_two = p_party_id;
  end if;
END;
$$ LANGUAGE plpgsql stable;
