-- getting rid of backslashes using for escaping

--
-- procedure drop_package/1
--
CREATE OR REPLACE FUNCTION drop_package(
   package_name varchar
) RETURNS varchar AS $$
DECLARE
       v_rec             record;
       v_drop_cmd        varchar;
       v_pkg_name        varchar;
BEGIN
        raise NOTICE 'DROP PACKAGE: %', package_name;
        v_pkg_name := package_name || '__' || '%';

        for v_rec in select proname 
                       from pg_proc 
                      where proname like v_pkg_name 
                   order by proname 
        LOOP
            raise NOTICE 'DROPPING FUNCTION: %', v_rec.proname;
            v_drop_cmd := get_func_drop_command (v_rec.proname::varchar);
            EXECUTE v_drop_cmd;
        end loop;

        if NOT FOUND then 
          raise NOTICE 'PACKAGE: % NOT FOUND', package_name;
        else
          raise NOTICE 'PACKAGE: %: DROPPED', package_name;
        end if;
        
        return null;

END;
$$ LANGUAGE plpgsql;



--
-- procedure get_func_definition/2
--
CREATE OR REPLACE FUNCTION get_func_definition(
   fname varchar,
   args oidvector
) RETURNS text AS $$
DECLARE
        nargs           integer default 0;
        v_pos           integer;
        v_funcdef       text default '';
        v_args          varchar;
        v_one_arg       varchar;
        v_one_type      varchar;
        v_nargs         integer;
        v_src           text;
        v_rettype       varchar;
BEGIN
        select proargtypes, pronargs, number_src(prosrc), 
               (select typname from pg_type where oid = p.prorettype::integer)
          into v_args, v_nargs, v_src, v_rettype
          from pg_proc p 
         where proname = fname::name
           and proargtypes = args;

         v_funcdef := v_funcdef || '
