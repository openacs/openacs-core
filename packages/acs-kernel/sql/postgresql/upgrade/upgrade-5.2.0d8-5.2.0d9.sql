-- on pg8 the get_func_drop_command is not found since it wont coerce proname to varchar
create or replace function drop_package (varchar) returns varchar as '
declare
       package_name      alias for $1;
       v_rec             record;
       v_drop_cmd        varchar;
       v_pkg_name        varchar;
begin
        raise NOTICE ''DROP PACKAGE: %'', package_name;
        v_pkg_name := package_name || ''\\\\_\\\\_'' || ''%'';

        for v_rec in select proname 
                       from pg_proc 
                      where proname like v_pkg_name 
                   order by proname 
        LOOP
            raise NOTICE ''DROPPING FUNCTION: %'', v_rec.proname;
            v_drop_cmd := get_func_drop_command (v_rec.proname::varchar);
            EXECUTE v_drop_cmd;
        end loop;

        if NOT FOUND then 
          raise NOTICE ''PACKAGE: % NOT FOUND'', package_name;
        else
          raise NOTICE ''PACKAGE: %: DROPPED'', package_name;
        end if;
        
        return null;

end;' language 'plpgsql';
