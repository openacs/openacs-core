
--- getting rid of backslashes used with the purpose of scaping

-- function is_assigned
select define_function_args ('content_keyword__is_assigned','item_id,keyword_id,recurse;none');
--
-- procedure content_keyword__is_assigned/3
--
CREATE OR REPLACE FUNCTION content_keyword__is_assigned(
   is_assigned__item_id integer,
   is_assigned__keyword_id integer,
   is_assigned__recurse varchar -- default 'none'

) RETURNS boolean AS $$
DECLARE
  v_ret                               boolean;    
  v_is_assigned__recurse	      varchar;
BEGIN
  if is_assigned__recurse is null then 
	v_is_assigned__recurse := 'none';
  else
      	v_is_assigned__recurse := is_assigned__recurse;	
  end if;

  -- Look for an exact match
  if v_is_assigned__recurse = 'none' then
      return count(*) > 0 from cr_item_keyword_map
       where item_id = is_assigned__item_id
         and keyword_id = is_assigned__keyword_id;
  end if;

  -- Look from specific to general
  if v_is_assigned__recurse = 'up' then
      return count(*) > 0
      where exists (select 1
                    from (select keyword_id from cr_keywords c, cr_keywords c2
	                  where c2.keyword_id = is_assigned__keyword_id
                            and c.tree_sortkey between c2.tree_sortkey and tree_right(c2.tree_sortkey)) t,
                      cr_item_keyword_map m
                    where t.keyword_id = m.keyword_id
                      and m.item_id = is_assigned__item_id);
  end if;

  if v_is_assigned__recurse = 'down' then
      return count(*) > 0
      where exists (select 1
                    from (select k2.keyword_id
                          from cr_keywords k1, cr_keywords k2
                          where k1.keyword_id = is_assigned__keyword_id
                            and k1.tree_sortkey between k2.tree_sortkey and tree_right(k2.tree_sortkey)) t, 
                      cr_item_keyword_map m
                    where t.keyword_id = m.keyword_id
                      and m.item_id = is_assigned__item_id);

  end if;  

  -- Tried none, up and down - must be an invalid parameter
  raise EXCEPTION '-20000: The recurse parameter to content_keyword.is_assigned should be ''none'', ''up'' or ''down''';
  
  return null;
END;
$$ LANGUAGE plpgsql stable;

select define_function_args('content_item__generic_move','item_id,target_item_id,name');


-- getting rid of extra end if on function

--
-- procedure content_item__generic_move/3
--
CREATE OR REPLACE FUNCTION content_item__generic_move(
   move__item_id integer,
   move__target_item_id integer,
   move__name varchar
) RETURNS integer AS $$
DECLARE
BEGIN

  if move__target_item_id is null then 
	raise exception 'attempt to move item_id % to null folder_id', move__item_id;
  end if;

  if content_folder__is_folder(move__item_id) = 't' then

    PERFORM content_folder__move(move__item_id, move__target_item_id);

  elsif content_folder__is_folder(move__target_item_id) = 't' then

    if content_folder__is_registered(move__target_item_id,
          content_item__get_content_type(move__item_id),'f') = 't' and
       content_folder__is_registered(move__target_item_id,
          content_item__get_content_type(content_symlink__resolve(move__item_id)),'f') = 't'
      then
    end if;
  end if;

  -- update the parent_id for the item

  update cr_items 
    set parent_id = move__target_item_id,
        name = coalesce(move__name, name)
    where item_id = move__item_id;

  -- GN: the following "end if" appears to be not needed
  -- end if;

  if move__name is not null then
    update acs_objects
      set title = move__name
      where object_id = move__item_id;
  end if;

  return 0; 
END;
$$ LANGUAGE plpgsql;


--- Removing 7.2 vs 7.3 querying 

select define_function_args('content_type__refresh_trigger','content_type');
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

select define_function_args('content_type__drop_type','content_type,drop_children_p;f,drop_table_p;f,drop_objects_p;f');
--
-- procedure content_type__drop_type/4
--
CREATE OR REPLACE FUNCTION content_type__drop_type(
   drop_type__content_type varchar,
   drop_type__drop_children_p boolean, -- default 'f'
   drop_type__drop_table_p boolean,    -- default 'f'
   drop_type__drop_objects_p boolean   -- default 'f'

) RETURNS integer AS $$
DECLARE
  table_exists_p                      boolean;       
  v_table_name                      varchar;   
  is_subclassed_p                   boolean;      
  child_rec                         record;    
  attr_row                          record;
  revision_row                      record;
  item_row                          record;
