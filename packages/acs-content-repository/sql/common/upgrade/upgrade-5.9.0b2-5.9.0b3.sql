
delete from cr_mime_types where file_extension = 'svg';
insert into cr_mime_types (label,mime_type,file_extension) values ('Image SVG', 'image/svg+xml', 'svg'); 

delete from cr_extension_mime_type_map where extension = 'svg';
insert into cr_extension_mime_type_map (extension, mime_type) 
       select 'svg', 'image/svg+xml' from dual 
       where not exists (select 1 from cr_extension_mime_type_map where mime_type = 'image/svg+xml');
