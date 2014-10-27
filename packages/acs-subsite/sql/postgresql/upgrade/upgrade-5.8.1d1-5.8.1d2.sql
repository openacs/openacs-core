-- Providing upgrade script for subsite
--
-- At least at openacs.org, 
--   * the table email_images and
--   * the role and
--   * rel_type email_image_rel 
--
-- were missing; to handle case, where the table was already created
-- (new install) we create the table conditionally.

CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN
  
  if exists (select 1 from pg_class where relname = 'email_images') then
     return 0;
  end if;

  create table email_images (
	user_id integer 
		constraint email_images_user_id_fk references users 
		constraint email_images_user_id_pk primary key
  );

  PERFORM acs_rel_type__create_role('email_image', 'Email Image', 'Email Images');

  PERFORM acs_rel_type__create_type (
      'email_image_rel',
      'Email Image',
      'Email Images',
      'relationship',
      'email_images',
      'user_id',
      'email_image_rel',
      'user',
      'user',
      1,
      1,
      'content_item',
      null,
      0,
      1
  );

  return 1;
END;
$$ LANGUAGE plpgsql;

select inline_0 ();

drop function inline_0 ();



