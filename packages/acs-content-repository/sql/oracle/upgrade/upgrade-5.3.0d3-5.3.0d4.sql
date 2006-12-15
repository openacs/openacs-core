-- 
-- packages/acs-content-repository/sql/oracle/upgrade/upgrade-5.3.0d3-5.3.0d4.sql
-- 
-- @author Emmanuelle Raffenne (eraffenne@dia.uned.es)
-- @creation-date 2006-12-15
-- @arch-tag: a67a9b16-d809-4da4-a47a-62f96f7e8d1e
-- @cvs-id $Id$
--

create or replace procedure update_mime_types (
	v_mime_type in cr_mime_types.mime_type%TYPE,
	v_file_extension in cr_mime_types.file_extension%TYPE,
	v_label in cr_mime_types.label%TYPE
) is
	v_count integer;
begin

	select count(*) into v_count from cr_mime_types where file_extension = v_file_extension;
	if v_count = 0 then
		insert into cr_mime_types (mime_type, file_extension, label) values (v_mime_type, v_file_extension, v_label);
	else
		update cr_mime_types set mime_type=v_mime_type, label=v_label where file_extension=v_file_extension;
	end if;

	select count(*) into v_count from cr_extension_mime_type_map where extension=v_file_extension;
	if v_count = 0 then
		insert into cr_extension_mime_type_map (mime_type, extension) values (v_mime_type, v_file_extension);
	else
		update cr_extension_mime_type_map set mime_type=v_mime_type where extension=v_file_extension;
	end if;

end update_mime_types;
/
show errors;


begin
	update_mime_types('application/vnd.oasis.opendocument.text', 'odt', 'OpenDocument Text');
	update_mime_types('application/vnd.oasis.opendocument.text-template', 'ott','OpenDocument Text Template');
	update_mime_types('application/vnd.oasis.opendocument.text-web', 'oth', 'HTML Document Template');
	update_mime_types('application/vnd.oasis.opendocument.text-master', 'odm', 'OpenDocument Master Document');
	update_mime_types('application/vnd.oasis.opendocument.graphics', 'odg', 'OpenDocument Drawing');
	update_mime_types('application/vnd.oasis.opendocument.graphics-template', 'otg', 'OpenDocument Drawing Template');
	update_mime_types('application/vnd.oasis.opendocument.presentation', 'odp', 'OpenDocument Presentation');
	update_mime_types('application/vnd.oasis.opendocument.presentation-template', 'otp', 'OpenDocument Presentation Template');
	update_mime_types('application/vnd.oasis.opendocument.spreadsheet', 'ods', 'OpenDocument Spreadsheet');
	update_mime_types('application/vnd.oasis.opendocument.spreadsheet-template', 'ots', 'OpenDocument Spreadsheet Template');
	update_mime_types('application/vnd.oasis.opendocument.chart', 'odc', 'OpenDocument Chart');
	update_mime_types('application/vnd.oasis.opendocument.formula', 'odf', 'OpenDocument Formula');
	update_mime_types('application/vnd.oasis.opendocument.database', 'odb', 'OpenDocument Database');
	update_mime_types('application/vnd.oasis.opendocument.image', 'odi', 'OpenDocument Image');
end;
/
show errors;

drop procedure update_mime_types;
