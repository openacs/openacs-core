-- Whoever added package_id forgot to add it to this call...

select define_function_args('content_item__new','name,parent_id,item_id,locale,creation_date;now,creation_user,context_id,creation_ip,item_subtype;content_item,content_type;content_revision,title,description,mime_type;text/plain,nls_language,text,data,relation_tag,is_live;f,storage_type;lob,package_id');

