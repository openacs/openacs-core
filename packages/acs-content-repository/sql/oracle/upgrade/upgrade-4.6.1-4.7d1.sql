-- Upgrade script
--
-- @author Lars Pind <lars@pinds.com>
-- @created 2003-01-27

insert into cr_mime_types(label, mime_type, file_extension) values ('Enhanced text', 'text/enhanced', 'etxt');
insert into cr_mime_types(label, mime_type, file_extension) values ('Fixed-width text', 'text/fixed-width', 'ftxt');
