-- procedure refresh_trigger
select define_function_args('content_type__refresh_trigger','content_type');

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
                                     new.creation_ip,
                                     new.object_package_id
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
    if version() like ''%PostgreSQL 7.2%'' then
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


create function inline_0 ()
returns integer as '
declare
    ct RECORD;
    v_dummy integer;
begin
  for ct in select object_type
            from acs_object_type_supertype_map
            where ancestor_type = ''content_revision''
  loop
    select content_type__refresh_trigger (ct.object_type) into v_dummy;
  end loop;

  return null;
end;' language 'plpgsql';

select inline_0();
drop function inline_0();
