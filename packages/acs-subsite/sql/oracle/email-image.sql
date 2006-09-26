-- Email-Image Data Model
-- author  Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
-- creation-date 2005-01-22


create table email_images (
	user_id		constraint email_images_user_id_fk
			references users
			constraint email_images_user_id_pk
			primary key
);

begin
  acs_rel_type.create_role('email_image', 'Email Image', 'Email Images');

  acs_rel_type.create_type (
    rel_type => 'email_image_rel',
    pretty_name => 'Email Image',
    pretty_plural => 'Email Images',
    object_type_one => 'user',
    role_one => 'user',
    table_name => 'email_images',
    id_column => 'user_id',
    package_name => 'email_image_rel',
    min_n_rels_one => 1,
    max_n_rels_one => 1,
    object_type_two => 'content_item',
    min_n_rels_two => 0,
    max_n_rels_two => 1
  );

  commit;
end;
/
show errors
