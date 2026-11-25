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
            ('acs__add_user', 'integer,varchar,timestamptz,integer,varchar,integer,varchar,varchar,varchar,varchar,varchar,character,character,varchar,boolean,varchar', 'user_id,object_type,creation_date,creation_user,creation_ip,authority_id,username,email,url,first_names,last_name,password,salt,screen_name,email_verified_p,member_state'),
            ('acs__magic_object_id', 'varchar', 'name'),
            ('acs__remove_user', 'integer', 'user_id'),
            ('acs_attribute__add_description', 'varchar,varchar,varchar,text', 'object_type,attribute_name,description_key,description'),
            ('acs_attribute__create_attribute', 'varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer,integer,varchar,boolean,boolean,varchar,varchar,boolean,varchar,varchar,varchar', 'object_type,attribute_name,datatype,pretty_name,pretty_plural,table_name,column_name,default_value,min_n_values,max_n_values,sort_order,storage,static_p,create_column_p,database_type,size,null_p,references,check_expr,column_spec'),
            ('acs_attribute__drop_attribute', 'varchar,varchar,boolean', 'object_type,attribute_name,drop_column_p'),
            ('acs_attribute__drop_description', 'varchar,varchar,varchar', 'object_type,attribute_name,description_key'),
            ('acs_datatype__date_output_function', 'text', 'attribute_name'),
            ('acs_datatype__timestamp_output_function', 'text', 'attribute_name'),
            ('acs_group__check_representation', 'integer', 'group_id'),
            ('acs_group__name', 'integer', 'group_id'),
            ('acs_group__new', 'integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,varchar,integer', 'group_id,object_type,creation_date,creation_user,creation_ip,email,url,group_name,join_policy,context_id'),
            ('acs_object__check_object_ancestors', 'integer,integer,integer', 'object_id,ancestor_id,n_generations'),
            ('acs_object__check_object_descendants', 'integer,integer,integer', 'object_id,descendant_id,n_generations'),
            ('acs_object__check_path', 'integer,integer', 'object_id,ancestor_id'),
            ('acs_object__default_name', 'integer', 'object_id'),
            ('acs_object__get_attr_storage_column', 'text', 'v_vals'),
            ('acs_object__get_attr_storage_sql', 'text', 'v_vals'),
            ('acs_object__get_attr_storage_table', 'text', 'v_vals'),
            ('acs_object__get_attribute', 'integer,varchar', 'object_id_in,attribute_name_in'),
            ('acs_object__get_attribute_storage', 'integer,varchar', 'object_id_in,attribute_name_in'),
            ('acs_object__initialize_attributes', 'integer', 'object_id'),
            ('acs_object__package_id', 'integer', 'object_id'),
            ('acs_object__update_last_modified', 'integer,integer,varchar,timestamptz', 'object_id,modifying_user,modifying_ip,last_modified'),
            ('acs_object_type__create_type', 'varchar,varchar,varchar,varchar,varchar,varchar,varchar,boolean,varchar,varchar,boolean,boolean', 'object_type,pretty_name,pretty_plural,supertype,table_name,id_column,package_name,abstract_p,type_extension_table,name_method,create_table_p,dynamic_p'),
            ('acs_object_type__drop_type', 'varchar,boolean,boolean', 'object_type,drop_children_p,drop_table_p'),
            ('acs_object_type__is_subtype_p', 'varchar,varchar', 'object_type_1,object_type_2'),
            ('acs_object_type__pretty_name', 'varchar', 'object_type'),
            ('acs_object_type_get_tree_sortkey', 'varchar', 'object_type'),
            ('acs_object_util__get_object_type', 'integer', 'object_id'),
            ('acs_object_util__object_ancestor_type_p', 'integer,varchar', 'object_id,object_type'),
            ('acs_object_util__object_type_p', 'integer,varchar', 'object_id,object_type'),
            ('acs_object_util__type_ancestor_type_p', 'varchar,varchar', 'object_type1,object_type2'),
            ('acs_privilege__add_child', 'varchar,varchar', 'privilege,child_privilege'),
            ('acs_privilege__create_privilege', 'varchar,varchar,varchar', 'privilege,pretty_name,pretty_plural'),
            ('acs_privilege__drop_privilege', 'varchar', 'privilege'),
            ('acs_privilege__remove_child', 'varchar,varchar', 'privilege,child_privilege'),
            ('acs_rel__delete', 'integer', 'rel_id'),
            ('acs_rel__new', 'integer,varchar,integer,integer,integer,integer,varchar', 'rel_id,rel_type,object_id_one,object_id_two,context_id,creation_user,creation_ip'),
            ('acs_rel_type__create_role', 'varchar,varchar,varchar', 'role,pretty_name,pretty_plural'),
            ('acs_rel_type__drop_role', 'varchar', 'role'),
            ('acs_rel_type__drop_type', 'varchar,boolean', 'rel_type,cascade_p'),
            ('acs_rel_type__role_pretty_name', 'varchar', 'role'),
            ('acs_rel_type__role_pretty_plural', 'varchar', 'role'),
            ('acs_user__approve_email', 'integer', 'user_id'),
            ('acs_user__delete', 'integer', 'user_id'),
            ('acs_user__unapprove_email', 'integer', 'user_id'),
            ('admin_rel__delete', 'integer', 'rel_id'),
            ('admin_rel__new', 'integer,varchar,integer,integer,varchar,integer,varchar', 'rel_id,rel_type,object_id_one,object_id_two,member_state,creation_user,creation_ip'),
            ('authority__del', 'integer', 'authority_id'),
            ('authority__new', 'integer,varchar,varchar,varchar,boolean,integer,integer,integer,varchar,varchar,integer,varchar,varchar,integer,varchar,integer', 'authority_id,object_type,short_name,pretty_name,enabled_p,sort_order,auth_impl_id,pwd_impl_id,forgotten_pwd_url,change_pwd_url,register_impl_id,register_url,help_contact_text,creation_user,creation_ip,context_id'),
            ('composition_rel__check_index', 'integer,integer', 'component_id,container_id'),
            ('composition_rel__check_path_exists_p', 'integer,integer', 'component_id,container_id'),
            ('composition_rel__check_representation', 'integer', 'rel_id'),
            ('composition_rel__delete', 'integer', 'rel_id'),
            ('composition_rel__new', 'integer,varchar,integer,integer,integer,varchar', 'rel_id,rel_type,object_id_one,object_id_two,creation_user,creation_ip'),
            ('define_function_args', 'varchar,varchar', 'function,arg_list'),
            ('get_func_drop_command', 'varchar', 'fname'),
            ('get_func_header', 'varchar,oidvector', 'fname,args'),
            ('group_contains_p', 'integer,integer,integer', 'group_id,component_id,rel_id'),
            ('instr', 'varchar,character,integer,integer', 'str,pat,dir,cnt'),
            ('journal_entry__delete', 'integer', 'journal_id'),
            ('journal_entry__delete_for_object', 'integer', 'object_id'),
            ('journal_entry__new', 'integer,integer,varchar,varchar,timestamptz,integer,varchar,varchar', 'journal_id,object_id,action,action_pretty,creation_date,creation_user,creation_ip,msg'),
            ('lob_copy', 'integer,integer', 'from_id,to_id'),
            ('lob_get_data', 'integer', 'lob_id'),
            ('lob_length', 'integer', 'id'),
            ('membership_rel__approve', 'integer', 'rel_id'),
            ('membership_rel__ban', 'integer', 'rel_id'),
            ('membership_rel__check_index', 'integer,integer,integer', 'group_id,member_id,container_id'),
            ('membership_rel__check_representation', 'integer', 'rel_id'),
            ('membership_rel__delete', 'integer', 'rel_id'),
            ('membership_rel__deleted', 'integer', 'rel_id'),
            ('membership_rel__merge', 'integer', 'rel_id'),
            ('membership_rel__new', 'integer,varchar,integer,integer,varchar,integer,varchar', 'rel_id,rel_type,object_id_one,object_id_two,member_state,creation_user,creation_ip'),
            ('membership_rel__reject', 'integer', 'rel_id'),
            ('membership_rel__unapprove', 'integer', 'rel_id'),
            ('number_src', 'text', 'v_src'),
            ('party__delete', 'integer', 'party_id'),
            ('party__email', 'integer', 'party_id'),
            ('party__name', 'integer', 'party_id'),
            ('party__new', 'integer,varchar,timestamptz,integer,varchar,varchar,varchar,integer', 'party_id,object_type,creation_date,creation_user,creation_ip,email,url,context_id'),
            ('party_approved_member__add', 'integer,integer,integer,varchar', 'party_id,member_id,rel_id,rel_type'),
            ('party_approved_member__remove', 'integer,integer,integer,varchar', 'party_id,member_id,rel_id,rel_type'),
            ('person__delete', 'integer', 'person_id'),
            ('person__first_names', 'integer', 'person_id'),
            ('person__last_name', 'integer', 'person_id'),
            ('person__name', 'integer', 'person_id'),
            ('person__new', 'integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,varchar,integer', 'person_id,object_type,creation_date,creation_user,creation_ip,email,url,first_names,last_name,context_id'),
            ('rel_constraint__delete', 'integer', 'constraint_id'),
            ('rel_constraint__get_constraint_id', 'integer,character,integer', 'rel_segment,rel_side,required_rel_segment'),
            ('rel_constraint__new', 'integer,varchar,varchar,integer,character,integer,integer,integer,varchar', 'constraint_id,constraint_type,constraint_name,rel_segment,rel_side,required_rel_segment,context_id,creation_user,creation_ip'),
            ('rel_constraint__violation', 'integer', 'rel_id'),
            ('rel_constraint__violation_if_removed', 'integer', 'rel_id'),
            ('rel_segment__delete', 'integer', 'segment_id'),
            ('rel_segment__get', 'integer,varchar', 'group_id,rel_type'),
            ('rel_segment__get_or_new', 'integer,varchar,varchar', 'group_id,rel_type,segment_name'),
            ('rel_segment__name', 'integer', 'segment_id'),
            ('rel_segment__new', 'integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,integer,varchar,integer', 'segment_id,object_type,creation_date,creation_user,creation_ip,email,url,segment_name,group_id,rel_type,context_id'),
            ('site_node__delete', 'integer', 'node_id'),
            ('site_node__find_pattern', 'integer', 'node_id'),
            ('site_node__new', 'integer,integer,varchar,integer,boolean,boolean,integer,varchar', 'node_id,parent_id,name,object_id,directory_p,pattern_p,creation_user,creation_ip'),
            ('site_node_object_map__del', 'integer', 'object_id'),
            ('site_node_object_map__new', 'integer,integer', 'object_id,node_id'),
            ('split', 'varchar,character,integer', 'string,split_char,element'),
            ('tree_ancestor_key', 'varbit,integer', 'tree_key,level'),
            ('tree_ancestor_p', 'varbit,varbit', 'potential_ancestor,potential_child'),
            ('tree_increment_key', 'varbit', 'child_sort_key'),
            ('tree_left', 'varbit', 'key'),
            ('tree_level', 'varbit', 'tree_key'),
            ('tree_next_key', 'varbit,integer', 'parent_key,child_value'),
            ('tree_right', 'varbit', 'key'),
            ('tree_root_key', 'varbit', 'tree_key'),
            ('trigger_type', 'integer', 'tgtype'),
            ('util__logical_negation', 'boolean', 'true_or_false'),
            ('util__multiple_nextval', 'varchar,integer', 'v_sequence_name,v_count')
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
           and not exists (
               select 1 from acs_function_args a
                where a.function = upper(e.function_name)
                  and (a.arg_seq < 1 or a.arg_seq > p.pronargs)
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
