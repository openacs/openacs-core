-- Remove obsolete parts of the APM datamodel not used
--
-- @author Peter Marklund

-- *** Remove a column not needed
-- See http://openacs.org/bugtracker/openacs/bug?bug%5fnumber=555
-- Seems PG 7.2 doesn't support this
-- alter table apm_packages drop enabled_p;

-- *** Get rid of file-related data no longer used
drop table apm_package_file_types;
drop table apm_package_files;
-- View was dropped by previous drop
--drop view apm_file_info;
drop function apm_package_version__add_file (integer,integer,varchar,varchar, varchar);
drop function apm_package_version__remove_file (integer,varchar);
drop function apm_package__disable (integer);
drop function apm_package__enable (integer);
-- Replacing reference to apm_package_file.path%TYPE with varchar(1500)
drop function apm_package_version__upgrade_p (varchar,varchar,varchar);
create function apm_package_version__upgrade_p (varchar,varchar,varchar)
returns integer as '
declare
  upgrade_p__path                   alias for $1;  
  upgrade_p__initial_version_name   alias for $2;  
  upgrade_p__final_version_name     alias for $3;  
  v_pos1                            integer;       
  v_pos2                            integer;       
  v_tmp                             varchar(1500);
  v_path                            varchar(1500);
  v_version_from                    apm_package_versions.version_name%TYPE;
  v_version_to                      apm_package_versions.version_name%TYPE;
begin

	-- Set v_path to the tail of the path (the file name).        
	v_path := substr(upgrade_p__path, instr(upgrade_p__path, ''/'', -1) + 1);

	-- Remove the extension, if it is .sql.
	v_pos1 := position(''.sql'' in v_path);
	if v_pos1 > 0 then
	    v_path := substr(v_path, 1, v_pos1 - 1);
	end if;

	-- Figure out the from/to version numbers for the individual file.
	v_pos1 := instr(v_path, ''-'', -1, 2);
	v_pos2 := instr(v_path, ''-'', -1);
	if v_pos1 = 0 or v_pos2 = 0 then
	    -- There aren''t two hyphens in the file name. Bail.
	    return 0;
	end if;

	v_version_from := substr(v_path, v_pos1 + 1, v_pos2 - v_pos1 - 1);
	v_version_to := substr(v_path, v_pos2 + 1);

	if apm_package_version__version_name_greater(upgrade_p__initial_version_name, v_version_from) <= 0 and
	   apm_package_version__version_name_greater(upgrade_p__final_version_name, v_version_to) >= 0 then
	    return 1;
	end if;

	return 0;
        -- exception when others then
	-- Invalid version number.
	-- return 0;
   
end;' language 'plpgsql';
