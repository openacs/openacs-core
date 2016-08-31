begin
	acs_rel_type.create_type (
                supertype => 'membership_rel',
		rel_type => 'blah_member_rel',
		pretty_name => 'Blah Membership Relationship',
		pretty_plural => 'Blah Membership Relationships',
		table_name => 'blah_member_rels',
		id_column => 'rel_id',
		package_name => 'blah_member_rel',
		object_type_one => 'group', 
		min_n_rels_one => 0, max_n_rels_one => null,
		object_type_two => 'party', role_two => 'member',
		min_n_rels_two => 0, max_n_rels_two => null,
        composable_p => 't'
	);


	acs_rel_type.create_type (
                supertype => 'membership_rel',
		rel_type => 'yippe_member_rel',
		pretty_name => 'Yippe Membership Relationship',
		pretty_plural => 'Yippe Membership Relationships',
		table_name => 'yippe_member_rels',
		id_column => 'rel_id',
		package_name => 'yippe_member_rel',
		object_type_one => 'group', 
		min_n_rels_one => 0, max_n_rels_one => null,
		object_type_two => 'party', role_two => 'member',
		min_n_rels_two => 0, max_n_rels_two => null,
        composable_p => 't'
	);
end;
/
show errors

create table blah_member_rels (
	rel_id			constraint blah_member_rel_id_fk
				references membership_rels (rel_id)
				constraint blah_member_rel_pk
				primary key
);

create table yippe_member_rels (
	rel_id			constraint yippe_member_rel_id_fk
				references membership_rels (rel_id)
				constraint yippe_member_rel_pk
				primary key
);


create or replace package blah_member_rel
is
  function new (
	rel_id		in blah_member_rels.rel_id%TYPE 
				default null,
	rel_type	in acs_rels.rel_type%TYPE 
				default 'blah_member_rel',
	object_id_one	in groups.group_id%TYPE,
	object_id_two	in parties.party_id%TYPE
  ) return blah_member_rels.rel_id%TYPE;

  procedure del (
	rel_id		in blah_member_rels.rel_id%TYPE
  );
end blah_member_rel;
/
show errors

create or replace package body blah_member_rel
is
  function new (
	rel_id		in blah_member_rels.rel_id%TYPE 
				default null,
	rel_type	in acs_rels.rel_type%TYPE 
				default 'blah_member_rel',
	object_id_one	in groups.group_id%TYPE,
	object_id_two	in parties.party_id%TYPE
  ) return blah_member_rels.rel_id%TYPE
  is
	v_rel_id	blah_member_rels.rel_id%TYPE;
  begin

	v_rel_id := membership_rel.new(
		rel_id => rel_id,
		rel_type => rel_type,
		object_id_one => object_id_one,
		object_id_two => object_id_two
	);


	insert into blah_member_rels
	(rel_id)
	values
	(v_rel_id);

	return v_rel_id;

  end new;

  procedure del (
	rel_id		in blah_member_rels.rel_id%TYPE
  )
  is
  begin

	delete from blah_member_rels where rel_id = rel_id;

	membership_rel.del(rel_id);

  end delete;
end blah_member_rel;
/
show errors



create or replace package yippe_member_rel
is
  function new (
	rel_id		in yippe_member_rels.rel_id%TYPE 
				default null,
	rel_type	in acs_rels.rel_type%TYPE 
				default 'yippe_member_rel',
	object_id_one	in groups.group_id%TYPE,
	object_id_two	in parties.party_id%TYPE
  ) return yippe_member_rels.rel_id%TYPE;

  procedure del (
	rel_id		in yippe_member_rels.rel_id%TYPE
  );
end yippe_member_rel;
/
show errors

create or replace package body yippe_member_rel
is
  function new (
	rel_id		in yippe_member_rels.rel_id%TYPE 
				default null,
	rel_type	in acs_rels.rel_type%TYPE 
				default 'yippe_member_rel',
	object_id_one	in groups.group_id%TYPE,
	object_id_two	in parties.party_id%TYPE
  ) return yippe_member_rels.rel_id%TYPE
  is
	v_rel_id	yippe_member_rels.rel_id%TYPE;
  begin

	v_rel_id := membership_rel.new(
		rel_id => rel_id,
		rel_type => rel_type,
		object_id_one => object_id_one,
		object_id_two => object_id_two
	);


	insert into yippe_member_rels
	(rel_id)
	values
	(v_rel_id);

	return v_rel_id;

  end new;

  procedure del (
	rel_id		in yippe_member_rels.rel_id%TYPE
  )
  is
  begin

	delete from yippe_member_rels where rel_id = rel_id;

	membership_rel.del(rel_id);

  end delete;
end yippe_member_rel;
/
show errors
