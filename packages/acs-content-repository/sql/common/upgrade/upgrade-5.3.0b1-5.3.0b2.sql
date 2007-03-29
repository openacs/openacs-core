-- Add a few common mime types
insert into cr_mime_types (label,mime_type,file_extension) values ('XPInstall', 'application/x-xpinstall', 'xpi'); 
insert into cr_mime_types (label,mime_type,file_extension) values ('Video MP4', 'video/mp4', 'mp4');

insert into cr_mime_types (label,mime_type,file_extension) 
select 'Video MP4', 'video/mp4', 'mp4' from dual 
where not exists (select 1 from cr_mime_types where mime_type = 'video/mp4');

insert into cr_extension_mime_type_map (extension, mime_type) 
select 'mp4', 'video/mp4' from dual 
where not exists (select 1 from cr_extension_mime_type_map where mime_type = 'video/mp4');

insert into cr_mime_types (label,mime_type,file_extension) 
select 'XPInstall', 'application/x-xpinstall', 'xpi' from dual 
where not exists (select 1 from cr_mime_types where mime_type = 'application/x-xpinstall');

insert into cr_extension_mime_type_map (extension, mime_type) 
select 'xpi', 'application/x-xpinstall' from dual 
where not exists (select 1 from cr_extension_mime_type_map where mime_type = 'application/x-xpinstall');