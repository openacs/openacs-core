-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2004-01-22
-- @cvs-id $Id

@@ ../packages-create.sql

-- OpenOffice MIME types

insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Spreadsheet'   , 'application/vnd.sun.xml.calc', 'sxc');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Spreadsheet Template', 'application/vnd.sun.xml.calc.template', 'stc');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Draw', 'application/vnd.sun.xml.draw', 'sxd');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Draw Template', 'application/vnd.sun.xml.draw.template', 'std');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Impress', 'application/vnd.sun.xml.impress', 'sxi');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Impress Template', 'application/vnd.sun.xml.impress.template', 'sti');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Math', 'application/vnd.sun.xml.math', 'sxm');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Writer', 'application/vnd.sun.xml.writer', 'sxw');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Writer Global', 'application/vnd.sun.xml.writer.global', 'sxg');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Writer Template', 'application/vnd.sun.xml.writer.template', 'stw');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxc', 'application/vnd.sun.xml.calc');
insert into cr_extension_mime_type_map (extension, mime_type) values ('stc', 'application/vnd.sun.xml.calc.template');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxd', 'application/vnd.sun.xml.draw');
insert into cr_extension_mime_type_map (extension, mime_type) values ('std', 'application/vnd.sun.xml.draw.template');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxi', 'application/vnd.sun.xml.impress');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sti', 'application/vnd.sun.xml.impress.template');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxm', 'application/vnd.sun.xml.math');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxw', 'application/vnd.sun.xml.writer');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxg', 'application/vnd.sun.xml.writer.global');
insert into cr_extension_mime_type_map (extension, mime_type) values ('stw', 'application/vnd.sun.xml.writer.template');
