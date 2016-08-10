--                                                                                          
-- Update mime types.
-- The changes have to be performed in a transaction, therefore the inline function.
--
create or replace function inline_0 (
    p_label varchar,
    p_extension varchar,
    p_old_mime_type varchar,
    p_new_mime_type varchar
)
returns integer as $$
begin
    SET CONSTRAINTS ALL DEFERRED;
    delete from cr_extension_mime_type_map where mime_type = p_old_mime_type;

    insert into cr_mime_types(label, mime_type, file_extension)
        select p_label, p_new_mime_type, p_extension from dual
        where not exists (select 1 from cr_mime_types where mime_type = p_new_mime_type);

    update cr_content_mime_type_map   set mime_type = p_new_mime_type where mime_type = p_old_mime_type;
    update cr_revisions               set mime_type = p_new_mime_type where mime_type = p_old_mime_type;

    if exists (select 1 from cr_extension_mime_type_map where extension = p_extension) then
        update cr_extension_mime_type_map set mime_type = p_new_mime_type where extension = p_extension;
    else
        insert into cr_extension_mime_type_map (extension, mime_type)
            select p_extension, p_new_mime_type from dual
            where not exists (select 1 from cr_extension_mime_type_map where mime_type = p_new_mime_type);
    end if;

    delete from cr_mime_types where mime_type = p_old_mime_type;
    return 0;
end;
$$ language 'plpgsql';


select inline_0('Microsoft Office Excel Template'               ,'xltx'     ,'application/vnd.openxmlformats-officedocument.spreadsheetml.template'     ,'application/vnd.openxmlformats-officedocument.spreadsheetml-template');
select inline_0('Microsoft Office PowerPoint Template'          ,'potx'     ,'application/vnd.openxmlformats-officedocument.presentationml.template'    ,'application/vnd.openxmlformats-officedocument.presentationml-template');
select inline_0('Microsoft Office Word Template'                ,'dotx'     ,'application/vnd.openxmlformats-officedocument.wordprocessingml.template'  ,'application/vnd.openxmlformats-officedocument.wordprocessingml-template');
select inline_0('Video FLASH'                                   ,'flv'      ,''     ,'video/x-flv');
select inline_0('Microsoft Portable Executable'                 ,'exe'      ,''     ,'application/vnd.microsoft.portable-executable');
select inline_0('Virtue MTS'                                    ,'mts'      ,''     ,'model/vnd.mts');
select inline_0('Microsoft Document Imaging Format'             ,'mdi'      ,''     ,'image/vnd.ms-modi');
select inline_0('WSDL - Web Services Description Language'      ,'wsdl'     ,''     ,'application/wsdl+xml');
select inline_0('VPIM voice message'                            ,'vpm'      ,''     ,'multipart/voice-message');
select inline_0('Mathematica Notebook Player'                   ,'nbp'      ,''     ,'application/vnd.wolfram.player');
select inline_0('SMART Notebook'                                ,'notebook' ,''     ,'application/vnd.smart.notebook');
select inline_0('Novadigm RADIA and EDM products'               ,'ext'      ,''     ,'application/vnd.novadigm.ext');
select inline_0('Novadigm RADIA and EDM products'               ,'edx'      ,''     ,'application/vnd.novadigm.edx');
select inline_0('Microsoft XML Paper Specification'             ,'xps'      ,''     ,'application/vnd.ms-xpsdocument');
select inline_0('Microsoft Windows Media Player Playlist'       ,'wpl'      ,''     ,'application/vnd.ms-wpl');
select inline_0('Microsoft Office System Release Theme'         ,'thmx'     ,''     ,'application/vnd.ms-officetheme');
select inline_0('Lotus Wordpro'                                 ,'lwp'      ,''     ,'application/vnd.lotus-wordpro');
select inline_0('GeoGebra'                                      ,'ggb'      ,''     ,'application/vnd.geogebra.file');
select inline_0('Forms Data Format'                             ,'fdf'      ,''     ,'application/vnd.fdf');
select inline_0('Solids'                                        ,'sol'      ,''     ,'application/solids');
select inline_0('Synchronized Multimedia Integration Language'  ,'smi'      ,''     ,'application/smil+xml');
select inline_0('PKCS #10 - Certification Request Standard'     ,'p'        ,''     ,'application/pkcs10');
select inline_0('OpenXPS'                                       ,'oxps'     ,''     ,'application/oxps');
select inline_0('Mathematica Notebooks'                         ,'nb'       ,''     ,'application/mathematica');
select inline_0(''                                              ,'mm'       ,''     ,'application/base64');
select inline_0('BioPAX OWL'                                    ,'owl'      ,''     ,'application/vnd.biopax.rdf+xml');
select inline_0('Tcpdump Packet Capture'                        ,'pcap'     ,''     ,'application/vnd.tcpdump.pcap');

drop function inline_0(varchar,varchar,varchar,varchar);
