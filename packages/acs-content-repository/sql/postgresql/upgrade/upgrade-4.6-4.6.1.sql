-- Upgrade script
--
-- @author Ola Hansson <ola@polyxena.net>
-- @created 2002-12-30

-- fixes bug http://openacs.org/bugtracker/openacs/patch?patch_number=25

create or replace function content_type__drop_type (varchar,boolean,boolean)
returns integer as '
declare
  drop_type__content_type           alias for $1;  
  drop_type__drop_children_p        alias for $2;  -- default ''f''  
  drop_type__drop_table_p           alias for $3;  -- default ''f''
  table_exists_p                      boolean;       
  v_table_name                      varchar;   
  is_subclassed_p                   boolean;      
  child_rec                         record;    
  attr_row                          record;
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
      PERFORM content_type__drop_type(child_rec.object_type, ''t'', ''f'');
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

    if version() like ''%7.2%'' then
      execute ''drop rule '' || v_table_name || ''_r'';
    else
      -- 7.3 syntax
      execute ''drop rule '' || v_table_name || ''_r '' || ''on '' || v_table_name || ''i'';
    end if;

    execute ''drop view '' || v_table_name || ''x'';
    execute ''drop view '' || v_table_name || ''i'';

    execute ''drop table '' || v_table_name;
  end if;

  PERFORM acs_object_type__drop_type(drop_type__content_type, ''f'');

  return 0; 
end;' language 'plpgsql';


-- procedure refresh_trigger
create or replace function content_type__refresh_trigger (varchar)
returns integer as '
declare
  refresh_trigger__content_type           alias for $1;  
  rule_text                               text default '''';
  v_table_name                            acs_object_types.table_name%TYPE;
  type_rec                                record;
begin

  -- get the table name for the content type (determines view name)

  select table_name 
    into v_table_name
    from acs_object_types 
   where object_type = refresh_trigger__content_type;

  --=================== start building rule code =======================

  rule_text := ''create rule '' || v_table_name || ''_r as on insert to '' ||
               v_table_name || ''i do instead (
                update cr_dummy set val = (
                select content_revision__new(
                                     new.title,
                                     new.description,
                                     now(),
                                     new.mime_type,
                                     new.nls_language,
                                     case when new.text is null 
                                              then new.data 
                                              else new.text
                                           end,
                                     content_symlink__resolve(new.item_id),
                                     new.revision_id,
                                     now(),
                                     new.creation_user, 
                                     new.creation_ip
                ));
                '';

  -- add an insert statement for each subtype in the hierarchy for this type

  for type_rec in select ot2.object_type, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2
                  where ot2.object_type <> ''acs_object''                       
                    and ot2.object_type <> ''content_revision''
                    and ot1.object_type = refresh_trigger__content_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by level desc
  LOOP
    rule_text := rule_text || '' '' || content_type__trigger_insert_statement(type_rec.object_type) || '';'';
  end loop;

  -- end building the rule definition code

  rule_text := rule_text || '' );'';

  --================== done building rule code =======================

  -- drop the old rule
  if rule_exists(v_table_name || ''_r'', v_table_name || ''i'') then 

    -- different syntax for dropping a rule in 7.2 and 7.3 so check which
    -- version is being used (olah).
    if version() like ''%7.2%'' then
      execute ''drop rule '' || v_table_name || ''_r'';
    else
      -- 7.3 syntax
      execute ''drop rule '' || v_table_name || ''_r '' || ''on '' || v_table_name || ''i'';
    end if;

  end if;

  -- create the new rule for inserts on the content type
  execute rule_text;

  return null; 

end;' language 'plpgsql';