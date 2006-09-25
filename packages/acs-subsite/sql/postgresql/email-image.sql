-- Email Image Data Model
-- author Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
-- creation-date 2005-01-22


create table email_images (
	user_id		integer constraint email_images_user_id_fk
			references users
			constraint email_images_user_id_pk
			primary key
);

create function inline_0 ()
returns integer as '
begin
  PERFORM acs_rel_type__create_role(''email_image'', ''Email Image'', ''Email Images'');

  PERFORM acs_rel_type__create_type (
      ''email_image_rel'',
      ''Email Image'',
      ''Email Images'',
      ''relationship'',
      ''email_images'',
      ''user_id'',
      ''email_image_rel'',
      ''user'',
      ''user'',
      1,
      1,
      ''content_item'',
      null,
      0,
      1
  );

  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();
