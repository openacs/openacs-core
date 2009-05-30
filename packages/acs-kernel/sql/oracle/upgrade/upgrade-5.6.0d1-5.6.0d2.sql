alter table users add bio text;

create function inline_0 ()
returns integer as '
declare
  one_user_id integer;
  bio_id integer;
begin

  bio_id := attribute_id
            from acs_attributes
            where object_type = ''person''
            and attribute_name = ''bio'';

  for one_user_id in select user_id from users loop
    if exists(select attr_value
              from acs_attribute_values
              where object_id = one_user_id
              and attribute_id = bio_id) then
      update users
      set bio = (select attr_value
                 from acs_attribute_values
                 where object_id = one_user_id
                 and attribute_id = bio_id)
      where user_id = one_user_id;
    end if;
  end loop;

  delete from acs_attribute_values
  where attribute_id = bio_id;

  perform acs_attribute__drop_attribute (''person'',''bio'');
  perform acs_attribute__drop_attribute (''person'',''bio_mime_type'');

  return 0;

end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

