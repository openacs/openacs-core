--
-- The DO statement is used to allow this script to be run multiple
-- times without raising exceptions
--

DO $$
DECLARE
	v_found boolean;
BEGIN
	--
	-- Was the column already renamed?
	--
	SELECT exists(
	   SELECT column_name 
	   FROM information_schema.columns 
	   WHERE table_name = 'party_approved_member_map' and column_name = 'originating_rel_id'
        ) INTO v_found;

	if v_found IS FALSE then
	   --
	   -- Use a better name for attribute "tag" in party_approved_member_map
	   -- 
	   alter table party_approved_member_map rename tag to originating_rel_id;

	   --
	   -- Create an "identity relationship"
	   --
	   perform acs_object__new(-10, 'relationship') from dual;
	   insert into acs_rels (rel_id, rel_type, object_id_one, object_id_two) values (-10, 'relationship', 0, 0);

	end if;
END$$;

--
-- Use the new identity relation instead of value "0"
--
update party_approved_member_map
set originating_rel_id = -10
where originating_rel_id = 0;

--
-- Make sure, there are no leftovers in the old "tag" attribute, which
-- did not have a foreign key defined
--
delete from party_approved_member_map
where originating_rel_id in
(select originating_rel_id from party_approved_member_map
except select rel_id from acs_rels);

--
-- Add a foreign key ...
-- ... and let the script run multiple times...
--
ALTER TABLE party_approved_member_map
DROP CONSTRAINT IF EXISTS party_member_rel_id_fk;

ALTER TABLE party_approved_member_map
ADD CONSTRAINT party_member_rel_id_fk foreign key (originating_rel_id)
references acs_rels on delete cascade;


DO $$
DECLARE
	v_found boolean;
BEGIN
	--
	-- Was the index already created?
	--
	SELECT exists(
	   SELECT relname from pg_class
	   WHERE relname ='party_member_party_idx'
	) into v_found;
	
	if v_found IS FALSE then
	   --
	   -- speed up referential integrity
	   --
	   create index party_member_party_idx on party_approved_member_map(party_id);
	   create index party_member_originating_idx on party_approved_member_map(originating_rel_id);
	end if;
END$$;


--
-- Redefine the stored procedures/functions referring to the attribute
-- "tag".
--

--
-- procedure party_approved_member__add_one/3
--
CREATE OR REPLACE FUNCTION party_approved_member__add_one(
   p_party_id integer,
   p_member_id integer,
   p_rel_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

  insert into party_approved_member_map
    (party_id, member_id, originating_rel_id)
  values
    (p_party_id, p_member_id, p_rel_id);

  return 1;

END;
$$ LANGUAGE plpgsql;

--
-- procedure party_approved_member__remove_one/3
--
CREATE OR REPLACE FUNCTION party_approved_member__remove_one(
   p_party_id integer,
   p_member_id integer,
   p_rel_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

  delete from party_approved_member_map
  where party_id = p_party_id
    and member_id = p_member_id
    and originating_rel_id = p_rel_id;

  return 1;

END;
$$ LANGUAGE plpgsql;


-- Triggers to maintain party_approved_member_map when parties are created or
-- destroyed.  These don't call the above helper functions because we're just
-- creating the identity row for the party.

CREATE OR REPLACE FUNCTION parties_in_tr () RETURNS trigger AS $$
BEGIN

  insert into party_approved_member_map
    (party_id, member_id, originating_rel_id)
  values
    (new.party_id, new.party_id, -10);

  return new;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION rel_segments_in_tr () RETURNS trigger AS $$
BEGIN

  insert into party_approved_member_map
    (party_id, member_id, originating_rel_id)
  select new.segment_id, element_id, rel_id
    from group_element_index
    where group_id = new.group_id
      and rel_type = new.rel_type;

  return new;

END;
$$ LANGUAGE plpgsql;

--
-- Improve get_func_definition() to return SQL function/procedure
-- definitions with argument names and defaults
--

--
-- procedure get_func_definition/2
--
CREATE OR REPLACE FUNCTION get_func_definition(
   fname varchar,
   args oidvector
) RETURNS text AS $PROC$
DECLARE
        v_funcdef       text default '';
        v_args          varchar;
        v_nargs         integer;
        v_src           text;
        v_rettype       varchar;
BEGIN
        select pg_get_function_arguments(oid), pronargs, prosrc, -- was number_src(prosrc)
               (select typname from pg_type where oid = p.prorettype::integer)
          into v_args, v_nargs, v_src, v_rettype
          from pg_proc p 
         where proname = fname::name
           and proargtypes = args;

         v_funcdef :=
	 	   E'--\n-- ' || fname || '/' || v_nargs || E'\n--' 
         	   || E'\ncreate or replace function ' || fname || E'(\n  '
                   || replace(v_args, ', ', E',\n  ')
	           || E'\n) returns ' || v_rettype
		   || E' as $$\n' || v_src || '$$ language plpgsql;';

        return v_funcdef;
END;
$PROC$ LANGUAGE plpgsql stable strict;
