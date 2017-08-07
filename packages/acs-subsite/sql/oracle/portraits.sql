-- Portrait Data Model

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Hiro Iwashima (iwashima@mit.edu)

-- $Id$

create table user_portraits (
	user_id		constraint user_portraits_user_id_fk
			references users
			constraint user_portraits_user_id_pk
			primary key
);

begin
  acs_rel_type.create_role('user', 'User', 'Users');
  acs_rel_type.create_role('portrait', 'Portrait', 'Portraits');

  acs_rel_type.create_type (
    rel_type => 'user_portrait_rel',
    pretty_name => 'User Portrait',
    pretty_plural => 'User Portraits',
    object_type_one => 'user',
    role_one => 'user',
    table_name => 'user_portraits',
    id_column => 'user_id',
    package_name => 'user_portrait_rel',
    min_n_rels_one => 1,
    max_n_rels_one => 1,
    object_type_two => 'content_item',
    min_n_rels_two => 0,
    max_n_rels_two => 1,
    composable_p => 'f'
  );

  commit;
end;
/
show errors
