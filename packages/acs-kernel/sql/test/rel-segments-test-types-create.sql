
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
		null::integer,
		'party',
                'member',
		0,
		null::integer,
               'f'
		);


	PERFORM acs_rel_type__create_type (
		'yippe_member_rel',
		'Yippe Membership Relationship',
		'Yippe Membership Relationships',
		'membership_rel',
		'yippe_member_rels',
		'rel_id',
		'yippe_member_rel',
		'group',
		null,
		0,
		null::integer,
		'party',
                'member',
		0,
		null::integer,
                'f'
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

create table yippe_member_rels (
	rel_id			integer constraint yippe_member_rel_id_fk
				references membership_rels (rel_id)
				constraint yippe_member_rel_pk
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



-- create or replace package yippe_member_rel
-- is
--   function new (
-- 	rel_id		in yippe_member_rels.rel_id%TYPE 
-- 				default null,
-- 	rel_type	in acs_rels.rel_type%TYPE 
-- 				default 'yippe_member_rel',
-- 	object_id_one	in groups.group_id%TYPE,
-- 	object_id_two	in parties.party_id%TYPE
--   ) return yippe_member_rels.rel_id%TYPE;
-- 
--   procedure delete (
-- 	rel_id		in yippe_member_rels.rel_id%TYPE
--   );
-- end yippe_member_rel;

-- show errors

-- create or replace package body yippe_member_rel
-- function new


-- added
select define_function_args('yippe_member_rel__new','rel_id,rel_type,object_id_one,object_id_two');

--
-- procedure yippe_member_rel__new/4
--
CREATE OR REPLACE FUNCTION yippe_member_rel__new(
   new__rel_id integer,
   new__rel_type varchar,
   new__object_id_one integer,
   new__object_id_two integer
) RETURNS integer AS $$
DECLARE
  v_rel_id                    yippe_member_rels.rel_id%TYPE;
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


	insert into yippe_member_rels
	(rel_id)
	values
	(v_rel_id);

	return v_rel_id;
   
END;
$$ LANGUAGE plpgsql;


-- procedure delete


-- added
select define_function_args('yippe_member_rel__delete','rel_id');

--
-- procedure yippe_member_rel__delete/1
--
CREATE OR REPLACE FUNCTION yippe_member_rel__delete(
   delete__rel_id yippe_member_rels
) RETURNS integer AS $$
DECLARE
BEGIN

	delete from yippe_member_rels where rel_id = delete__rel_id;

	PERFORM membership_rel__delete(delete__rel_id);

        return 0; 
END;
$$ LANGUAGE plpgsql;



-- show errors
