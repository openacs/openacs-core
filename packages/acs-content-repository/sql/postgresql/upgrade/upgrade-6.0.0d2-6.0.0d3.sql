-- Add names only to signatures verified against the current install SQL.
-- Prefix names to avoid collisions with the aliases in legacy bodies.
do $$
declare
    target record;
    definition text;
begin
    for target in
        with expected(function_name, input_types, input_names) as (
            values
            ('content_extlink__copy', 'integer,integer,integer,varchar,varchar', 'extlink_id,target_folder_id,creation_user,creation_ip,name'),
            ('content_extlink__delete', 'integer', 'extlink_id'),
            ('content_extlink__is_extlink', 'integer', 'item_id'),
            ('content_folder__del', 'integer,boolean', 'folder_id,cascade_p'),
            ('content_folder__delete', 'integer,boolean', 'folder_id,cascade_p'),
            ('content_folder__edit_name', 'integer,varchar,varchar,varchar', 'folder_id,name,label,description'),
            ('content_folder__get_index_page', 'integer', 'folder_id'),
            ('content_folder__get_label', 'integer', 'folder_id'),
            ('content_folder__is_registered', 'integer,varchar,boolean', 'folder_id,content_type,include_subtypes'),
            ('content_folder__is_root', 'integer', 'folder_id'),
            ('content_folder__move', 'integer,integer,varchar', 'folder_id,target_folder_id,name'),
            ('content_folder__new', 'varchar,varchar,varchar,integer,integer,integer,timestamptz,integer,varchar,boolean,integer', 'name,label,description,parent_id,context_id,folder_id,creation_date,creation_user,creation_ip,security_inherit_p,package_id'),
            ('content_folder__unregister_content_type', 'integer,varchar,boolean', 'folder_id,content_type,include_subtypes'),
            ('content_item__copy2', 'integer,integer,integer,varchar', 'item_id,target_folder_id,creation_user,creation_ip'),
            ('content_item__delete', 'integer', 'item_id'),
            ('content_item__edit_name', 'integer,varchar', 'item_id,name'),
            ('content_item__get_best_revision', 'integer', 'item_id'),
            ('content_item__get_content_type', 'integer', 'item_id'),
            ('content_item__get_context', 'integer', 'item_id'),
            ('content_item__get_id', 'varchar,integer,boolean', 'item_path,root_folder_id,resolve_index'),
            ('content_item__get_latest_revision', 'integer', 'item_id'),
            ('content_item__get_live_revision', 'integer', 'item_id'),
            ('content_item__get_parent_folder', 'integer', 'item_id'),
            ('content_item__get_publish_date', 'integer,boolean', 'item_id,is_live'),
            ('content_item__get_revision_count', 'integer', 'item_id'),
            ('content_item__get_root_folder', 'integer', 'item_id'),
            ('content_item__get_template', 'integer,varchar', 'item_id,use_context'),
            ('content_item__is_index_page', 'integer,integer', 'item_id,folder_id'),
            ('content_item__is_published', 'integer', 'item_id'),
            ('content_item__is_subclass', 'varchar,varchar', 'object_type,supertype'),
            ('content_item__register_template', 'integer,integer,varchar', 'item_id,template_id,use_context'),
            ('content_item__relate', 'integer,integer,varchar,integer,varchar', 'item_id,object_id,relation_tag,order_n,relation_type'),
            ('content_item__set_release_period', 'integer,timestamptz,timestamptz', 'item_id,start_when,end_when'),
            ('content_item__unregister_template', 'integer,integer,varchar', 'item_id,template_id,use_context'),
            ('content_item__unrelate', 'integer', 'rel_id'),
            ('content_item__unset_live_revision', 'integer', 'item_id'),
            ('content_item__write_to_file', 'integer,varchar', 'item_id,root_path'),
            ('content_keyword__del', 'integer', 'keyword_id'),
            ('content_keyword__delete', 'integer', 'keyword_id'),
            ('content_keyword__get_description', 'integer', 'keyword_id'),
            ('content_keyword__get_heading', 'integer', 'keyword_id'),
            ('content_keyword__get_path', 'integer', 'keyword_id'),
            ('content_keyword__is_leaf', 'integer', 'keyword_id'),
            ('content_keyword__item_assign', 'integer,integer,integer,integer,varchar', 'item_id,keyword_id,context_id,creation_user,creation_ip'),
            ('content_keyword__item_unassign', 'integer,integer', 'item_id,keyword_id'),
            ('content_keyword__new', 'varchar,varchar,integer,integer,timestamptz,integer,varchar,varchar,integer', 'heading,description,parent_id,keyword_id,creation_date,creation_user,creation_ip,object_type,package_id'),
            ('content_keyword__set_description', 'integer,varchar', 'keyword_id,description'),
            ('content_keyword__set_heading', 'integer,varchar', 'keyword_id,heading'),
            ('content_revision__copy_attributes', 'varchar,integer,integer', 'content_type,revision_id,copy_id'),
            ('content_revision__delete', 'integer', 'revision_id'),
            ('content_revision__is_latest', 'integer', 'revision_id'),
            ('content_revision__is_live', 'integer', 'revision_id'),
            ('content_revision__revision_name', 'integer', 'revision_id'),
            ('content_revision__to_html', 'integer', 'revision_id'),
            ('content_revision__to_temporary_clob', 'integer', 'revision_id'),
            ('content_symlink__del', 'integer', 'symlink_id'),
            ('content_symlink__delete', 'integer', 'symlink_id'),
            ('content_symlink__is_symlink', 'integer', 'item_id'),
            ('content_symlink__resolve', 'integer', 'item_id'),
            ('content_symlink__resolve_content_type', 'integer', 'item_id'),
            ('content_template__del', 'integer', 'template_id'),
            ('content_template__delete', 'integer', 'template_id'),
            ('content_template__get_path', 'integer,integer', 'template_id,root_folder_id'),
            ('content_template__is_template', 'integer', 'template_id'),
            ('content_template__new', 'varchar,integer,integer,timestamptz,integer,varchar,text,bool', 'name,parent_id,template_id,creation_date,creation_user,creation_ip,text,is_live'),
            ('content_type__create_attribute', 'varchar,varchar,varchar,varchar,varchar,integer,varchar,varchar', 'content_type,attribute_name,datatype,pretty_name,pretty_plural,sort_order,default_value,column_spec'),
            ('content_type__create_type', 'varchar,varchar,varchar,varchar,varchar,varchar,varchar', 'content_type,supertype,pretty_name,pretty_plural,table_name,id_column,name_method'),
            ('content_type__drop_attribute', 'varchar,varchar,boolean', 'content_type,attribute_name,drop_column'),
            ('content_type__get_template', 'varchar,varchar', 'content_type,use_context'),
            ('content_type__is_content_type', 'varchar', 'object_type'),
            ('content_type__register_child_type', 'varchar,varchar,varchar,integer,integer', 'parent_type,child_type,relation_tag,min_n,max_n'),
            ('content_type__register_mime_type', 'varchar,varchar', 'content_type,mime_type'),
            ('content_type__register_relation_type', 'varchar,varchar,varchar,integer,integer', 'content_type,target_type,relation_tag,min_n,max_n'),
            ('content_type__register_template', 'varchar,integer,varchar,boolean', 'content_type,template_id,use_context,is_default'),
            ('content_type__rotate_template', 'integer,varchar,varchar', 'template_id,v_content_type,use_context'),
            ('content_type__set_default_template', 'varchar,integer,varchar', 'content_type,template_id,use_context'),
            ('content_type__trigger_insert_statement', 'varchar', 'content_type'),
            ('content_type__unregister_child_type', 'varchar,varchar,varchar', 'parent_type,child_type,relation_tag'),
            ('content_type__unregister_mime_type', 'varchar,varchar', 'content_type,mime_type'),
            ('content_type__unregister_relation_type', 'varchar,varchar,varchar', 'content_type,target_type,relation_tag'),
            ('content_type__unregister_template', 'varchar,integer,varchar', 'content_type,template_id,use_context')
        )
        select p.oid, n.nspname, p.proname, arguments.signature
          from expected e
          join pg_proc p on p.oid = to_regprocedure(
              format('%I.%I(%s)', current_schema(), e.function_name, e.input_types))
          join pg_namespace n on n.oid = p.pronamespace
          cross join lateral (
              select string_agg(
                         format('%I %s', 'arg_' || a.arg_name, format_type(a.type_oid, null)),
                         ', ' order by a.position) as signature
                from unnest(p.proargtypes::oid[], string_to_array(e.input_names, ','))
                     with ordinality as a(type_oid, arg_name, position)
          ) arguments
         where p.prokind = 'f'
           and p.proargnames is null
           and p.proargmodes is null
           and p.pronargdefaults = 0
           and p.pronargs = cardinality(string_to_array(e.input_names, ','))
           and p.pronargs = (
               select count(*) from acs_function_args a
                where a.function = upper(e.function_name)
           )
           and e.input_names = (
               select string_agg(lower(a.arg_name), ',' order by a.arg_seq)
                 from acs_function_args a
                where a.function = upper(e.function_name)
           )
           and not exists (
               select 1 from pg_proc other
                where other.proname = p.proname
                  and other.pronargs = p.pronargs
                  and other.oid <> p.oid
           )
    loop
        definition := pg_get_functiondef(target.oid);
        execute format('CREATE OR REPLACE FUNCTION %I.%I(%s)',
                       target.nspname, target.proname, target.signature)
                || substr(definition, strpos(definition, chr(10)));
    end loop;
end;
$$;
