-- define additional plpgsql 

select define_function_args('content_item__delete','item_id');

select define_function_args('content_item__copy','item_id,target_folder_id,creation_user,creation_ip;null,name;null');
