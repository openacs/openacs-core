create function inline_0 ()
returns integer as '
declare
  v_catalog_type_exists_p integer;
begin
	select count(*) into v_catalog_type_exists_p 
	from apm_package_file_types where file_type_key = ''message_catalog'';

	if v_catalog_type_exists_p = ''0'' then
          insert into apm_package_file_types(file_type_key, pretty_name) 
               values(''message_catalog'', ''Message Catalog'');
	end if;

	return 1;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();