BEGIN

  -- first we'll rid ourselves of any dependent child types, if any , 
  -- along with their own dependent grandchild types

  select 
    count(*) > 0 into is_subclassed_p 
  from 
    acs_object_types 
  where supertype = drop_type__content_type;

  -- this is weak and will probably break;
  -- to remove grand child types, the process will probably
  -- require some sort of querying for drop_type 
  -- methods within the children's packages to make
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
      PERFORM content_type__drop_type(child_rec.object_type, 't', drop_type__drop_table_p, drop_type__drop_objects_p);
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
                                         'f'
    );
  end LOOP;

  -- we'll remove the associated table if it exists
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

    execute 'drop table ' || v_table_name || ' cascade';

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
END;
$$ LANGUAGE plpgsql;


-- getting right definition of function's arguments 

select define_function_args('cr_items_get_tree_sortkey','item_id');
select define_function_args('cr_keywords_get_tree_sortkey','keyword_id');
select define_function_args('content_extlink__new','name;null,url,label;null,description;null,parent_id,extlink_id;null,creation_date;now,creation_user;null,creation_ip;null,package_id;null');
select define_function_args('content_extlink__delete','extlink_id');
select define_function_args('content_extlink__is_extlink','item_id');
select define_function_args('content_extlink__copy','extlink_id,target_folder_id,creation_user,creation_ip;null,name');
select define_function_args('content_folder__new','name,label,description;null,parent_id;null,context_id;null,folder_id;null,creation_date;now,creation_user;null,creation_ip;null,security_inherit_p;t,package_id;null');
select define_function_args('content_folder__del','folder_id,cascade_p;f');
select define_function_args('content_folder__delete','folder_id,cascade_p;f');
select define_function_args('content_folder__edit_name','folder_id,name;null,label;null,description;null');
select define_function_args('content_folder__move','folder_id,target_folder_id,name;null');
select define_function_args('content_folder__copy','folder_id,target_folder_id,creation_user,creation_ip;null,name;null');
select define_function_args('content_folder__is_folder','item_id');
select define_function_args('content_folder__is_sub_folder','folder_id,target_folder_id');
select define_function_args('content_folder__is_empty','folder_id');
select define_function_args('content_folder__register_content_type','folder_id,content_type,include_subtypes;f');
select define_function_args('content_folder__unregister_content_type','folder_id,content_type,include_subtypes;f');
select define_function_args('content_folder__is_registered','folder_id,content_type,include_subtypes;f');
select define_function_args('content_folder__get_label','folder_id');
select define_function_args('content_folder__get_index_page','folder_id');
select define_function_args('content_folder__is_root','folder_id');
select define_function_args('image__new','name,parent_id;null,item_id;null,revision_id;null,mime_type;jpeg,creation_user;null,creation_ip;null,relation_tag;null,title;null,description;null,is_live;f,publish_date;now(),path,file_size,height,width,package_id;null');
select define_function_args('image__new_revision','item_id,revision_id,title,description,publish_date,mime_type,nls_language,creation_user,creation_ip,height,width,package_id');
select define_function_args('image__delete','v_item_id');
select define_function_args('content_item__get_root_folder','item_id;null');
select define_function_args('content_item__new','name,parent_id;null,item_id;null,locale;null,creation_date;now,creation_user;null,context_id;null,creation_ip;null,item_subtype;content_item,content_type;content_revision,title;null,description;null,mime_type;text/plain,nls_language;null,text;null,data;null,relation_tag;null,is_live;f,storage_type;null,package_id;null');
select define_function_args('content_item__is_published','item_id');
select define_function_args('content_item__is_publishable','item_id');
select define_function_args('content_item__is_valid_child','item_id,content_type,relation_tag');
select define_function_args('content_item__del','item_id');
select define_function_args('content_item__delete','item_id');
select define_function_args('content_item__edit_name','item_id,name');
select define_function_args('content_item__get_id','item_path,root_folder_id;null,resolve_index;f');
select define_function_args('content_item__get_path','item_id,root_folder_id;null');
select define_function_args('content_item__get_virtual_path','item_id,root_folder_id;-100');
select define_function_args('content_item__write_to_file','item_id,root_path');
select define_function_args('content_item__register_template','item_id,template_id,use_context');
select define_function_args('content_item__unregister_template','item_id,template_id;null,use_context;null');
select define_function_args('content_item__get_template','item_id,use_context');
select define_function_args('content_item__get_content_type','item_id');
select define_function_args('content_item__get_live_revision','item_id');
select define_function_args('content_item__get_live_revision','item_id');
select define_function_args('content_item__set_live_revision','revision_id,publish_status;ready');
select define_function_args('content_item__set_live_revision','revision_id,publish_status;ready');
select define_function_args('content_item__unset_live_revision','item_id');
select define_function_args('content_item__set_release_period','item_id,start_when;null,end_when;null');
select define_function_args('content_item__get_revision_count','item_id');
select define_function_args('content_item__get_revision_count','item_id');
select define_function_args('content_item__get_context','item_id');
select define_function_args('content_item__move','item_id,target_folder_id,name');
select define_function_args('content_item__generic_move','item_id,target_item_id,name');
select define_function_args('content_item__copy2','item_id,target_folder_id,creation_user,creation_ip;null');
select define_function_args('content_item__copy','item_id,target_folder_id,creation_user,creation_ip;null,name;null');
select define_function_args('content_item__get_latest_revision','item_id');
select define_function_args('content_item__get_best_revision','item_id');
select define_function_args('content_item__get_title','item_id,is_live;f');
select define_function_args('content_item__get_publish_date','item_id,is_live;f');
select define_function_args('content_item__is_subclass','object_type,supertype');
select define_function_args('content_item__relate','item_id,object_id,relation_tag;generic,order_n;null,relation_type;cr_item_rel');
select define_function_args('content_item__unrelate','rel_id');
select define_function_args('content_item__unrelate','rel_id');
select define_function_args('content_item__is_index_page','item_id,folder_id');
select define_function_args('content_item__is_index_page','item_id,folder_id');
select define_function_args('content_item__get_parent_folder','item_id');
select define_function_args ('content_keyword__get_heading','keyword_id');
select define_function_args ('content_keyword__get_description','keyword_id');
select define_function_args ('content_keyword__set_heading','keyword_id,heading');
select define_function_args ('content_keyword__set_description','keyword_id,description');
select define_function_args ('content_keyword__is_leaf','keyword_id');
select define_function_args('content_keyword__new','heading,description;null,parent_id;null,keyword_id;null,creation_date;now,creation_user;null,creation_ip;null,object_type;content_keyword');
select define_function_args ('content_keyword__del','keyword_id');
select define_function_args('content_keyword__delete','keyword_id');
select define_function_args ('content_keyword__item_assign','item_id,keyword_id,context_id;null,creation_user;null,creation_ip;null');
select define_function_args ('content_keyword__item_unassign','item_id,keyword_id');
select define_function_args ('content_keyword__is_assigned','item_id,keyword_id,recurse;none');
select define_function_args ('content_keyword__get_path','keyword_id');
select define_function_args('content_permission__inherit_permissions','parent_object_id,child_object_id,child_creator_id;null');
select define_function_args('content_permission__has_grant_authority','object_id,holder_id,privilege');
select define_function_args('content_permission__has_revoke_authority','object_id,holder_id,privilege,revokee_id');
select define_function_args('content_permission__grant_permission_h','object_id,grantee_id,privilege');
select define_function_args('content_permission__grant_permission','object_id,holder_id,privilege,recipient_id,is_recursive;f,object_type;content_item');
select define_function_args('content_permission__revoke_permission_h','object_id,revokee_id,privilege');
select define_function_args('content_permission__revoke_permission','object_id,holder_id,privilege,revokee_id,is_recursive;f,object_type;content_item');
select define_function_args('content_permission__permission_p','object_id,holder_id,privilege');
select define_function_args('content_revision__new','title,description;null,publish_date;now(),mime_type;text/plain,nls_language;null,text; ,item_id,revision_id;null,creation_date;now(),creation_user;null,creation_ip;null,content_length;null,package_id;null');
select define_function_args('content_revision__copy_attributes','content_type,revision_id,copy_id');
select define_function_args('content_revision__copy','revision_id,copy_id;null,target_item_id;null,creation_user;null,creation_ip;null');
select define_function_args('content_revision__del','revision_id');
select define_function_args('content_revision__delete','revision_id');
select define_function_args('content_revision__get_number','revision_id');
select define_function_args('content_revision__revision_name','revision_id');
select define_function_args('content_revision__to_html','revision_id');
select define_function_args('content_revision__is_live','revision_id');
select define_function_args('content_revision__is_latest','revision_id');
select define_function_args('content_revision__to_temporary_clob','revision_id');
select define_function_args('content_revision__content_copy','revision_id,revision_id_dest;null');
select define_function_args('content_revision__get_content','revision_id');
select define_function_args('content_symlink__new','name;null,label;null,target_id,parent_id,symlink_id;null,creation_date;now,creation_user;null,creation_ip;null,package_id;null');
select define_function_args('content_symlink__delete','symlink_id');
select define_function_args('content_symlink__del','symlink_id');
select define_function_args('content_symlink__is_symlink','item_id');
select define_function_args('content_symlink__copy','symlink_id,target_folder_id,creation_user,creation_ip;null,name;null');
select define_function_args('content_symlink__resolve','item_id');
select define_function_args('content_symlink__resolve_content_type','item_id');
select define_function_args('content_template__new','name,parent_id;null,template_id;null,creation_date;now,creation_user;null,creation_ip;null,text;null,is_live;f');
select define_function_args('content_template__del','template_id');
select define_function_args('content_template__delete','template_id');
select define_function_args('content_template__is_template','template_id');
select define_function_args('content_template__get_path','template_id,root_folder_id;content_template_globals.c_root_folder_id');
select define_function_args('content_test__save_val','v_id,v_name');
select define_function_args('content_type__create_type','content_type,supertype;content_revision,pretty_name,pretty_plural,table_name,id_column;XXX,name_method;null');
select define_function_args('content_type__drop_type','content_type,drop_children_p;f,drop_table_p;f,drop_objects_p;f');
select define_function_args('content_type__drop_type','content_type,drop_children_p;f,drop_table_p;f,drop_objects_p;f');
select define_function_args('content_type__create_attribute','content_type,attribute_name,datatype,pretty_name,pretty_plural;null,sort_order;null,default_value;null,column_spec;text');
select define_function_args('content_type__drop_attribute','content_type,attribute_name,drop_column;f');
select define_function_args('content_type__register_template','content_type,template_id,use_context,is_default;f');
select define_function_args('content_type__set_default_template','content_type,template_id,use_context');
select define_function_args('content_type__get_template','content_type,use_context');
select define_function_args('content_type__unregister_template','content_type;null,template_id,use_context;null');
select define_function_args('content_type__trigger_insert_statement','content_type');
select define_function_args('content_type__refresh_trigger','content_type');
select define_function_args('content_type__refresh_view','content_type');
select define_function_args('content_type__register_child_type','parent_type,child_type,relation_tag;generic,min_n;0,max_n;null');
select define_function_args('content_type__register_child_type','parent_type,child_type,relation_tag;generic,min_n;0,max_n;null');
select define_function_args('content_type__unregister_child_type','parent_type,child_type,relation_tag');
select define_function_args('content_type__register_relation_type','content_type,target_type,relation_tag;generic,min_n;0,max_n;null');
select define_function_args('content_type__unregister_relation_type','content_type,target_type,relation_tag;null');
select define_function_args('content_type__register_mime_type','content_type,mime_type');
select define_function_args('content_type__unregister_mime_type','content_type,mime_type');
select define_function_args('content_type__is_content_type','object_type'); 
select define_function_args('content_type__rotate_template','template_id,v_content_type,use_context');
select define_function_args('table_exists','table_name');
select define_function_args('column_exists','table_name,column_name');
select define_function_args('trigger_exists','trigger_name,on_table');
select define_function_args('trigger_func_exists','trigger_name');
select define_function_args('rule_exists','rule_name,table_name');
select define_function_args('doc__get_proc_header','proc_name,package_name');
select define_function_args('doc__get_package_header','package_name');


