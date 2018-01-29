--
-- Minimal version (compared to postgres update), just adding the entry to cr_mime_types
--
insert into cr_mime_types(label, mime_type, file_extension) values ('Markdown text', 'text/markdown', 'mtxt');
