--
-- add extended attribute to rel types
--
-- make the upgrade script loadable multiple times
DO $$
DECLARE
	v_found boolean;
BEGIN
	SELECT exists(
	   SELECT 1 FROM information_schema.columns WHERE table_name='acs_rel_types' and column_name='composable_p'
	) INTO v_found;
	if v_found IS FALSE then

	   ALTER TABLE acs_rel_types ADD COLUMN composable_p boolean DEFAULT true NOT NULL;
	   UPDATE acs_rel_types SET composable_p = false WHERE rel_type = 'admin_rel';
	   
	end if;
END$$;


drop trigger membership_rels_in_tr on membership_rels;
drop function membership_rels_in_tr ();


--
-- procedure membership_rels_in_tr/0
--
CREATE OR REPLACE FUNCTION membership_rels_in_tr(

) RETURNS trigger AS $$
DECLARE
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_composable_p  acs_rel_types.composable_p%TYPE;
  v_error         text;
  map             record;
BEGIN
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint__violation(new.rel_id);
  if v_error is not null then
      raise EXCEPTION '-20000: %', v_error;
  end if;

  select object_id_one, object_id_two, r.rel_type, composable_p
  into v_object_id_one, v_object_id_two, v_rel_type, v_composable_p
  from acs_rels r
  join acs_rel_types t on (r.rel_type = t.rel_type)
  where rel_id = new.rel_id;

  -- Insert a row for me in the group_element_index.
  insert into group_element_index
   (group_id, element_id, rel_id, container_id, 
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, new.rel_id, v_object_id_one, 
    v_rel_type, 'membership_rel');

  if new.member_state = 'approved' then
    perform party_approved_member__add(v_object_id_one, v_object_id_two, new.rel_id, v_rel_type);
  end if;

  -- If this rel_type composable...
  if v_composable_p = 't' then

     -- For all groups of which I am a component, insert a
     -- row in the group_element_index.
     for map in select distinct group_id
          from group_component_map
          where component_id = v_object_id_one 
     loop

        insert into group_element_index
               (group_id, element_id, rel_id, container_id,
               rel_type, ancestor_rel_type)
        values
               (map.group_id, v_object_id_two, new.rel_id, v_object_id_one,
               v_rel_type, 'membership_rel');

        if new.member_state = 'approved' then
           perform party_approved_member__add(map.group_id, v_object_id_two, new.rel_id, v_rel_type);
        end if;

     end loop;
  end if;
  return new;

END;
$$ LANGUAGE plpgsql;

create trigger membership_rels_in_tr after insert on membership_rels
for each row execute procedure membership_rels_in_tr ();

drop trigger composition_rels_in_tr on composition_rels;
drop function composition_rels_in_tr ();



--
-- procedure composition_rels_in_tr/0
--
CREATE OR REPLACE FUNCTION composition_rels_in_tr(

) RETURNS trigger AS $$
DECLARE
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_error         text;
  map             record;
BEGIN
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint__violation(new.rel_id);

  if v_error is not null then
      raise EXCEPTION '-20000: %', v_error;
  end if;

  select object_id_one, object_id_two, rel_type
  into v_object_id_one, v_object_id_two, v_rel_type
  from acs_rels
  where rel_id = new.rel_id;

  -- Insert a row for me in group_element_index
  insert into group_element_index
   (group_id, element_id, rel_id, container_id,
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, new.rel_id, v_object_id_one,
    v_rel_type, 'composition_rel');

  -- Add to the denormalized party_approved_member_map

  perform party_approved_member__add(v_object_id_one, member_id, rel_id, rel_type)
  from group_approved_member_map m
  where group_id = v_object_id_two
  and not exists (select 1
          from group_element_map
          where group_id = v_object_id_one
          and element_id = m.member_id
          and rel_id = m.rel_id);

  -- Make my composable elements be elements of my new composite group
  insert into group_element_index
   (group_id, element_id, rel_id, container_id,
    rel_type, ancestor_rel_type)
  select distinct
   v_object_id_one, element_id, rel_id, container_id,
   m.rel_type, ancestor_rel_type
  from group_element_map m
  join acs_rel_types t on (m.rel_type = t.rel_type)
  where group_id = v_object_id_two
  and t.composable_p = 't'
  and not exists (select 1
          from group_element_map
          where group_id = v_object_id_one
          and element_id = m.element_id
          and rel_id = m.rel_id);

  -- For all direct or indirect containers of my new composite group, 
  -- add me and add my elements
  for map in  select distinct group_id
          from group_component_map
          where component_id = v_object_id_one 
  LOOP

    -- Add a row for me

    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    values
     (map.group_id, v_object_id_two, new.rel_id, v_object_id_one,
      v_rel_type, 'composition_rel');

    -- Add to party_approved_member_map

    perform party_approved_member__add(map.group_id, member_id, rel_id, m.rel_type)
    from group_approved_member_map m
    join acs_rel_types t on (m.rel_type = t.rel_type)
    where group_id = v_object_id_two
    and t.composable_p = 't'
    and not exists (select 1
            from group_element_map
            where group_id = map.group_id
            and element_id = m.member_id
            and rel_id = m.rel_id);

    -- Add rows for my composable elements

    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    select distinct
     map.group_id, element_id, rel_id, container_id,
     m.rel_type, ancestor_rel_type
    from group_element_map m
    join acs_rel_types t on (m.rel_type = t.rel_type)
    where group_id = v_object_id_two
    and t.composable_p = 't'
    and not exists (select 1
            from group_element_map
            where group_id = map.group_id
            and element_id = m.element_id
            and rel_id = m.rel_id);
  end loop;

  return new;

