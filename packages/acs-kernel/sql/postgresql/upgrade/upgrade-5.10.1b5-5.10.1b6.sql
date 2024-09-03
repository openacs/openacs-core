---
--- The default value for "authority_id" was missing.
---
select define_function_args('acs_user__new','user_id;null,object_type;user,creation_date;now(),creation_user;null,creation_ip;null,authority_id;null,username,email,url;null,first_names,last_name,password,salt,screen_name;null,email_verified_p;t,context_id;null');

---
--- Remove leftovers from earlier changes in the SQL API. The update
--- scripts did not care about function args, so orphaned entries
--- could cause confusions.
---
delete from acs_function_args where function = 'USER__NEW';
delete from acs_function_args where function = 'SITE_NODE_GET_TREE_SORTKEY';
delete from acs_function_args where function = 'ACS_OBJECT__CHECK_REPRESENTATION';
delete from acs_function_args where function = 'PRIV_RECURSE_SUBTREE';


---
--- The drop package function did not care about deleting entries on
--- the function args table. The function args deleted here are
--- created automatically by the Tcl proc "package_generate_body".
---
CREATE OR REPLACE FUNCTION drop_package(
   package_name varchar
) RETURNS varchar AS $$
DECLARE
       v_rec             record;
       v_drop_cmd        varchar;
       v_pkg_name        varchar;
BEGIN
        raise NOTICE 'DROP PACKAGE: %', package_name;
        v_pkg_name := package_name || '__' || '%';

        for v_rec in select proname
                       from pg_proc
                      where proname like v_pkg_name
                   order by proname
        LOOP
            raise NOTICE 'DROPPING FUNCTION: %', v_rec.proname;
            v_drop_cmd := get_func_drop_command (v_rec.proname::varchar);
            EXECUTE v_drop_cmd;

            DELETE FROM acs_function_args where function = upper(v_rec.proname);
        end loop;

        if NOT FOUND then
          raise NOTICE 'PACKAGE: % NOT FOUND', package_name;
        else
          raise NOTICE 'PACKAGE: %: DROPPED', package_name;
        end if;

        return null;

END;
$$ LANGUAGE plpgsql;
