--
-- Fix type of v_is_registered to boolean (was "varchar")
-- (This chance is necessary at least for pg 9.5)
--

--
-- procedure content_folder__register_content_type/3
--
CREATE OR REPLACE FUNCTION content_folder__register_content_type(
   register_content_type__folder_id integer,
   register_content_type__content_type varchar,
   register_content_type__include_subtypes boolean -- default 'f'

) RETURNS integer AS $$
DECLARE
  v_is_registered boolean;  
BEGIN

  if register_content_type__include_subtypes = 'f' then

    v_is_registered := content_folder__is_registered(
        register_content_type__folder_id,
	register_content_type__content_type, 
	'f' 
    );

    if v_is_registered = 'f' then

        insert into cr_folder_type_map (
	  folder_id, content_type
	) values (
	  register_content_type__folder_id, 
	  register_content_type__content_type
	);

    end if;

  else
    
    insert into cr_folder_type_map
      select register_content_type__folder_id as folder_id, 
        o.object_type as content_type
      from acs_object_types o, acs_object_types o2
      where o.object_type <> 'acs_object'
        and not exists (select 1
                        from cr_folder_type_map
                        where folder_id = register_content_type__folder_id
                          and content_type = o.object_type)
        and o2.object_type = register_content_type__content_type
        and o.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey);
  end if;

  return 0; 
END;
$$ LANGUAGE plpgsql;