-- right return type for functions used in triggers and right naming 
-- vguerra - NOTE: ALTER TRIGGER could be used for renaming the triggers but it 
-- is available starting from PG 8.2 on, so for backwards compatibility 
-- we simply drop and recreate the triggers.

--
-- procedure cr_revision_del_ri_tr/0
--
CREATE OR REPLACE FUNCTION cr_revision_del_ri_tr(

) RETURNS trigger AS $$
DECLARE
        dummy           integer;
        v_latest        integer;
        v_live          integer;
BEGIN
        select 1 into dummy
        from 
          cr_revisions           
        where 
          revision_id = old.live_revision;
        
        if FOUND then
          raise EXCEPTION 'Referential Integrity: live_revision still exists: %', old.live_revision;
        end if;
        
        select 1 into dummy
        from 
          cr_revisions 
        where 
          revision_id = old.latest_revision;
        
        if FOUND then
          raise EXCEPTION 'Referential Integrity: latest_revision still exists: %', old.latest_revision;
        end if;
        
        return old;
END;
$$ LANGUAGE plpgsql;



--
-- procedure cr_revision_ins_ri_tr/0
--
CREATE OR REPLACE FUNCTION cr_revision_ins_ri_tr(

) RETURNS trigger AS $$
DECLARE
        dummy           integer;
        v_latest        integer;
        v_live          integer;
