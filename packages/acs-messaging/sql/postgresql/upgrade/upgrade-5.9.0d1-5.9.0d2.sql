
select define_function_args('acs_message__delete','message_id');
select define_function_args('acs_message__delete_extlink','extlink_id');
select define_function_args('acs_message__delete_file','file_id');
select define_function_args('acs_message__delete_image','image_id');
select define_function_args('acs_message__edit','message_id,title;null,description;null,mime_type;text/plain,text;null,data;null,creation_date;sysdate,creation_user;null,creation_ip;null,is_live;t');
select define_function_args('acs_message__edit_extlink','extlink_id,url,label;null,description');
select define_function_args('acs_message__edit_file','file_id,title;null,description;null,mime_type;text/plain,data;null,creation_date;sysdate,creation_user;null,creation_ip;null,is_live;t');
select define_function_args('acs_message__edit_image','image_id,title;null,description;null,mime_type;text/plain,data;null,width;null,height;null,creation_date;sysdate,creation_user;null,creation_ip;null,is_live;t');
select define_function_args('acs_message__first_ancestor','message_id');
select define_function_args('acs_message__message_p','message_id');
select define_function_args('acs_message__name','message_id');
select define_function_args('acs_message__new','message_id,reply_to,sent_date,sender,rfc822_id,title,description,mime_type,text,data,parent_id,context_id,creation_user,creation_ip,object_type,is_live,package_id');
select define_function_args('acs_message__new_extlink','name;null,extlink_id;null,url,label;null,description;null,parent_id,creation_date;sysdate,creation_user;null,creation_ip;null,package_id;null');
select define_function_args('acs_message__new_file','message_id,file_id;null,file_name,title;null,description;null,mime_type;text/plain,data;null,creation_date;sysdate,creation_user;null,creation_ip;null,is_live;t,storage_type;file,package_id;null');
select define_function_args('acs_message__new_image','message_id,image_id;null,file_name,title;null,description;null,mime_type;text/plain,data;null,width;null,height;null,creation_date;sysdate,creation_user;null,creation_ip;null,is_live;t,storage_type;file,package_id;null');
select define_function_args('acs_message__send','message_id,recipient_id,grouping_id;null,wait_until;sysdate');
select define_function_args('acs_message_get_tree_sortkey','message_id');
