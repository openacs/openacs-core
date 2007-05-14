-- procedure refresh_trigger
select define_function_args('content_type__refresh_trigger','content_type');
create or replace function content_type__refresh_trigger (varchar)
returns integer as '
declare
  refresh_trigger__content_type           alias for $1;  
  rule_text                               text default '''';
  function_text                           text default '''';
  v_table_name                            acs_object_types.table_name%TYPE;
  type_rec                                record;
begin

  -- get the table name for the content type (determines view name)
  raise NOTICE ''refresh trigger for % '', refresh_trigger__content_type;

  select table_name 
    into v_table_name
    from acs_object_types 
   where object_type = refresh_trigger__content_type;

  --=================== start building rule code =======================

  function_text := function_text ||
             ''create or replace function '' || v_table_name || ''_f (p_new ''|| v_table_name || ''i)
             returns void as ''''
             declare
               v_revision_id integer;
             begin

               select content_revision__new(
                                     p_new.title,
                                     p_new.description,
                                     now(),
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
                '';

  -- add an insert statement for each subtype in the hierarchy for this type

  for type_rec in select ot2.object_type, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2
                  where ot2.object_type <> ''acs_object''                       
                    and ot2.object_type <> ''content_revision''
                    and ot1.object_type = refresh_trigger__content_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by level asc
  LOOP
    function_text := function_text || '' '' || content_type__trigger_insert_statement(type_rec.object_type) || '';
    '';
  end loop;

  function_text := function_text || ''
   return;
   end;'''' language ''''plpgsql''''; 
   '';
  -- end building the rule definition code

  -- create the new function
  execute function_text;

  rule_text := ''create rule '' || v_table_name || ''_r as on insert to '' ||
               v_table_name || ''i do instead SELECT '' || v_table_name || ''_f(new); '' ;
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


-- function trigger_insert_statement
select define_function_args('content_type__trigger_insert_statement','content_type');
create or replace function content_type__trigger_insert_statement (varchar)
returns varchar as '
declare
  trigger_insert_statement__content_type   alias for $1;  
  v_table_name                             acs_object_types.table_name%TYPE;
  v_id_column                              acs_object_types.id_column%TYPE;
  cols                                     varchar default '''';
  vals                                     varchar default '''';
  attr_rec                                 record;
begin
  if trigger_insert_statement__content_type is null then 
        return exception ''content_type__trigger_insert_statement called with null content_type'';
  end if;

  select 
    table_name, id_column into v_table_name, v_id_column
  from 
    acs_object_types 
  where 
    object_type = trigger_insert_statement__content_type;

  for attr_rec in select
                    attribute_name
                  from
                    acs_attributes
                  where
                    object_type = trigger_insert_statement__content_type 
  LOOP
    cols := cols || '', '' || attr_rec.attribute_name;
    vals := vals || '', p_new.'' || attr_rec.attribute_name;
  end LOOP;

  return ''insert into '' || v_table_name || 
    '' ( '' || v_id_column || cols || '' ) values (v_revision_id'' ||
    vals || '')'';
  
end;' language 'plpgsql' stable;

select define_function_args('content_type__refresh_view','content_type');

