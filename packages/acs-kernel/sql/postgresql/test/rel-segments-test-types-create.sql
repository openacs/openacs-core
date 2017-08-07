
CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN
	PERFORM acs_rel_type__create_type (
		'blah_member_rel',
		'Blah Membership Relationship',
		'Blah Membership Relationships',
                'membership_rel',
		'blah_member_rels',
		'rel_id',
		'blah_member_rel',
		'group',
                null,
		0,
		null,
		'party',
                'member',
		0,
		null,
        't'
		);


	PERFORM acs_rel_type__create_type (
		'yippie_member_rel',
		'Yippie Membership Relationship',
		'Yippie Membership Relationships',
		'membership_rel',
		'yippie_member_rels',
		'rel_id',
		'yippie_member_rel',
		'group',
		null,
		0,
		null,
		'party',
                'member',
		0,
		null,
        't'
		);

        return null;

END;
$$ LANGUAGE plpgsql;

select inline_0 ();

drop function inline_0 ();


-- show errors

create table blah_member_rels (
	rel_id			integer constraint blah_member_rel_id_fk
				references membership_rels (rel_id)
				constraint blah_member_rel_pk
				primary key
);

create table yippie_member_rels (
	rel_id			integer constraint yippie_member_rel_id_fk
				references membership_rels (rel_id)
				constraint yippie_member_rel_pk
				primary key
);


-- create or replace package blah_member_rel
-- is
--   function new (
-- 	rel_id		in blah_member_rels.rel_id%TYPE 
-- 				default null,
-- 	rel_type	in acs_rels.rel_type%TYPE 
-- 				default 'blah_member_rel',
-- 	object_id_one	in groups.group_id%TYPE,
-- 	object_id_two	in parties.party_id%TYPE
--   ) return blah_member_rels.rel_id%TYPE;
-- 
--   procedure delete (
-- 	rel_id		in blah_member_rels.rel_id%TYPE
--   );
-- end blah_member_rel;

-- show errors

-- create or replace package body blah_member_rel
-- function new


-- added
select define_function_args('blah_member_rel__new','rel_id,rel_type,object_id_one,object_id_two');

--
-- procedure blah_member_rel__new/4
--
CREATE OR REPLACE FUNCTION blah_member_rel__new(
   new__rel_id integer,
   new__rel_type varchar,
   new__object_id_one integer,
   new__object_id_two integer
) RETURNS integer AS $$
DECLARE
  v_rel_id                    blah_member_rels.rel_id%TYPE;
BEGIN

	v_rel_id := membership_rel__new(
		new__rel_id,
		new__rel_type,
		new__object_id_one,
		new__object_id_two,
                'approved',
                null,
                null
	);

	insert into blah_member_rels
	(rel_id)
	values
	(v_rel_id);

	return v_rel_id;
   
END;
$$ LANGUAGE plpgsql;


-- procedure delete


-- added
select define_function_args('blah_member_rel__delete','rel_id');

--
-- procedure blah_member_rel__delete/1
--
CREATE OR REPLACE FUNCTION blah_member_rel__delete(
   delete__rel_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

	delete from blah_member_rels where rel_id = delete__rel_id;

	PERFORM membership_rel__delete(delete__rel_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;



-- show errors



-- create or replace package yippie_member_rel
-- is
--   function new (
-- 	rel_id		in yippie_member_rels.rel_id%TYPE 
-- 				default null,
-- 	rel_type	in acs_rels.rel_type%TYPE 
-- 				default 'yippie_member_rel',
-- 	object_id_one	in groups.group_id%TYPE,
-- 	object_id_two	in parties.party_id%TYPE
--   ) return yippie_member_rels.rel_id%TYPE;
-- 
--   procedure delete (
-- 	rel_id		in yippie_member_rels.rel_id%TYPE
--   );
-- end yippie_member_rel;

-- show errors

-- create or replace package body yippie_member_rel
-- function new


-- added
select define_function_args('yippie_member_rel__new','rel_id,rel_type,object_id_one,object_id_two');

--
-- procedure yippie_member_rel__new/4
--
CREATE OR REPLACE FUNCTION yippie_member_rel__new(
   new__rel_id integer,
   new__rel_type varchar,
   new__object_id_one integer,
   new__object_id_two integer
) RETURNS integer AS $$
DECLARE
  v_rel_id                    yippie_member_rels.rel_id%TYPE;
BEGIN

	v_rel_id := membership_rel__new(
		new__rel_id,
		new__rel_type,
		new__object_id_one,
		new__object_id_two,
                'approved',
                null,
                null
	);

	insert into yippie_member_rels
	(rel_id)
	values
	(v_rel_id);

	return v_rel_id;
   
END;
$$ LANGUAGE plpgsql;


-- procedure delete


-- added
select define_function_args('yippie_member_rel__delete','rel_id');

--
-- procedure yippie_member_rel__delete/1
--
CREATE OR REPLACE FUNCTION yippie_member_rel__delete(
   delete__rel_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

	delete from yippie_member_rels where rel_id = delete__rel_id;

	PERFORM membership_rel__delete(delete__rel_id);

        return 0; 
END;
$$ LANGUAGE plpgsql;



-- show errors