END;
$$ LANGUAGE plpgsql;  

create trigger composition_rels_in_tr after insert on composition_rels
for each row execute procedure composition_rels_in_tr ();

select define_function_args('acs_rel_type__create_type','rel_type,pretty_name,pretty_plural,supertype;relationship,table_name,id_column,package_name,object_type_one,role_one;null,min_n_rels_one,max_n_rels_one,object_type_two,role_two;null,min_n_rels_two,max_n_rels_two,composable_p;t');

drop function if exists acs_rel_type__create_type(
   varchar,
   varchar,
   varchar,
   varchar, -- default 'relationship'
   varchar,
   varchar,
   varchar,
   varchar,
   varchar,  -- default null
   integer,
   integer,
   varchar,
   varchar,  -- default null
   integer,
   integer
   );
--
-- procedure acs_rel_type__create_type/16
--
CREATE OR REPLACE FUNCTION acs_rel_type__create_type(
   create_type__rel_type varchar,
   create_type__pretty_name varchar,
   create_type__pretty_plural varchar,
   create_type__supertype varchar, -- default 'relationship'
   create_type__table_name varchar,
   create_type__id_column varchar,
   create_type__package_name varchar,
   create_type__object_type_one varchar,
   create_type__role_one varchar,  -- default null
   create_type__min_n_rels_one integer,
   create_type__max_n_rels_one integer,
   create_type__object_type_two varchar,
   create_type__role_two varchar,  -- default null
   create_type__min_n_rels_two integer,
   create_type__max_n_rels_two integer,
   create_type__composable_p boolean default true

) RETURNS integer AS $$
DECLARE

  type_extension_table acs_object_types.type_extension_table%TYPE default null;
  abstract_p   acs_object_types.abstract_p%TYPE      default 'f';
  name_method  acs_object_types.name_method%TYPE     default null;     
BEGIN
    PERFORM acs_object_type__create_type(
      create_type__rel_type,
      create_type__pretty_name,
      create_type__pretty_plural,
      create_type__supertype,
      create_type__table_name,
      create_type__id_column,
      create_type__package_name,
      abstract_p,
      type_extension_table,
      name_method
    );

    insert into acs_rel_types
     (rel_type,
      object_type_one, role_one,
      min_n_rels_one, max_n_rels_one,
      object_type_two, role_two,
      min_n_rels_two, max_n_rels_two,
      composable_p)
    values
     (create_type__rel_type,
      create_type__object_type_one, create_type__role_one,
      create_type__min_n_rels_one, create_type__max_n_rels_one,
      create_type__object_type_two, create_type__role_two,
      create_type__min_n_rels_two, create_type__max_n_rels_two,
      create_type__composable_p);

    return 0; 
END;
$$ LANGUAGE plpgsql;



-- procedure create_type

DROP FUNCTION IF EXISTS acs_rel_type__create_type(
   varchar,
   varchar,
   varchar,
   varchar, -- default 'relationship'
   varchar,
   varchar,
   varchar,
   varchar, -- default null
   varchar,
   integer,
   integer,
   varchar,
   integer,
   integer
);
--
-- procedure acs_rel_type__create_type/15
--
CREATE OR REPLACE FUNCTION acs_rel_type__create_type(
   create_type__rel_type varchar,
   create_type__pretty_name varchar,
   create_type__pretty_plural varchar,
   create_type__supertype varchar,            -- default 'relationship'
   create_type__table_name varchar,
   create_type__id_column varchar,
   create_type__package_name varchar,
   create_type__type_extension_table varchar, -- default null
   create_type__object_type_one varchar,
   create_type__min_n_rels_one integer,
   create_type__max_n_rels_one integer,
   create_type__object_type_two varchar,
   create_type__min_n_rels_two integer,
   create_type__max_n_rels_two integer,
   create_type__composable_p boolean default true

) RETURNS integer AS $$
DECLARE

  abstract_p   acs_object_types.abstract_p%TYPE      default 'f';
  name_method  acs_object_types.name_method%TYPE     default null;     
  create_type__role_one  acs_rel_types.role_one%TYPE default null;           
  create_type__role_two  acs_rel_types.role_two%TYPE default null;
BEGIN

    PERFORM acs_object_type__create_type(
      create_type__rel_type,
      create_type__pretty_name,
      create_type__pretty_plural,
      create_type__supertype,
      create_type__table_name,
      create_type__id_column,
      create_type__package_name,
      abstract_p,
      create_type__type_extension_table,
      name_method
    );

    insert into acs_rel_types
     (rel_type,
      object_type_one, role_one,
      min_n_rels_one, max_n_rels_one,
      object_type_two, role_two,
      min_n_rels_two, max_n_rels_two,
      composable_p)
    values
     (create_type__rel_type,
      create_type__object_type_one, create_type__role_one,
      create_type__min_n_rels_one, create_type__max_n_rels_one,
      create_type__object_type_two, create_type__role_two,
      create_type__min_n_rels_two, create_type__max_n_rels_two,
      create_type__composable_p);

    return 0; 
END;
$$ LANGUAGE plpgsql;
