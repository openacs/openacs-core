insert into cr_mime_types (label,mime_type,file_extension)
       select 'Image SVG', 'image/svg+xml', 'svg' from dual
       where not exists (select 1 from cr_mime_types where mime_type = 'image/svg+xml');
       
update cr_revisions set mime_type = 'image/svg+xml' where mime_type = 'image/xml+svg';
update cr_content_mime_type_map set mime_type = 'image/svg+xml' where mime_type = 'image/xml+svg';

delete from cr_extension_mime_type_map where extension = 'svg';
delete from cr_mime_types where mime_type = 'image/xml+svg';

insert into cr_extension_mime_type_map (extension, mime_type) 
       select 'svg', 'image/svg+xml' from dual 
       where not exists (select 1 from cr_extension_mime_type_map where mime_type = 'image/svg+xml');
