-- Portrait Data Model

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Hiro Iwashima (iwashima@mit.edu)

-- $Id$

create table user_portraits (
	user_id		integer constraint user_portraits_user_id_fk
			references users
			constraint user_portraits_user_id_pk
			primary key
);

-- begin
--   acs_rel_type.create_role('user', 'User', 'Users');
--   acs_rel_type.create_role('portrait', 'Portrait', 'Portraits');

--   acs_rel_type.create_type (
--     rel_type => 'user_portrait_rel',
--     pretty_name => 'User Portrait',
--     pretty_plural => 'User Portraits',
--     object_type_one => 'user',
--     role_one => 'user',
--     table_name => 'user_portraits',
--     id_column => 'user_id',
--     package_name => 'user_portrait_rel',
--     min_n_rels_one => 1,
--     max_n_rels_one => 1,
--     object_type_two => 'content_item',
--     min_n_rels_two => 0,
--     max_n_rels_two => 1
--   );

--   commit;
-- end;
-- /
-- show errors

CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN
  PERFORM acs_rel_type__create_role('user', 'User', 'Users');
  PERFORM acs_rel_type__create_role('portrait', 'Portrait', 'Portraits');

  PERFORM acs_rel_type__create_type (
      'user_portrait_rel',
      '#acs-subsite.User_Portrait#',
      '#acs-subsite.User_Portraits#',
      'relationship',
      'user_portraits',
      'user_id',
      'user_portrait_rel',
      'user',
      'user',
      1,
      1,
      'content_item',
      null,
      0,
      1
  );

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_0 ();

drop function inline_0 ();
