--
-- procedure content_type__refresh_trigger/1
--
CREATE OR REPLACE FUNCTION content_type__refresh_trigger(
   refresh_trigger__content_type varchar
) RETURNS integer AS $$
DECLARE
  rule_text                               text default '';
  function_text                           text default '';
  v_table_name                            acs_object_types.table_name%TYPE;
  type_rec                                record;
BEGIN

  -- get the table name for the content type (determines view name)
  raise NOTICE 'refresh trigger for % ', refresh_trigger__content_type;

    -- Since we allow null table name use object type if table name is null so
  -- we still can have a view.
  select coalesce(table_name,object_type)
    into v_table_name
    from acs_object_types 
   where object_type = refresh_trigger__content_type;

  --=================== start building rule code =======================

  function_text := function_text ||
             'create or replace function ' || v_table_name || '_f (p_new '|| v_table_name || 'i)
             returns void as ''
             declare
               v_revision_id integer;
             begin

               select content_revision__new(
                                     p_new.title,
                                     p_new.description,
                                     p_new.publish_date,
                                     p_new.mime_type,
                                     p_new.nls_language,
                                     case when p_new.text is null 
                                              then p_new.data 
                                              else p_new.text
                                           end,
                                     content_symlink__resolve(p_new.item_id),
                                     p_new.revision_id,
                                     now(),
                                     p_new.creation_user, 
                                     p_new.creation_ip,
                                     p_new.object_package_id
                ) into v_revision_id;
                ';

  -- add an insert statement for each subtype in the hierarchy for this type

  for type_rec in select ot2.object_type, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2
                  where ot2.object_type <> 'acs_object'                       
                    and ot2.object_type <> 'content_revision'
                    and ot1.object_type = refresh_trigger__content_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                    and ot1.table_name is not null
                  order by level asc
  LOOP
    function_text := function_text || ' ' || content_type__trigger_insert_statement(type_rec.object_type) || ';
    ';
  end loop;

  function_text := function_text || '
   return;
   end;'' language ''plpgsql''; 
   ';
  -- end building the rule definition code

  -- create the new function
  execute function_text;

  rule_text := 'create rule ' || v_table_name || '_r as on insert to ' ||
               v_table_name || 'i do instead SELECT ' || v_table_name || '_f(new); ' ;
  --================== done building rule code =======================

  -- drop the old rule
  if rule_exists(v_table_name || '_r', v_table_name || 'i') then 
     execute 'drop rule ' || v_table_name || '_r ' || 'on ' || v_table_name || 'i';
  end if;

  -- create the new rule for inserts on the content type
  execute rule_text;

  return null; 

END;
$$ LANGUAGE plpgsql;


-- upgrade types

WITH RECURSIVE cr_types as (
    select object_type from acs_object_types where object_type = 'content_revision'
UNION ALL
    select ot.object_type from acs_object_types ot,cr_types 
    where ot.supertype = cr_types.object_type
) select object_type, content_type__refresh_view(object_type) from cr_types;
