--
-- Update mime_type to official content type as registered by IANA.
-- The changes have to be performed in a transaction, therefore the inline function.
-- 
create function inline_0 ()
returns integer as $$
begin
  SET CONSTRAINTS ALL DEFERRED;
  delete from cr_extension_mime_type_map where mime_type = 'application/x-shockwave-flash';
  update cr_mime_types              set mime_type = 'application/vnd.adobe.flash-movie' where mime_type = 'application/x-shockwave-flash';
  update cr_revisions               set mime_type = 'application/vnd.adobe.flash-movie' where mime_type = 'application/x-shockwave-flash';
  insert into cr_extension_mime_type_map (extension, mime_type) values ( 'swf','application/vnd.adobe.flash-movie' );
  return 0;
end;
$$ language 'plpgsql';

select inline_0();
drop function inline_0();