BEGIN
        select 1 into dummy
        from 
          cr_revisions           
        where 
          revision_id = new.live_revision;
        
        if NOT FOUND and new.live_revision is NOT NULL then
          raise EXCEPTION 'Referential Integrity: live_revision does not exist: %', new.live_revision;
        end if;
        
        select 1 into dummy
        from 
          cr_revisions 
        where 
          revision_id = new.latest_revision;
        
        if NOT FOUND and new.latest_revision is NOT NULL then
          raise EXCEPTION 'Referential Integrity: latest_revision does not exist: %', new.latest_revision;
        end if;

        return new;
END;
$$ LANGUAGE plpgsql;



--
-- procedure cr_revision_up_ri_tr/0
--
CREATE OR REPLACE FUNCTION cr_revision_up_ri_tr(

) RETURNS trigger AS $$
DECLARE
        dummy           integer;
        v_latest        integer;
        v_live          integer;
BEGIN
        select 1 into dummy
        from 
          cr_revisions           
        where 
          revision_id = new.live_revision;
        
        if NOT FOUND and new.live_revision <> old.live_revision and new.live_revision is NOT NULL then
          raise EXCEPTION 'Referential Integrity: live_revision does not exist: %', new.live_revision;
        end if;
        
        select 1 into dummy
        from 
          cr_revisions 
        where 
          revision_id = new.latest_revision;
        
        if NOT FOUND and new.latest_revision <> old.latest_revision and new.latest_revision is NOT NULL then
          raise EXCEPTION 'Referential Integrity: latest_revision does not exist: %', new.latest_revision;
        end if;
        
        return new;
