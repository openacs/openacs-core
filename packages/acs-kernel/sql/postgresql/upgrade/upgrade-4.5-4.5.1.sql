-- added jon@jongriffin.com

--include the new file
\i ../site-node-object-map-create.sql


-- acs-objects-create code

drop function acs_object__update_last_modified (integer, timestamp);

 create function acs_object__update_last_modified (integer, timestamp)
 returns integer as '
 declare
     acs_object__update_last_modified__object_id     alias for $1;
     acs_object__update_last_modified__last_modified alias for $2; -- default now()
     v_parent_id                                     integer;
     v_last_modified                                 timestamp;
 begin
     if acs_object__update_last_modified__last_modified is null then
         v_last_modified := now();
     else
         v_last_modified := acs_object__update_last_modified__last_modified;
     end if;

     update acs_objects
     set last_modified = v_last_modified
     where object_id = acs_object__update_last_modified__object_id;

     select context_id
     into v_parent_id
     from acs_objects
     where object_id = acs_object__update_last_modified__object_id;

     if v_parent_id is not null and v_parent_id != 0 then
         perform acs_object__update_last_modified(v_parent_id, v_last_modified);
     end if;

     return acs_object__update_last_modified__object_id;
 end;' language 'plpgsql';


-- apm-create
 create function apm_package__parent_id (integer) returns integer as '
 declare
     apm_package__parent_id__package_id alias for $1;
     v_package_id apm_packages.package_id%TYPE;
 begin
     select sn1.object_id
     into v_package_id
     from site_nodes sn1
     where sn1.node_id = (select sn2.parent_id
                          from site_nodes sn2
                          where sn2.object_id = apm_package__parent_id__package_id);

     if NOT FOUND then
         return -1;
     else
         return v_package_id;
     end if;
 end;' language 'plpgsql';


-- function upgrade_p

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
        v_pos1 := position(''.'' in v_path);
        if v_pos1 > 0 and substr(v_path, v_pos1) = ''.sql'' then
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


-- postgresql.sql

create function tree_increment_key(varbit)
 returns varbit as '
 declare
     p_child_sort_key                alias for $1;
     v_child_sort_key                integer;
 begin
     if p_child_sort_key is null then
         v_child_sort_key := 0;
     else
         v_child_sort_key := tree_leaf_key_to_int(p_child_sort_key) + 1;
     end if;

     return int_to_tree_key(v_child_sort_key);
 end;' language 'plpgsql' with(iscachable);

--
drop function int_to_tree_key(integer);

create function int_to_tree_key(integer) returns varbit as '

-- Convert an integer into the bit string format used to store
-- tree sort keys.   Using 4 bytes for the long keys requires
-- using -2^31 rather than 2^31 to avoid a twos-complement
-- "integer out of range" error in PG - if for some reason you
-- want to use a smaller value use positive powers of two!

-- There was an "out of range" check in here when I was using 15
-- bit long keys but the only check that does anything with the long
-- keys is to check for negative numbers.

declare
  p_intkey        alias for $1;
begin
  if p_intkey < 0 then
    raise exception ''int_to_tree_key: key must be a positive integer'';
  end if;

  if p_intkey < 128 then
    return substring(bitfromint4(p_intkey), 25, 8);
  else
    return substring(bitfromint4(-2^31 + p_intkey), 1, 32);
  end if;

end;' language 'plpgsql' with (isstrict, iscachable);

--

drop function create_user_col_comments();
create function create_user_col_comments() returns boolean as '
begin
  -- in version 7.1 col_description was missing but is present in 7.2
  -- does it exist in 7.0?
  if version() like ''%7.1%'' then
    execute ''
      create view user_col_comments as
        select upper(c.relname) as table_name,
         upper(a.attname) as column_name,
         d.description as comments
          from pg_class c,
               pg_attribute a
                 left outer join pg_description d on (a.oid = d.objoid)
         where c.oid = a.attrelid
           and a.attnum > 0'';
  else
    execute ''
      create view user_col_comments as
        select upper(c.relname) as table_name,
               upper(a.attname) as column_name,
               col_description(a.attrelid, a.attnum) as comments
        from pg_class c
          left join pg_attribute a
          on a.attrelid = c.oid
        where a.attnum > 0'';
  end if;
  return ''t'';
end;' language 'plpgsql';

select create_user_col_comments();

drop function create_user_col_comments();

---

drop function create_user_tab_comments();
create function create_user_tab_comments() returns boolean as '
begin
  if version() like ''%7.2%'' then
    execute ''
    create view user_tab_comments as
      select upper(c.relname) as table_name,
         case
           when c.relkind = ''''r'''' then ''''TABLE''''
           when c.relkind = ''''v'''' then ''''VIEW''''
           else c.relkind::text
         end as table_type,
         d.description as comments
    from pg_class c
           left outer join pg_description d on (c.oid = d.objoid)
       where d.objsubid = 0'';
  else
    execute ''
    create view user_tab_comments as
      select upper(c.relname) as table_name,
         case
           when c.relkind = ''''r'''' then ''''TABLE''''
           when c.relkind = ''''v'''' then ''''VIEW''''
           else c.relkind::text
         end as table_type,
         d.description as comments
    from pg_class c
           left outer join pg_description d on (c.oid = d.objoid)'';
  end if;
  return ''t'';
end;' language 'plpgsql';

select create_user_tab_comments();

drop function create_user_tab_comments();

--

create function rel_segment__new (varchar,integer,varchar)
returns integer as '
declare
  new__segment_name      alias for $1;
  new__group_id          alias for $2;
  new__rel_type          alias for $3;
  v_segment_id           rel_segments.segment_id%TYPE;
begin

   v_segment_id := rel_segment__new(null, ''rel_segment'', now(), null, null, null, null, new__segment_name, new__group\
_id, new__rel_type, null);

   return v_segment_id;

end;' language 'plpgsql';

-- site-nodes-create

create index site_nodes_parent_id_idx on site_nodes(parent_id,object_id,node_id);

select define_function_args ('site_node__new', 'node_id,parent_id,name,object_id,directory_p,pattern_p,creation_user,cr\
eation_ip');

-- Hope this all works for you!


