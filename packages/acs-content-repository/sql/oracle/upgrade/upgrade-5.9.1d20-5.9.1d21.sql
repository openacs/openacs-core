--
-- Update mime types.
-- The changes have to be performed in a transaction, therefore the inline function.
--

create or replace function inline_0 (
    p_label in varchar,
    p_extension in varchar,
    p_old_mime_type in varchar,
    p_new_mime_type in varchar
)
return integer 
as
begin
  v_extension_exists integer default 0;

  delete from cr_extension_mime_type_map where mime_type = p_old_mime_type;

  insert into cr_mime_types(label, mime_type, file_extension)
    select p_label, p_new_mime_type, p_extension from dual
    where not exists (select 1 from cr_mime_types where mime_type = p_new_mime_type);

  update cr_content_mime_type_map   set mime_type = p_new_mime_type where mime_type = p_old_mime_type;
  update cr_revisions               set mime_type = p_new_mime_type where mime_type = p_old_mime_type;
  
  select 1 into v_extension_exists 
    from cr_extension_mime_type_map 
    where extension = p_extension;

  if v_extension_exists = 1 then
    update cr_extension_mime_type_map set mime_type = p_new_mime_type where extension = p_extension;
  else
    insert into cr_extension_mime_type_map (extension, mime_type)
      select p_extension, p_new_mime_type from dual
      where not exists (select 1 from cr_extension_mime_type_map where mime_type = p_new_mime_type);
  end if;

  delete from cr_mime_types where mime_type = p_old_mime_type;
  return 1;
end;
/

select inline_0('Microsoft Office Excel Template'               ,'xltx'     ,'application/vnd.openxmlformats-officedocument.spreadsheetml.template'     ,'application/vnd.openxmlformats-officedocument.spreadsheetml-template') from dual;
select inline_0('Microsoft Office PowerPoint Template'          ,'potx'     ,'application/vnd.openxmlformats-officedocument.presentationml.template'    ,'application/vnd.openxmlformats-officedocument.presentationml-template') from dual;
select inline_0('Microsoft Office Word Template'                ,'dotx'     ,'application/vnd.openxmlformats-officedocument.wordprocessingml.template'  ,'application/vnd.openxmlformats-officedocument.wordprocessingml-template') from dual;
select inline_0('Video FLASH'                                   ,'flv'      ,''     ,'video/x-flv') from dual;
select inline_0('Microsoft Portable Executable'                 ,'exe'      ,''     ,'application/vnd.microsoft.portable-executable') from dual;
select inline_0('Virtue MTS'                                    ,'mts'      ,''     ,'model/vnd.mts') from dual;
select inline_0('Microsoft Document Imaging Format'             ,'mdi'      ,''     ,'image/vnd.ms-modi') from dual;
select inline_0('WSDL - Web Services Description Language'      ,'wsdl'     ,''     ,'application/wsdl+xml') from dual;
select inline_0('VPIM voice message'                            ,'vpm'      ,''     ,'multipart/voice-message') from dual;
select inline_0('Mathematica Notebook Player'                   ,'nbp'      ,''     ,'application/vnd.wolfram.player') from dual;
select inline_0('SMART Notebook'                                ,'notebook' ,''     ,'application/vnd.smart.notebook') from dual;
select inline_0('Novadigm RADIA and EDM products'               ,'ext'      ,''     ,'application/vnd.novadigm.ext') from dual;
select inline_0('Novadigm RADIA and EDM products'               ,'edx'      ,''     ,'application/vnd.novadigm.edx') from dual;
select inline_0('Microsoft XML Paper Specification'             ,'xps'      ,''     ,'application/vnd.ms-xpsdocument') from dual;
select inline_0('Microsoft Windows Media Player Playlist'       ,'wpl'      ,''     ,'application/vnd.ms-wpl') from dual;
select inline_0('Microsoft Office System Release Theme'         ,'thmx'     ,''     ,'application/vnd.ms-officetheme') from dual;
select inline_0('Lotus Wordpro'                                 ,'lwp'      ,''     ,'application/vnd.lotus-wordpro') from dual;
select inline_0('GeoGebra'                                      ,'ggb'      ,''     ,'application/vnd.geogebra.file') from dual;
select inline_0('Forms Data Format'                             ,'fdf'      ,''     ,'application/vnd.fdf') from dual;
select inline_0('Solids'                                        ,'sol'      ,''     ,'application/solids') from dual;
select inline_0('Synchronized Multimedia Integration Language'  ,'smi'      ,''     ,'application/smil+xml') from dual;
select inline_0('PKCS #10 - Certification Request Standard'     ,'p'        ,''     ,'application/pkcs10') from dual;
select inline_0('OpenXPS'                                       ,'oxps'     ,''     ,'application/oxps') from dual;
select inline_0('Mathematica Notebooks'                         ,'nb'       ,''     ,'application/mathematica') from dual;
select inline_0(''                                              ,'mm'       ,''     ,'application/base64') from dual;
select inline_0('BioPAX OWL'                                    ,'owl'      ,''     ,'application/vnd.biopax.rdf+xml') from dual;
select inline_0('Tcpdump Packet Capture'                        ,'pcap'     ,''     ,'application/vnd.tcpdump.pcap') from dual;

drop function inline_0;
