insert into cr_mime_types(label, mime_type, file_extension) select 'Archive Zip', 'application/x-zip', 'zip' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/x-zip');
insert into cr_mime_types(label, mime_type, file_extension) select 'Shell Script', 'application/x-sh', 'sh' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/x-sh');
insert into cr_mime_types(label, mime_type, file_extension) select 'RDF/XML', 'application/rdf+xml', 'rdf' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/rdf+xml');

create or replace trigger cr_cleanup_cr_files_del_trg
before delete on cr_revisions
for each row
begin
        insert into cr_files_to_delete (
          path, storage_area_key
        ) select :old.filename, i.storage_area_key
            from cr_items i
           where i.item_id = :old.item_id
             and i.storage_type = 'file'
             and :old.filename is not null;

end cr_cleanup_cr_files_del_trg;
/
show errors
