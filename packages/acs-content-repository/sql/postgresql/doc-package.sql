----------------------------------------
-- Return function headers for packages
---------------------------------------

-- show errors



-- added
select define_function_args('doc__get_proc_header','proc_name,package_name');

--
-- procedure doc__get_proc_header/2
--
CREATE OR REPLACE FUNCTION doc__get_proc_header(
   proc_name varchar,
   package_name varchar
) RETURNS varchar AS $$
DECLARE
BEGIN
        return definition 
          from acs_func_headers 
         where fname = (package_name || '__' || proc_name)::name 
         limit 1;

END;
$$ LANGUAGE plpgsql stable;




-- added
select define_function_args('doc__get_package_header','package_name');

--
-- procedure doc__get_package_header/1
--
CREATE OR REPLACE FUNCTION doc__get_package_header(
   package_name varchar
) RETURNS varchar AS $$
DECLARE
BEGIN

        return '';

END;
$$ LANGUAGE plpgsql immutable strict;

-- show errors
