procedure drop_type (
  content_type		in acs_object_types.object_type%TYPE,
  drop_children_p	in char default 'f',
  drop_table_p		in char default 'f',
  drop_objects_p		in char default 'f'
) is


  cursor attribute_cur is
    select
      attribute_name
    from
      acs_attributes
    where
      object_type = drop_type.content_type;

  cursor child_type_cur is 
    select 
      object_type
    from 
      acs_object_types
    where
      supertype = drop_type.content_type;
 
  cursor revision_cur is
      select revision_id 
      from cr_revisions, acs_objects
      where revision_id = object_id
      and object_type = drop_type.content_type;

  cursor item_cur is 
      select item_id 
      from cr_items
      where content_type = drop_type.content_type;
   
  table_exists integer;
  v_table_name varchar2(50);
  is_subclassed_p char;

 
begin


  -- first we'll rid ourselves of any dependent child types, if any , along with their
  -- own dependent grandchild types
  select 
    decode(count(*),0,'f','t') into is_subclassed_p 
  from 
    acs_object_types 
  where supertype = drop_type.content_type;

  -- this is weak and will probably break;
  -- to remove grand child types, the process will probably
  -- require some sort of querying for drop_type 
  -- methods within the children's packages to make
  -- certain there are no additional unanticipated
  -- restraints preventing a clean drop

  if drop_children_p = 't' and is_subclassed_p = 't' then

    for child_rec in child_type_cur loop
      drop_type( 
        content_type => child_rec.object_type,
	drop_children_p => 't',
	drop_table_p => drop_table_p,
	drop_objects_p => drop_objects_p );
    end loop;

  end if;

  -- now drop all the attributes related to this type
  for attr_row in attribute_cur loop
    drop_attribute(
     content_type => drop_type.content_type,
      attribute_name => attr_row.attribute_name
    );
  end loop;

  -- we'll remove the associated table if it exists
  select 
    decode(count(*),0,0,1) into table_exists 
  from 
    user_tables u, acs_object_types objet
  where 
    objet.object_type = drop_type.content_type and
    u.table_name = upper(objet.table_name);

  if table_exists = 1 and drop_table_p = 't' then
    select 
      table_name into v_table_name 
    from 
      acs_object_types 
    where
      object_type = drop_type.content_type;

    -- drop the input/output views for the type
    -- being dropped.
    -- FIXME: does the trigger get dropped when the 
    -- view is dropped?  This did not exist in the 4.2 release,
    -- and it needs to be tested.

       
    execute immediate 'drop view ' || v_table_name || 'x';
    execute immediate 'drop view ' || v_table_name || 'i';

    execute immediate 'drop table ' || v_table_name;

  end if;

  if drop_objects_p = 't' then
    for revision_row in revision_cur loop
      content_revision.delete( 
        revision_id => revision_row.revision_id
      );
    end loop;
    for item_row in item_cur loop
      content_item.delete( 
        item_id => item_row.item_id
      );
    end loop;
  end if;

  acs_object_type.drop_type(
    object_type   => drop_type.content_type
  );

end drop_type;
