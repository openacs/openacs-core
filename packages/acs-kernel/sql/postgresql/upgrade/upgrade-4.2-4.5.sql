-- packages/acs-kernel/sql/upgrade/upgrade-4.2-4.5.sql
--
-- @author vinod@kurup.com
-- @creation-date 2002-05-15
-- @cvs-id $Id$
--

-- fixes bug #1515 http://openacs.org/sdm/one-bug.tcl?baf_id=1515

drop function apm_package_version__upgrade_p (varchar,varchar,varchar);
create function apm_package_version__upgrade_p (varchar,varchar,varchar)
returns integer as '
declare
  upgrade_p__path                   alias for $1;  
  upgrade_p__initial_version_name   alias for $2;  
  upgrade_p__final_version_name     alias for $3;  
  v_pos1                            integer;       
  v_pos2                            integer;       
  v_tmp                             apm_package_files.path%TYPE;
  v_path                            apm_package_files.path%TYPE;
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

