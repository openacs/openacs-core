-- added jon@jongriffin.com
-- updated 2002-08-17 vinod@kurup.com

-- acs-kernel-create.sql
\i ../site-node-object-map-create.sql


-- acs-objects-create.sql
 create function acs_object__update_last_modified (integer)
 returns integer as '
 declare
     acs_object__update_last_modified__object_id     alias for $1;
 begin
     return acs_object__update_last_modified(acs_object__update_last_modified__object_id, now());
 end;' language 'plpgsql';

 create function acs_object__update_last_modified (integer, timestamptz)
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


-- apm-create.sql
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

-- postgresql.sql

create function inline_0 () returns integer as '
-- Create a bitfromint4(integer) function if it doesn''t exists.
-- Due to a bug in PG 7.3 this function is absent in PG 7.3.
declare
    v_bitfromint4_count integer;
begin
    select into v_bitfromint4_count count(*) from pg_proc where proname = ''bitfromint4'';
    if v_bitfromint4_count = 0 then
	create or replace function bitfromint4 (integer) returns bit varying as ''
	begin 
    	    return "bit"($1);
	end;'' language ''plpgsql'';
   end if;
   return 1;
end;' language 'plpgsql';

select inline_0();
drop function inline_0();

create function inline_1 () returns integer as '
-- Create a bitfromint4(integer) function if it doesn''t exists.
-- Due to a bug in PG 7.3 this function is absent in PG 7.3.
declare
    v_bittoint4_count integer;
begin
    select into v_bittoint4_count count(*) from pg_proc where proname = ''bittoint4'';
    if v_bittoint4_count = 0 then
	create or replace function bittoint4 (bit varying) returns integer as ''
	begin 
    	    return "int4"($1);
	end;'' language ''plpgsql'';
   end if;
   return 1;
end;' language 'plpgsql';

select inline_1();
drop function inline_1();

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

---

-- vinodk: create_user_col_comments is changed, but only with comments
-- also, the function is dropped after it creates the view, so the comments
-- persist only in the SQL file

---

-- need to drop the view that the function is going to create
-- otherwise, we'll get 'relation already exists' errors

drop view user_tab_comments;

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

-- rel-constraints-create.sql

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

-- site-nodes-create.sql

create index site_nodes_parent_id_idx on site_nodes(parent_id,object_id,node_id);

select define_function_args ('site_node__new', 'node_id,parent_id,name,object_id,directory_p,pattern_p,creation_user,cr\
eation_ip');

-- Hope this all works for you!