create or replace function ' || fname || '(';

         v_pos := position(' ' in v_args);

         while nargs < v_nargs loop
             nargs := nargs + 1;
             if nargs = v_nargs then 
                 v_one_arg := v_args;
                 v_args    := '';
             else
                 v_one_arg := substr(v_args, 1, v_pos - 1);
                 v_args    := substr(v_args, v_pos + 1);
                 v_pos     := position(' ' in v_args);            
             end if;
             select case when nargs = 1 
                           then typname 
                           else ',' || typname 
                         end into v_one_type 
               from pg_type 
              where oid = v_one_arg::integer;
             v_funcdef := v_funcdef || v_one_type;
         end loop;
         v_funcdef := v_funcdef || ') returns ' || v_rettype || E' as ''\n' || v_src || ''' language ''plpgsql'';';

        return v_funcdef;

END;
$$ LANGUAGE plpgsql stable strict;

-- geting right definition of function's arguments 

select define_function_args('acs__add_user','user_id;null,object_type;user,creation_date;now(),creation_user;null,creation_ip;null,authority_id,username,email,url;null,first_names,last_name,password,salt,screen_name;null,email_verified_p;t,member_state;approved');
select define_function_args('acs__remove_user','user_id');
select define_function_args('acs__magic_object_id','name');
select define_function_args('acs_log__notice','log_key,message');
select define_function_args('acs_log__warn','log_key,message');
select define_function_args('acs_log__error','log_key,message');
select define_function_args('acs_log__debug','log_key,message');
select define_function_args('acs_object_type_get_tree_sortkey','object_type');
select define_function_args('acs_object_type__create_type','object_type,pretty_name,pretty_plural,supertype,table_name;null,id_column;null,package_name;null,abstract_p;f,type_extension_table;null,name_method;null,create_table_p;f,dynamic_p;f');
select define_function_args('acs_object_type__drop_type','object_type,drop_children_p;f,drop_table_p;f');
select define_function_args('acs_object_type__pretty_name','object_type');
select define_function_args('acs_object_type__is_subtype_p','object_type_1,object_type_2');
select define_function_args('acs_attribute__create_attribute','object_type,attribute_name,datatype,pretty_name,pretty_plural;null,table_name;null,column_name;null,default_value;null,min_n_values;1,max_n_values;1,sort_order;null,storage;type_specific,static_p;f,create_column_p;f,database_type;null,size;null,null_p;t,references;null,check_expr;null,column_spec;null');
select define_function_args('acs_attribute__drop_attribute','object_type,attribute_name,drop_column_p;f');
select define_function_args('acs_attribute__add_description','object_type,attribute_name,description_key,description');
select define_function_args('acs_attribute__drop_description','object_type,attribute_name,description_key');
select define_function_args('acs_datatype__date_output_function','attribute_name');
select define_function_args('acs_datatype__timestamp_output_function','attribute_name');
select define_function_args('acs_objects_get_tree_sortkey','object_id');
select define_function_args('acs_object__initialize_attributes','initialize_attributes__object_id');
select define_function_args('acs_object__new','object_id;null,object_type;acs_object,creation_date;now(),creation_user;null,creation_ip;null,context_id;null,security_inherit_p;t,title;null,package_id;null');
select define_function_args('acs_object__delete','object_id');
select define_function_args('acs_object__name','name__object_id');
select define_function_args('acs_object__default_name','default_name__object_id');
select define_function_args('acs_object__object_id','p_object_id');
select define_function_args('acs_object__package_id','object_id');
select define_function_args('acs_object__get_attribute_storage','object_id_in,attribute_name_in');
select define_function_args('acs_object__get_attr_storage_column','v_vals');
select define_function_args('acs_object__get_attr_storage_table','v_vals');
select define_function_args('acs_object__get_attr_storage_sql','v_vals');
select define_function_args('acs_object__get_attribute','object_id_in,attribute_name_in');
select define_function_args('acs_object__set_attribute','object_id_in,attribute_name_in,value_in');
select define_function_args('acs_object__check_context_index','check_context_index__object_id,check_context_index__ancestor_id,check_context_index__n_generations');
select define_function_args('acs_object__check_object_ancestors','object_id,ancestor_id,n_generations');
select define_function_args('acs_object__check_object_descendants','object_id,descendant_id,n_generations');
select define_function_args('acs_object__check_path','check_path__object_id,check_path__ancestor_id');
select define_function_args('acs_object__check_representation','check_representation__object_id');
select define_function_args('acs_object__update_last_modified','update_last_modified__object_id,update_last_modified__modifying_user,update_last_modified__modifying_ip,update_last_modified__last_modified;now()');
select define_function_args('acs_object_util__object_type_exist_p','object_type');
select define_function_args('acs_object_util__get_object_type','object_id');
select define_function_args('acs_object_util__type_ancestor_type_p','object_type1,object_type2');
select define_function_args('acs_object_util__object_ancestor_type_p','object_id,object_type');
select define_function_args('acs_object_util__object_type_p','object_id,object_type');
select define_function_args('priv_recurse_subtree','nkey,child_priv');
select define_function_args('acs_privilege__create_privilege','privilege,pretty_name;null,pretty_plural;null');
select define_function_args('acs_privilege__drop_privilege','privilege');
select define_function_args('acs_privilege__add_child','privilege,child_privilege');
select define_function_args('acs_privilege__remove_child','privilege,child_privilege');
select define_function_args('acs_permission__grant_permission','object_id,grantee_id,privilege');
select define_function_args('acs_permission__revoke_permission','object_id,grantee_id,privilege');
select define_function_args('acs_permission__permission_p','object_id,party_id,privilege');
select define_function_args('acs_rel_type__create_role','role,pretty_name;null,pretty_plural;null');
select define_function_args('acs_rel_type__drop_role','role');
select define_function_args('acs_rel_type__role_pretty_name','role');
select define_function_args('acs_rel_type__role_pretty_plural','role');
select define_function_args('acs_rel_type__create_type','rel_type,pretty_name,pretty_plural,supertype;relationship,table_name,id_column,package_name,object_type_one,role_one;null,min_n_rels_one,max_n_rels_one,object_type_two,role_two;null,min_n_rels_two,max_n_rels_two');
select define_function_args('acs_rel_type__drop_type','rel_type,cascade_p;f');
select define_function_args('acs_rel__new','rel_id;null,rel_type;relationship,object_id_one,object_id_two,context_id;null,creation_user;null,creation_ip;null');
select define_function_args('acs_rel__delete','rel_id');
select define_function_args('apm__register_package','package_key,pretty_name,pretty_plural,package_uri,package_type,initial_install_p;f,singleton_p;f,implements_subsite_p;f,inherit_templates_p;f,spec_file_path;null,spec_file_mtime;null');
select define_function_args('apm__update_package','package_key,pretty_name;null,pretty_plural;null,package_uri;null,package_type;null,initial_install_p;null,singleton_p;null,implements_subsite_p;f,inherit_templates_p;f,spec_file_path;null,spec_file_mtime;null');
select define_function_args('apm__unregister_package','package_key,cascade_p;t');
select define_function_args('apm__register_p','package_key');
select define_function_args('apm__register_application','package_key,pretty_name,pretty_plural,package_uri,initial_install_p;f,singleton_p;f,implements_subsite_p;f,inherit_templates_p;f,spec_file_path;null,spec_file_mtime;null');
select define_function_args('apm__unregister_application','package_key,cascade_p;f');
select define_function_args('apm__register_service','package_key,pretty_name,pretty_plural,package_uri,initial_install_p;f,singleton_p;f,implements_subsite_p;f,inherit_templates_p;f,spec_file_path;null,spec_file_mtime;null');
select define_function_args('apm__unregister_service','package_key,cascade_p;f');
select define_function_args('apm__register_parameter','parameter_id;null,package_key,parameter_name,description;null,scope,datatype;string,default_value;null,section_name;null,min_n_values;1,max_n_values;1');
select define_function_args('apm__update_parameter','parameter_id,parameter_name;null,description;null,datatype;string,default_value;null,section_name;null,min_n_values;1,max_n_values;1');
select define_function_args('apm__parameter_p','package_key,parameter_name');
select define_function_args('apm__unregister_parameter','parameter_id;null');
select define_function_args('apm__id_for_name','package_key,parameter_name');
select define_function_args('apm__get_value','package_key,parameter_name');
select define_function_args('apm__set_value','package_key,parameter_name,attr_value');
select define_function_args('apm_package__is_child','parent_package_key,child_package_key');
select define_function_args('apm_package__initialize_parameters','package_id,package_key');
select define_function_args('apm_package__new','package_id;null,instance_name;null,package_key,object_type;apm_package,creation_date;now(),creation_user;null,creation_ip;null,context_id;null');
select define_function_args('apm_package__delete','package_id');
select define_function_args('apm_package__initial_install_p','package_key');
select define_function_args('apm_package__singleton_p','package_key');
select define_function_args('apm_package__num_instances','package_key');
select define_function_args('apm_package__name','package_id');
select define_function_args('apm_package__highest_version','package_key');
select define_function_args('apm_package__parent_id','parent_id__package_id');
select define_function_args('apm_package_version__new','version_id;null,package_key,version_name;null,version_uri,summary,description_format,description,release_date,vendor,vendor_uri,auto_mount,installed_p;f,data_model_loaded_p;f');
select define_function_args('apm_package_version__delete','version_id');
select define_function_args('apm_package_version__enable','version_id');
select define_function_args('apm_package_version__disable','version_id');
select define_function_args('apm_package_version__copy','version_id,new_version_id;null,new_version_name,new_version_uri,copy_owners_p');
select define_function_args('apm_package_version__edit','new_version_id;null,version_id,version_name;null,version_uri,summary,description_format,description,release_date,vendor,vendor_uri,auto_mount,installed_p;f,data_model_loaded_p;f');
select define_function_args('apm_package_version__add_interface','interface_id;null,version_id,interface_uri,interface_version');
select define_function_args('apm_package_version__remove_interface','interface_uri,interface_version,version_id');
select define_function_args('apm_package_version__add_dependency','dependency_type,dependency_id;null,version_id,dependency_uri,dependency_version');
select define_function_args('apm_package_version__remove_dependency','dependency_uri,dependency_version,version_id');
select define_function_args('apm_package_version__sortable_version_name','version_name');
select define_function_args('apm_package_version__version_name_greater','version_name_one,version_name_two');
select define_function_args('apm_package_version__upgrade_p','path,initial_version_name,final_version_name');
select define_function_args('apm_package_version__upgrade','version_id');
select define_function_args('apm_package_type__create_type','package_key,pretty_name,pretty_plural,package_uri,package_type,initial_install_p,singleton_p,implements_subsite_p,inherit_templates_p,spec_file_path;null,spec_file_mtime;null');
select define_function_args('apm_package_type__update_type','package_key,pretty_name;null,pretty_plural;null,package_uri;null,package_type;null,initial_install_p;null,singleton_p;null,implements_subsite_p;null,inherit_templates_p;null,spec_file_path;null,spec_file_mtime;null');
select define_function_args('apm_package_type__drop_type','package_key,cascade_p;f');
select define_function_args('apm_package_type__num_parameters','package_key');
select define_function_args('apm_parameter_value__new','value_id;null,package_id,parameter_id,attr_value');
select define_function_args('apm_parameter_value__delete','value_id;null');
select define_function_args('apm_application__new','application_id;null,instance_name;null,package_key,object_type;apm_application,creation_date;now(),creation_user;null,creation_ip;null,context_id;null');
select define_function_args('apm_application__delete','application_id');
select define_function_args('apm_service__new','service_id;null,instance_name;null,package_key,object_type;apm_service,creation_date;now(),creation_user;null,creation_ip;null,context_id;null');
select define_function_args('apm_service__delete','service_id');
select define_function_args('authority__new','authority_id;null,object_type;authority,short_name,pretty_name,enabled_p;t,sort_order,auth_impl_id;null,pwd_impl_id;null,forgotten_pwd_url;null,change_pwd_url;null,register_impl_id;null,register_url;null,help_contact_text;null,creation_user;null,creation_ip;null,context_id;null');
select define_function_args('authority__del','authority_id');
select define_function_args('party__new','party_id;null,object_type;party,creation_date;now(),creation_user;null,creation_ip;null,email,url;null,context_id;null');
select define_function_args('party__delete','party_id');
select define_function_args('party__name','party_id');
select define_function_args('party__email','party_id');
select define_function_args('person__new','person_id;null,object_type;person,creation_date;now(),creation_user;null,creation_ip;null,email,url;null,first_names,last_name,context_id;null');
select define_function_args('person__delete','person_id');
select define_function_args('person__name','person_id');
select define_function_args('person__first_names','person_id');
select define_function_args('person__last_name','person_id');
select define_function_args('user__new','user_id,object_type;user,creation_date;now(),creation_user,creation_ip,authority_id,username,email,url,first_names,last_name,password,salt,screen_name,email_verified_p;t,context_id');
select define_function_args('acs_user__new','user_id;null,object_type;user,creation_date;now(),creation_user;null,creation_ip;null,authority_id,username,email,url;null,first_names,last_name,password,salt,screen_name;null,email_verified_p;t,context_id;null');
select define_function_args('acs_user__receives_alerts_p','user_id');
select define_function_args('acs_user__approve_email','user_id');
select define_function_args('acs_user__unapprove_email','user_id');
select define_function_args('acs_user__delete','user_id');
select define_function_args('composition_rel__new','rel_id;null,rel_type;composition_rel,object_id_one,object_id_two,creation_user;null,creation_ip;null');
select define_function_args('composition_rel__delete','rel_id');
select define_function_args('composition_rel__check_path_exists_p','component_id,container_id');
select define_function_args('composition_rel__check_index','component_id,container_id');
select define_function_args('composition_rel__check_representation','rel_id');
select define_function_args('membership_rel__new','rel_id;null,rel_type;membership_rel,object_id_one,object_id_two,member_state;approved,creation_user;null,creation_ip;null');
select define_function_args('membership_rel__ban','rel_id');
select define_function_args('membership_rel__approve','rel_id');
select define_function_args('membership_rel__reject','rel_id');
select define_function_args('membership_rel__unapprove','rel_id');
select define_function_args('membership_rel__deleted','rel_id');
select define_function_args('membership_rel__delete','rel_id');
select define_function_args('membership_rel__merge','rel_id');
select define_function_args('membership_rel__check_index','group_id,member_id,container_id');
select define_function_args('membership_rel__check_representation','rel_id');
select define_function_args('acs_group__new','group_id;null,object_type;group,creation_date;now(),creation_user;null,creation_ip;null,email;null,url;null,group_name,join_policy;null,context_id;null');
select define_function_args('acs_group__delete','group_id');
select define_function_args('acs_group__name','group_id');
select define_function_args('acs_group__member_p','party_id,group_id,cascade_membership');
select define_function_args('acs_group__check_representation','group_id');
select define_function_args('admin_rel__new','rel_id;null,rel_type;admin_rel,object_id_one,object_id_two,member_state;approved,creation_user;null,creation_ip;null');
select define_function_args('admin_rel__delete','rel_id');
select define_function_args('group_contains_p','group_id,component_id,rel_id');
select define_function_args('journal_entry__new','journal_id;null,object_id,action,action_pretty;null,creation_date;now(),creation_user;null,creation_ip;null,msg;null');
select define_function_args('journal_entry__delete','journal_id');
select define_function_args('journal_entry__delete_for_object','object_id');
select define_function_args('lob_get_data','lob_id');
select define_function_args('lob_copy','from_id,to_id');
select define_function_args('lob_length','id');
select define_function_args('instr','str,pat,dir,cnt');
select define_function_args('split','string,split_char,element');
select define_function_args('get_func_drop_command','fname');
select define_function_args('drop_package','package_name');
select define_function_args('number_src','v_src');
select define_function_args('get_func_definition','fname,args');
select define_function_args('get_func_header','fname,args');
select define_function_args('int_to_tree_key','intkey');
select define_function_args('tree_key_to_int','tree_key,level');
select define_function_args('tree_ancestor_key','tree_key,level');
select define_function_args('tree_root_key','tree_key');
select define_function_args('tree_leaf_key_to_int','tree_key');
select define_function_args('tree_next_key','parent_key,child_value');
select define_function_args('tree_increment_key','child_sort_key');
select define_function_args('tree_left','key');
select define_function_args('tree_right','key');
select define_function_args('tree_level','tree_key');
select define_function_args('tree_ancestor_p','potential_ancestor,potential_child');
select define_function_args('define_function_args','function,arg_list');
select define_function_args('trigger_type','tgtype');
select define_function_args('rel_constraint__new','constraint_id;null,constraint_type;rel_constraint,constraint_name,rel_segment,rel_side;two,required_rel_segment,context_id;null,creation_user;null,creation_ip;null');
select define_function_args('rel_constraint__delete','constraint_id');
select define_function_args('rel_constraint__get_constraint_id','rel_segment,rel_side,required_rel_segment');
select define_function_args('rel_constraint__violation','rel_id');
select define_function_args('rel_constraint__violation_if_removed','rel_id');
select define_function_args('rel_segment__new','segment_id;null,object_type;rel_segment,creation_date;now(),creation_user;null,creation_ip;null,email;null,url;null,segment_name,group_id,rel_type,context_id;null');
select define_function_args('rel_segment__delete','segment_id');
select define_function_args('rel_segment__get','group_id,rel_type');
select define_function_args('rel_segment__get_or_new','group_id,rel_type,segment_name;null');
select define_function_args('rel_segment__name','segment_id');
select define_function_args('party_approved_member__add_one','party_id,member_id,rel_id');
select define_function_args('party_approved_member__add','party_id,member_id,rel_id,rel_type');
select define_function_args('party_approved_member__remove_one','party_id,member_id,rel_id');
select define_function_args('party_approved_member__remove','party_id,member_id,rel_id,rel_type');
select define_function_args('site_node_object_map__new', 'object_id,node_id');
select define_function_args('site_node_object_map__del', 'object_id');
select define_function_args('site_node_get_tree_sortkey','node_id');
select define_function_args('site_node__new','node_id;null,parent_id;null,name,object_id;null,directory_p,pattern_p;f,creation_user;null,creation_ip;null');
select define_function_args('site_node__delete','node_id');
select define_function_args('site_node__find_pattern','node_id');
select define_function_args('site_node__node_id','url,parent_id;null');
select define_function_args('site_node__url','node_id');
select define_function_args('util__multiple_nextval','v_sequence_name,v_count');
select define_function_args('util__logical_negation','true_or_false');


--- getting triggers right ( names and return values )

CREATE OR REPLACE FUNCTION lobs_delete_tr() RETURNS trigger AS $$
BEGIN
	delete from lob_data where lob_id = old.lob_id;
	return old;
END;
$$ LANGUAGE plpgsql;

create trigger lobs_delete_tr before delete on lobs
for each row execute procedure lobs_delete_tr();

drop trigger lobs_delete_trig on lobs;
drop function on_lobs_delete();
