--
-- Adds the */* mime type as "Unknown" (added to content-create.sql by lars
--

insert into cr_mime_types(label, mime_type, file_extension) select 'Unkown', '*/*', '' from dual where not exists (select 1 from cr_mime_types where mime_type = '*/*');
