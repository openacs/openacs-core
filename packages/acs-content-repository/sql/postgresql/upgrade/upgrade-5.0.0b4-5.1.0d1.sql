select define_function_args('content_extlink__new','name;null,url,label;null,description;null,parent_id,extlink_id;null,creation_date;current_timestamp,creation_user;null,creation_ip;null');

select define_function_args('content_folder__new','name,label,description;null,parent_id;null,context_id;null,folder_id;null,creation_date;current_timestamp,creation_user;null,creation_ip;null,security_inherit_p;null');

select define_function_args('content_item__new','name,parent_id;null,item_id;null,locale;null,creation_date;current_timestamp,creation_user;null,context_id;null,creation_ip;null,item_subtype;content_item,content_type;content_revision,title;null,description;null,mime_type;text/plain,nls_language;null,text;null,data;null,relation_tag;null,is_live;f,storage_type;lob');

select define_function_args('content_keyword__new','heading,description;null,parent_id;null,keyword_id;null,creation_date;current_timestamp,creation_user;null,creation_ip;null,object_type;content_keyword');

select define_function_args('content_symlink__new','name;null,label;null,target_id,parent_id,symlink_id;null,creation_date;current_timestamp,creation_user;null,creation_ip;null');

select define_function_args('content_template__new','name,parent_id;null,template_id;null,creation_date;null,creation_user;null,creation_ip;null');

select define_function_args('content_type__create_type','content_type,super_type;content_revision,pretty_name,pretty_plural,table_name;null,id_colum;XXX,name_method;null');

select define_function_args('content_type__create_attribute','content_type,attribute_name,datatype,pretty_name,pretty_plural;null,sort_order;null,default_value;null,column_spec;text');
