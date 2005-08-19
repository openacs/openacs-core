-- define additional plpgsql 
select define_function_args('content_item__delete','item_id');
select define_function_args('content_item__copy','item_id,target_folder_id,creation_user,creation_ip,name');
select define_function_args('content_item__get_parent_folder','item_id');
select define_function_args('content_item__unrelate','rel_id');
select define_function_args('content_item__is_index_page','item_id,folder_id');
select define_function_args('content_item__relate','item_id,object_id,relation_tag;generic,order_n,relation_type;cr_item_rel');
select define_function_args('content_item__is_subclass','object_type,supertype');
select define_function_args('content_item__get_publish_date','item_id,is_live;f');
select define_function_args('content_item__get_title','item_id,is_live;f');
select define_function_args('content_item__get_best_revision','item_id');
select define_function_args('content_item__get_latest_revision','item_id');
select define_function_args('content_item__move','item_id,target_folder_id,name');
select define_function_args('content_item__get_context','item_id');
select define_function_args('content_item__get_revision_count','item_id');
select define_function_args('content_item__set_release_period','item_id,start_when,end_when');
select define_function_args('content_item__unset_live_revision','item_id');
select define_function_args('content_item__set_live_revision','revision_id,publish_status;ready');
select define_function_args('content_item__get_live_revision','item_id');
select define_function_args('content_item__get_content_type','item_id');
select define_function_args('content_item__get_template','item_id,use_context');
select define_function_args('content_item__unregister_template','item_id,template_id,use_context');
select define_function_args('content_item__register_template','item_id,template_id,use_context');
select define_function_args('content_item__get_virtual_path','item_id,root_folder_id;-100');
select define_function_args('content_item__get_path','item_id,root_folder_id');
select define_function_args('content_item__get_id','item_path,root_folder_id,resolve_index;f');
select define_function_args('content_item__edit_name','item_id,name');
select define_function_args('content_item__is_valid_child','item_id,content_type,relation_tag');
select define_function_args('content_item__is_publishable','item_id');
select define_function_args('content_item__is_published','item_id');
select define_function_args('content_item__get_root_folder','item_id');

select define_function_args('content_revision__get_content','revision_id');
select define_function_args('content_revision__content_copy','revision_id,revision_id_dest');
select define_function_args('content_revision__is_latest','revision_id');
select define_function_args('content_revision__is_live','revision_id');
select define_function_args('content_revision__to_html','revision_id');
select define_function_args('content_revision__revision_name','revision_id');
select define_function_args('content_revision__get_number','revision_id');
select define_function_args('content_revision__delete','revision_id');
select define_function_args('content_revision__copy','revision_id,copy_id,target_item_id,creation_user,creation_ip');
select define_function_args('content_revision__copy_attributes','content_type,revision_id,copy_id');

select define_function_args('content_type__rotate_template','template_id,content_type,use_context');
select define_function_args('content_type__is_content_type','content_type');
select define_function_args('content_type__unregister_mime_type','content_type,mime_type');
select define_function_args('content_type__register_mime_type','content_type,mime_type');
select define_function_args('content_type__unregister_relation_type','content_type,target_type,relation_tag;generic');
select define_function_args('content_type__register_relation_type','content_type,target_type,relation_tag;generic,min_n;0,max_n');
select define_function_args('content_type__unregister_child_type','content_type,child_type,relation_tag');
select define_function_args('content_type__register_child_type','content_type,child_type,relation_tag;generic,min_n;0,max_n');
select define_function_args('content_type__refresh_view','content_type');
select define_function_args('content_type__refresh_trigger','content_type');
select define_function_args('content_type__trigger_insert_statement','content_type');
select define_function_args('content_type__unregister_template','content_type,template_id,use_context');
select define_function_args('content_type__get_template','content_type,use_context');
select define_function_args('content_type__set_default_template','content_type,template_id,use_context');
select define_function_args('content_type__register_template','content_type,template_id,use_context,is_default;f');



select define_function_args('content_folder__delete','folder_id,cascade_p;f');
select define_function_args('content_folder__register_content_type','folder_id,content_type,include_subtypes;f');
select define_function_args('content_folder__is_root','folder_id');
select define_function_args('content_folder__get_index_page','folder_id');
select define_function_args('content_folder__get_label','folder_id');
select define_function_args('content_folder__is_registered','folder_id,content_type,include_subtypes;f');
select define_function_args('content_folder__unregister_content_type','folder_id,content_type,include_subtypes;f');
select define_function_args('content_folder__is_empty','folder_id');
select define_function_args('content_folder__is_sub_folder','folder_id,target_folder_id');
select define_function_args('content_folder__is_folder','folder_id');
select define_function_args('content_folder__edit_name','folder_id,name,label,description');
select define_function_args('content_folder__move','folder_id,target_folder_id');

select define_function_args('content_template__get_path','template_id,root_folder_id;-100');
select define_function_args('content_template__is_template','template_id');
select define_function_args('content_template__delete','template_id');

select define_function_args('content_symlink__resolve','item_id');
select define_function_args('content_symlink__resolve_content_type','item_id');
select define_function_args('content_symlink__is_symlink','item_id');
select define_function_args('content_symlink__copy','symlink_id,target_folder_id,creation_user,creation_ip,name');
select define_function_args('content_symlink__new','name,label,target_id,parent_id,symlink_id,creation_date;now,creation_user,creation_ip,package_id');

select define_function_args('content_extlink__copy','extlink_id,target_folder_id,creation_user,creation_ip,name');
select define_function_args('content_extlink__is_extlink','item_id');
select define_function_args('content_extlink__delete','extlink_id');
select define_function_args('content_extlink__new','name,url,label,description,parent_id,extlink_id,creation_date;now,creation_user,creation_ip,package_id');