END;
$$ LANGUAGE plpgsql;



--
-- procedure cr_revision_del_rev_ri_tr/0
--
CREATE OR REPLACE FUNCTION cr_revision_del_rev_ri_tr(

) RETURNS trigger AS $$
DECLARE
        dummy           integer;
BEGIN
        select 1 into dummy
        from 
          cr_items
        where 
          item_id = old.item_id
        and
          live_revision = old.revision_id;
        
        if FOUND then
          raise EXCEPTION 'Referential Integrity: attempting to delete live_revision: %', old.revision_id;
        end if;
        
        select 1 into dummy
        from 
          cr_items
        where 
          item_id = old.item_id
        and
          latest_revision = old.revision_id;
        
        if FOUND then
          raise EXCEPTION 'Referential Integrity: attempting to delete latest_revision: %', old.revision_id;
        end if;
        
        return old;
END;
$$ LANGUAGE plpgsql;

--
-- procedure cr_cleanup_cr_files_del_tr/0
--
CREATE OR REPLACE FUNCTION cr_cleanup_cr_files_del_tr(

) RETURNS trigger AS $$
DECLARE
        
BEGIN
        insert into cr_files_to_delete
        select r.content as path, i.storage_area_key
          from cr_items i, cr_revisions r
         where i.item_id = r.item_id
           and r.revision_id = old.revision_id
           and i.storage_type = 'file'
           and r.content is not null;

        return old;
END;
$$ LANGUAGE plpgsql;

create trigger cr_revision_del_ri_tr 
after delete on cr_items
for each row execute procedure cr_revision_del_ri_tr();

create trigger cr_revision_up_ri_tr 
after update on cr_items
for each row execute procedure cr_revision_up_ri_tr();

create trigger cr_revision_ins_ri_tr 
after insert on cr_items
for each row execute procedure cr_revision_ins_ri_tr();

create trigger cr_revision_del_rev_ri_tr 
after delete on cr_revisions
for each row execute procedure cr_revision_del_rev_ri_tr();

create trigger cr_cleanup_cr_files_del_tr
before delete on cr_revisions
for each row execute procedure cr_cleanup_cr_files_del_tr();

drop trigger cr_revision_del_ri_trg on cr_items;
drop trigger cr_revision_up_ri_trg on cr_items;
drop trigger cr_revision_ins_ri_trg on cr_items;
drop trigger cr_revision_del_rev_ri_trg on cr_revisions;
drop trigger cr_cleanup_cr_files_del_trg on cr_revisions;

drop function cr_revision_del_ri_trg();
drop function cr_revision_up_ri_trg();
drop function cr_revision_ins_ri_trg();
drop function cr_revision_del_rev_ri_trg();
drop function cr_cleanup_cr_files_del_trg();