create or replace function content_type__refresh_view (varchar)
returns integer as '
declare
  refresh_view__content_type           alias for $1;  
  cols                                 varchar default ''''; 
  tabs                                 varchar default ''''; 
  joins                                varchar default '''';
  v_table_name                         varchar;
  join_rec                             record;
begin

  for join_rec in select ot2.table_name, ot2.id_column, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2
                  where ot2.object_type <> ''acs_object''                       
                    and ot2.object_type <> ''content_revision''
                    and lower(ot2.table_name) <> ''acs_objects''     
                    and lower(ot2.table_name) <> ''cr_revisions''
                    and ot1.object_type = refresh_view__content_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by ot2.tree_sortkey desc
  LOOP
    if join_rec.table_name is not null then
        cols := cols || '', '' || join_rec.table_name || ''.*'';
        tabs := tabs || '', '' || join_rec.table_name;
        joins := joins || '' and acs_objects.object_id = '' || 
                 join_rec.table_name || ''.'' || join_rec.id_column;
    end if;
  end loop;

  select table_name into v_table_name from acs_object_types
    where object_type = refresh_view__content_type;

  if length(v_table_name) > 25 then
      raise exception ''Table name cannot be longer than 25 characters, because that causes conflicting rules when we create the views.'';
  end if;

  -- create the input view (includes content columns)

  if table_exists(v_table_name || ''i'') then
     execute ''drop view '' || v_table_name || ''i'' || '' CASCADE'';
  end if;

  -- FIXME:  need to look at content_revision__get_content.  Since the CR
  -- can store data in a lob, a text field or in an external file, getting
  -- the data attribute for this view will be problematic.

  execute ''create view '' || v_table_name ||
    ''i as select  acs_objects.object_id,
 acs_objects.object_type,
 acs_objects.title as object_title,
 acs_objects.package_id as object_package_id,
 acs_objects.context_id,
 acs_objects.security_inherit_p,
 acs_objects.creation_user,
 acs_objects.creation_date,
 acs_objects.creation_ip,
 acs_objects.last_modified,
 acs_objects.modifying_user,
 acs_objects.modifying_ip,
 acs_objects.tree_sortkey,
 acs_objects.max_child_sortkey, cr.revision_id, cr.title, cr.item_id,
    content_revision__get_content(cr.revision_id) as data, 
    cr_text.text_data as text,
    cr.description, cr.publish_date, cr.mime_type, cr.nls_language'' || 
    cols || 
    '' from acs_objects, cr_revisions cr, cr_text'' || tabs || '' where 
    acs_objects.object_id = cr.revision_id '' || joins;

  -- create the output view (excludes content columns to enable SELECT *)

  if table_exists(v_table_name || ''x'') then
     execute ''drop view '' || v_table_name || ''x'';
  end if;

  execute ''create view '' || v_table_name ||
    ''x as select  acs_objects.object_id,
 acs_objects.object_type,
 acs_objects.title as object_title,
 acs_objects.package_id as object_package_id,
 acs_objects.context_id,
 acs_objects.security_inherit_p,
 acs_objects.creation_user,
 acs_objects.creation_date,
 acs_objects.creation_ip,
 acs_objects.last_modified,
 acs_objects.modifying_user,
 acs_objects.modifying_ip,
 acs_objects.tree_sortkey,
 acs_objects.max_child_sortkey, cr.revision_id, cr.title, cr.item_id,
    cr.description, cr.publish_date, cr.mime_type, cr.nls_language,
    i.name, i.parent_id'' || 
    cols || 
    '' from acs_objects, cr_revisions cr, cr_items i, cr_text'' || tabs || 
    '' where acs_objects.object_id = cr.revision_id 
      and cr.item_id = i.item_id'' || joins;

  PERFORM content_type__refresh_trigger(refresh_view__content_type);

-- exception
--   when others then
--     dbms_output.put_line(''Error creating attribute view or trigger for''
--  || content_type);

  return 0; 
end;' language 'plpgsql';


create or replace function inline_0() returns integer as '
declare v_row record;
begin
    for v_row in select distinct o.object_type,o.table_name 
        from acs_object_type_supertype_map m,
	     acs_object_types o
        where (m.ancestor_type=''content_revision''
        and o.object_type=m.object_type)
	or (o.object_type=''content_revision'')
    loop
	if table_exists(v_row.table_name) then 
	    perform content_type__refresh_view(v_row.object_type);
	end if;
    end loop;
return 0;
end;' language 'plpgsql';

select inline_0();

drop function inline_0();

-- rebuild content search triggers to honor publish_date
drop trigger content_search__itrg on cr_revisions;

drop trigger content_search__dtrg on cr_revisions;

drop trigger content_search__utrg on cr_revisions;

drop trigger content_item_search__utrg on cr_items;

drop function content_search__itrg();
drop function content_search__utrg();
drop function content_item_search__utrg();

create function content_search__itrg ()
returns opaque as '
begin
if (select live_revision from cr_items where item_id=new.item_id) = new.revision_id and new.publish_date >= current_timestamp then
        perform search_observer__enqueue(new.revision_id,''INSERT'');
    end if;
    return new;
end;' language 'plpgsql';

create or replace function content_search__utrg ()
returns opaque as '
declare
    v_live_revision integer;
begin
    select into v_live_revision live_revision from
        cr_items where item_id=old.item_id;
    if old.revision_id=v_live_revision
      and new.publish_date <= current_timestamp then
        insert into search_observer_queue (
            object_id,
            event
        ) values (
old.revision_id,
            ''UPDATE''
        );
    end if;
    return new;
end;' language 'plpgsql';

-- we need new triggers on cr_items to index when a live revision
-- changes -DaveB 2002-09-26

create function content_item_search__utrg ()
returns opaque as '
begin
    if new.live_revision is not null and coalesce(old.live_revision,0) <> new.live_revision and (select publish_date from cr_revisions where revision_id=new.live_revision) <= current_timestamp then
        perform search_observer__enqueue(new.live_revision,''INSERT'');        
    end if;

    if old.live_revision is not null and old.live_revision <> coalesce(new.live_revision,0) then
        perform search_observer__enqueue(old.live_revision,''DELETE'');
    end if;
    if new.publish_status = ''expired'' then
        perform search_observer__enqueue(old.live_revision,''DELETE'');
    end if;

    return new;
end;' language 'plpgsql';

create trigger content_search__itrg after insert on cr_revisions
for each row execute procedure content_search__itrg (); 

create trigger content_search__dtrg after delete on cr_revisions
for each row execute procedure content_search__dtrg (); 

create trigger content_search__utrg after update on cr_revisions
for each row execute procedure content_search__utrg (); 


create trigger content_item_search__utrg before update on cr_items
for each row execute procedure content_item_search__utrg ();
