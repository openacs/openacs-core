----------------------------------------
-- Return function headers for packages
---------------------------------------

-- create or replace package doc
-- is
-- 
--   function get_proc_header (
--     proc_name    in varchar2,
--     package_name in varchar2
--   ) return varchar2;
-- 
--   function get_package_header (
--     package_name in varchar2
--   ) return varchar2;
-- 
-- end doc;

-- show errors

-- create or replace package body doc
-- function get_proc_header
create function doc__get_proc_header (varchar,varchar)
returns varchar as '
declare
  proc_name              alias for $1;  
  package_name           alias for $2;  
begin
        return definition 
          from acs_func_headers 
         where fname = (package_name || ''__'' || proc_name)::name 
         limit 1;

end;' language 'plpgsql';


-- function get_package_header
create function doc__get_package_header (varchar)
returns varchar as '
declare
  package_name           alias for $1;  
begin

        return '''';
   
end;' language 'plpgsql';



-- show errors
         
      

        
