----------------------------------------
-- Return function headers for packages
---------------------------------------

-- show errors

create or replace function doc__get_proc_header (varchar,varchar)
returns varchar as '
declare
  proc_name              alias for $1;  
  package_name           alias for $2;  
begin
        return definition 
          from acs_func_headers 
         where fname = (package_name || ''__'' || proc_name)::name 
         limit 1;

end;' language 'plpgsql' stable;


create or replace function doc__get_package_header (varchar)
returns varchar as '
declare
  package_name           alias for $1;  
begin

        return '''';

end;' language 'plpgsql' immutable strict;

-- show errors
