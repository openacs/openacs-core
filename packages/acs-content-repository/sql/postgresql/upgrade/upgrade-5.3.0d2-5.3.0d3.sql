select define_function_args('content_type__drop_type','content_type,drop_children_p;f,drop_table_p;f,drop_objects_p;f');

create or replace function content_type__drop_type (varchar,boolean,boolean,boolean)
returns integer as '
declare
  drop_type__content_type           alias for $1;  
  drop_type__drop_children_p        alias for $2;  -- default ''f''  
  drop_type__drop_table_p           alias for $3;  -- default ''f''
  drop_type__drop_objects_p         alias for $4;  -- default ''f''
  table_exists_p                      boolean;       
  v_table_name                      varchar;   
  is_subclassed_p                   boolean;      
  child_rec                         record;    
  attr_row                          record;
  revision_row                      record;
  item_row                          record;
begin

  -- first we''ll rid ourselves of any dependent child types, if any , 
  -- along with their own dependent grandchild types

  select 
    count(*) > 0 into is_subclassed_p 
  from 
    acs_object_types 
  where supertype = drop_type__content_type;

  -- this is weak and will probably break;
  -- to remove grand child types, the process will probably
  -- require some sort of querying for drop_type 
  -- methods within the children''s packages to make
  -- certain there are no additional unanticipated
  -- restraints preventing a clean drop

  if drop_type__drop_children_p and is_subclassed_p then

    for child_rec in select 
                       object_type
                     from 
                       acs_object_types
                     where
                       supertype = drop_type__content_type 
    LOOP
      PERFORM content_type__drop_type(child_rec.object_type, ''t'', drop_type__drop_table_p, drop_type__drop_objects_p);
    end LOOP;

  end if;

  -- now drop all the attributes related to this type
  for attr_row in select
                    attribute_name
                  from
                    acs_attributes
                  where
                    object_type = drop_type__content_type 
  LOOP
    PERFORM content_type__drop_attribute(drop_type__content_type,
                                         attr_row.attribute_name,
                                         ''f''
    );
  end LOOP;

  -- we''ll remove the associated table if it exists
  select 
    table_exists(lower(table_name)) into table_exists_p
  from 
    acs_object_types
  where 
    object_type = drop_type__content_type;

  if table_exists_p and drop_type__drop_table_p then
    select 
      table_name into v_table_name 
    from 
      acs_object_types 
    where
      object_type = drop_type__content_type;
       
    -- drop the rule and input/output views for the type
    -- being dropped.
    -- FIXME: this did not exist in the oracle code and it needs to be
    -- tested.  Thanks to Vinod Kurup for pointing this out.
    -- The rule dropping might be redundant as the rule might be dropped
    -- when the view is dropped.

    -- different syntax for dropping a rule in 7.2 and 7.3 so check which
    -- version is being used (olah).

    execute ''drop table '' || v_table_name || '' cascade'';

  end if;

  -- If we are dealing with a revision, delete the revision with revision__delete
  -- This way the integrity constraint with live revision is dealt with correctly
  if drop_type__drop_objects_p then
    for revision_row in
      select revision_id 
      from cr_revisions, acs_objects
      where revision_id = object_id
      and object_type = drop_type__content_type
    loop
      PERFORM content_revision__delete(revision_row.revision_id);
    end loop;

    for item_row in
      select item_id 
      from cr_items
      where content_type = drop_type__content_type
    loop
      PERFORM content_item__delete(item_row.item_id);
    end loop;

  end if;

  PERFORM acs_object_type__drop_type(drop_type__content_type, drop_type__drop_objects_p);

  return 0; 
end;' language 'plpgsql';
