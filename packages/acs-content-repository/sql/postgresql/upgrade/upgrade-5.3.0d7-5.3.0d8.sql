-- 
-- packages/acs-content-repository/sql/postgresql/upgrade/upgrade-5.3.0d7-5.3.0d8.sql
-- 
-- @author Emmanuelle Raffenne (eraffenne@dia.uned.es)
-- @creation-date 2006-12-15
-- @arch-tag: a67a9b16-d809-4da4-a47a-62f96f7e8d1e
-- @cvs-id $Id$
--

create or replace function inline_0(varchar,varchar,varchar) returns integer as
'declare
	v_mime_type alias for $1;
	v_file_extension alias for $2;
	v_label alias for $3;
	crmt_rec record;
	cremtm_rec record;
begin

	select into crmt_rec * from cr_mime_types where file_extension = v_file_extension;
	if not found then
		insert into cr_mime_types (mime_type, file_extension, label) values (v_mime_type, v_file_extension, v_label);
	else
		update cr_mime_types set mime_type=v_mime_type, label=v_label where file_extension=v_file_extension;
	end if;

	select into cremtm_rec * from cr_extension_mime_type_map where extension=v_file_extension;
	if not found then
		insert into cr_extension_mime_type_map (mime_type, extension) values (v_mime_type, v_file_extension);
	else
		update cr_extension_mime_type_map set mime_type=v_mime_type where extension=v_file_extension;
	end if;

	return 0;
	end;
' language 'plpgsql';



select inline_0('application/vnd.oasis.opendocument.text', 'odt', 'OpenDocument Text');
select inline_0('application/vnd.oasis.opendocument.text-template', 'ott','OpenDocument Text Template');
select inline_0('application/vnd.oasis.opendocument.text-web', 'oth', 'HTML Document Template');
select inline_0('application/vnd.oasis.opendocument.text-master', 'odm', 'OpenDocument Master Document');
select inline_0('application/vnd.oasis.opendocument.graphics', 'odg', 'OpenDocument Drawing');
select inline_0('application/vnd.oasis.opendocument.graphics-template', 'otg', 'OpenDocument Drawing Template');
select inline_0('application/vnd.oasis.opendocument.presentation', 'odp', 'OpenDocument Presentation');
select inline_0('application/vnd.oasis.opendocument.presentation-template', 'otp', 'OpenDocument Presentation Template');
select inline_0('application/vnd.oasis.opendocument.spreadsheet', 'ods', 'OpenDocument Spreadsheet');
select inline_0('application/vnd.oasis.opendocument.spreadsheet-template', 'ots', 'OpenDocument Spreadsheet Template');
select inline_0('application/vnd.oasis.opendocument.chart', 'odc', 'OpenDocument Chart');
select inline_0('application/vnd.oasis.opendocument.formula', 'odf', 'OpenDocument Formula');
select inline_0('application/vnd.oasis.opendocument.database', 'odb', 'OpenDocument Database');
select inline_0('application/vnd.oasis.opendocument.image', 'odi', 'OpenDocument Image');

drop function inline_0(varchar,varchar,varchar);
