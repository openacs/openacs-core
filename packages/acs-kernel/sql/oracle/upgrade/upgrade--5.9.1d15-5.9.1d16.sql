-- add extended attribute to rel types
alter table acs_rel_types add column composable_p boolean default 't' not null;
update acs_rel_types set composable_p = 'f' where rel_type = 'admin_rel';

create or replace trigger membership_rels_in_tr
after insert on membership_rels
for each row
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_error varchar2(4000);
begin
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint.violation(:new.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  select object_id_one, object_id_two, r.rel_type, composable_p
  into v_object_id_one, v_object_id_two, v_rel_type
  from acs_rels r
  join acs_rel_types t on (r.rel_type = t.rel_type)
  where rel_id = :new.rel_id;

  -- Insert a row for me in the group_member_index.
  insert into group_element_index
   (group_id, element_id, rel_id, container_id, 
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, :new.rel_id, v_object_id_one, 
    v_rel_type, 'membership_rel');

  if :new.member_state = 'approved' then
    party_approved_member.add(v_object_id_one, v_object_id_two, v_rel_type);
  end if;

  if v_composable_p = 't' then
    -- For all groups of which I am a component, insert a
    -- row in the group_member_index.
    for map in (select distinct group_id
	        from group_component_map
	        where component_id = v_object_id_one) loop
          insert into group_element_index
          (group_id, element_id, rel_id, container_id,
          rel_type, ancestor_rel_type)
          values
          (map.group_id, v_object_id_two, :new.rel_id, v_object_id_one,
          v_rel_type, 'membership_rel');

          if :new.member_state = 'approved' then
             party_approved_member.add(map.group_id, v_object_id_two, v_rel_type);
          end if;

    end loop;
  end if;
end;
/
show errors

create or replace trigger composition_rels_in_tr
after insert on composition_rels
for each row
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_error varchar2(4000);
begin
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint.violation(:new.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  select object_id_one, object_id_two, rel_type
  into v_object_id_one, v_object_id_two, v_rel_type
  from acs_rels
  where rel_id = :new.rel_id;

  -- Insert a row for me in group_element_index
  insert into group_element_index
   (group_id, element_id, rel_id, container_id,
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, :new.rel_id, v_object_id_one,
    v_rel_type, 'composition_rel');

  for members in (select distinct member_id, rel_type
               from group_approved_member_map m
               where group_id = v_object_id_two
                 and not exists (select 1
		                 from group_element_map
		                 where group_id = v_object_id_one
		                   and element_id = m.member_id
		                   and rel_id = m.rel_id))
  loop
    party_approved_member.add(v_object_id_one, members.member_id, members.rel_type);
  end loop;

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
  -- add me and add my composable elements
  for map in (select distinct group_id
	      from group_component_map
	      where component_id = v_object_id_one) loop

    -- Add a row for me
    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    values
     (map.group_id, v_object_id_two, :new.rel_id, v_object_id_one,
      v_rel_type, 'composition_rel');

    -- Add rows for my composable elements

    for members in (select distinct member_id, rel_type
                    from group_approved_member_map m
                     join acs_rel_types t on (m.rel_type = t.rel_type)
                    where group_id = v_object_id_two
                      and t.composable_p = 't'
                      and not exists (select 1
		                      from group_element_map
		                      where group_id = map.group_id
		                        and element_id = m.member_id
		                        and rel_id = m.rel_id))
    loop
      party_approved_member.add(map.group_id, members.member_id, members.rel_type);
    end loop;

    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    select distinct
     map.group_id, element_id, rel_id, container_id,
     rel_type, ancestor_rel_type
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

end;
/
show errors

create or replace package acs_rel_type
as

  procedure create_role (
    role	  in acs_rel_roles.role%TYPE,
    pretty_name   in acs_rel_roles.pretty_name%TYPE default null,
    pretty_plural in acs_rel_roles.pretty_plural%TYPE default null
  );

  procedure drop_role (
    role	in acs_rel_roles.role%TYPE
  );

  function role_pretty_name (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_name%TYPE;

  function role_pretty_plural (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_plural%TYPE;

  procedure create_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'relationship',
    table_name		in acs_object_types.table_name%TYPE,
    id_column		in acs_object_types.id_column%TYPE,
    package_name	in acs_object_types.package_name%TYPE,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null,
    object_type_one	in acs_rel_types.object_type_one%TYPE,
    role_one		in acs_rel_types.role_one%TYPE default null,
    min_n_rels_one	in acs_rel_types.min_n_rels_one%TYPE,
    max_n_rels_one	in acs_rel_types.max_n_rels_one%TYPE,
    object_type_two	in acs_rel_types.object_type_two%TYPE,
    role_two		in acs_rel_types.role_two%TYPE default null,
    min_n_rels_two	in acs_rel_types.min_n_rels_two%TYPE,
    max_n_rels_two	in acs_rel_types.max_n_rels_two%TYPE,
    composable_p    in acs_rel_types.composable_p%TYPE
  );

  procedure drop_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    cascade_p		in char default 'f'
  );

end acs_rel_type;
/
show errors

create or replace package body acs_rel_type
as

  procedure create_role (
    role	  in acs_rel_roles.role%TYPE,
    pretty_name   in acs_rel_roles.pretty_name%TYPE default null,
    pretty_plural in acs_rel_roles.pretty_plural%TYPE default null
  )
  is
  begin
    insert into acs_rel_roles
     (role, pretty_name, pretty_plural)
    values
     (create_role.role, nvl(create_role.pretty_name,create_role.role), nvl(create_role.pretty_plural,create_role.role));
  end;

  procedure drop_role (
    role	in acs_rel_roles.role%TYPE
  )
  is
  begin
    delete from acs_rel_roles
    where role = drop_role.role;
  end;

  function role_pretty_name (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_name%TYPE
  is
    v_pretty_name acs_rel_roles.pretty_name%TYPE;
  begin
    select r.pretty_name into v_pretty_name
      from acs_rel_roles r
     where r.role = role_pretty_name.role;

    return v_pretty_name;
  end role_pretty_name;


  function role_pretty_plural (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_plural%TYPE
  is
    v_pretty_plural acs_rel_roles.pretty_plural%TYPE;
  begin
    select r.pretty_plural into v_pretty_plural
      from acs_rel_roles r
     where r.role = role_pretty_plural.role;

    return v_pretty_plural;
  end role_pretty_plural;

  procedure create_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'relationship',
    table_name		in acs_object_types.table_name%TYPE,
    id_column		in acs_object_types.id_column%TYPE,
    package_name	in acs_object_types.package_name%TYPE,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null,
    object_type_one	in acs_rel_types.object_type_one%TYPE,
    role_one		in acs_rel_types.role_one%TYPE default null,
    min_n_rels_one	in acs_rel_types.min_n_rels_one%TYPE,
    max_n_rels_one	in acs_rel_types.max_n_rels_one%TYPE,
    object_type_two	in acs_rel_types.object_type_two%TYPE,
    role_two		in acs_rel_types.role_two%TYPE default null,
    min_n_rels_two	in acs_rel_types.min_n_rels_two%TYPE,
    max_n_rels_two	in acs_rel_types.max_n_rels_two%TYPE,
    composable_p    in acs_rel_types.composable_p%TYPE
  )
  is
  begin
    acs_object_type.create_type(
      object_type => rel_type,
      pretty_name => pretty_name,
      pretty_plural => pretty_plural,
      supertype => supertype,
      table_name => table_name,
      id_column => id_column,
      package_name => package_name,
      abstract_p => abstract_p,
      type_extension_table => type_extension_table,
      name_method => name_method
    );

    insert into acs_rel_types
     (rel_type,
      object_type_one, role_one,
      min_n_rels_one, max_n_rels_one,
      object_type_two, role_two,
      min_n_rels_two, max_n_rels_two, composable_p)
    values
     (create_type.rel_type,
      create_type.object_type_one, create_type.role_one,
      create_type.min_n_rels_one, create_type.max_n_rels_one,
      create_type.object_type_two, create_type.role_two,
      create_type.min_n_rels_two, create_type.max_n_rels_two, create_type.composable_p);
  end;

  procedure drop_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    cascade_p		in char default 'f'
  )
  is
  begin
    -- XXX do cascade_p
    delete from acs_rel_types
    where acs_rel_types.rel_type = acs_rel_type.drop_type.rel_type;

    acs_object_type.drop_type(acs_rel_type.drop_type.rel_type, acs_rel_type.drop_type.cascade_p);
  end;

end acs_rel_type;
/
show errors
