-- function check_representation
create or replace function acs_group__check_representation (integer)
returns boolean as '
declare
  group_id               alias for $1;  
  res                    boolean; 
  comp                   record;
  memb                   record;      
begin
   if group_id is null then 
        --maybe we should just return ''f'' instead?
	raise exception ''acs_group__check_representation called with null group_id'';
   end if;

   res := ''t'';
   PERFORM acs_log__notice(''acs_group.check_representation'',
                  ''Running check_representation on group '' || group_id);

   if acs_object__check_representation(group_id) = ''f'' then
     res := ''f'';
   end if;

   for comp in select c.rel_id
             from acs_rels r, composition_rels c
             where r.rel_id = c.rel_id
             and r.object_id_one = group_id 
   LOOP
     if composition_rel__check_representation(comp.rel_id) = ''f'' then
       res := ''f'';
     end if;
   end loop;

   for memb in  select m.rel_id
             from acs_rels r, membership_rels m
             where r.rel_id = m.rel_id
             and r.object_id_one = group_id 
   LOOP
     if membership_rel__check_representation(memb.rel_id) = ''f'' then
       res := ''f'';
     end if;
   end loop;

   PERFORM acs_log__notice(''acs_group.check_representation'',
                  ''Done running check_representation on group '' || group_id);

   return res;
  
end;' language 'plpgsql';

-- check for null input raise exception.

create or replace function acs_object__check_context_index (integer,integer,integer)
returns boolean as '
declare
  check_context_index__object_id              alias for $1;  
  check_context_index__ancestor_id            alias for $2;  
  check_context_index__n_generations          alias for $3;  
  n_rows                                      integer;       
  n_gens                                      integer;       
begin
   -- Verify that this row exists in the index.
   if check_context_index__object_id is null or check_context_index__ancestor_id is null then
	raise exception ''object_id or ancestor_id is null in acs_object__check_context_index'';
   end if;	
   select case when count(*) = 0 then 0 else 1 end into n_rows
   from acs_object_context_index
   where object_id = check_context_index__object_id
   and ancestor_id = check_context_index__ancestor_id;

   if n_rows = 1 then
     -- Verify that the count is correct.
     select n_generations into n_gens
     from acs_object_context_index
     where object_id = check_context_index__object_id
     and ancestor_id = check_context_index__ancestor_id;

     if n_gens != check_context_index__n_generations then
       PERFORM acs_log__error(''acs_object.check_representation'', 
                              ''Ancestor '' ||
                     check_context_index__ancestor_id || '' of object '' || 
                     check_context_index__object_id ||
		     '' reports being generation '' || n_gens ||
		     '' when it is actually generation '' || 
                     check_context_index__n_generations ||
		     ''.'');
       return ''f'';
     else
       return ''t'';
     end if;
   else
     PERFORM acs_log__error(''acs_object.check_representation'', 
                            ''Ancestor '' ||
                            check_context_index__ancestor_id || 
                            '' of object '' || check_context_index__object_id 
                            || '' is missing an entry in acs_object_context_index.'');
     return ''f'';
   end if;
  
end;' language 'plpgsql';


-- function check_path
create or replace function acs_object__check_path (integer,integer)
returns boolean as '
declare
  check_path__object_id              alias for $1;  
  check_path__ancestor_id            alias for $2;  
  check_path__context_id             acs_objects.context_id%TYPE;
  check_path__security_inherit_p     acs_objects.security_inherit_p%TYPE;
begin
   if check_path__object_id is null or check_path__ancestor_id then 
	raise exception ''acs_object__check_path called with null object_id or ancestor_id'';
   end if;
   if check_path__object_id = check_path__ancestor_id then
     return ''t'';
   end if;

   select context_id, security_inherit_p 
   into check_path__context_id, check_path__security_inherit_p
   from acs_objects
   where object_id = check_path__object_id;

   -- we should be able to handle the case where check_path fails 
   -- should we not?

   if check_path__object_id = 0 and check_path__context_id is null then 
      return ''f'';
   end if;

   if check_path__context_id is null or check_path__security_inherit_p = ''f'' 
   then
     check_path__context_id := 0;
   end if;

   return acs_object__check_path(check_path__context_id, 
                                 check_path__ancestor_id);
  
end;' language 'plpgsql';



create or replace function acs_object__check_representation (integer)
returns boolean as '
declare
  check_representation__object_id              alias for $1;  
  result                                       boolean;       
  check_representation__object_type            acs_objects.object_type%TYPE;
  n_rows                                       integer;    
  v_rec                                        record;  
  row                                          record; 
begin
   if check_representation__object_id is null then 
	raise exception ''acs_object__check_representation called for null object_id'';
   end if;

   result := ''t'';
   PERFORM acs_log__notice(''acs_object.check_representation'',
                  ''Running acs_object.check_representation on object_id = '' 
                  || check_representation__object_id || ''.'');

   select object_type into check_representation__object_type
   from acs_objects
   where object_id = check_representation__object_id;

   PERFORM acs_log__notice(''acs_object.check_representation'',
                  ''OBJECT STORAGE INTEGRITY TEST'');

   for v_rec in  select t.object_type, t.table_name, t.id_column
             from acs_object_type_supertype_map m, acs_object_types t
	     where m.ancestor_type = t.object_type
	     and m.object_type = check_representation__object_type
	     union
	     select object_type, table_name, id_column
	     from acs_object_types
	     where object_type = check_representation__object_type 
     LOOP

        for row in execute ''select case when count(*) = 0 then 0 else 1 end as n_rows from '' || quote_ident(v_rec.table_name) || '' where '' || quote_ident(v_rec.id_column) || '' = '' || check_representation__object_id
        LOOP
            n_rows := row.n_rows;
            exit;
        end LOOP;

        if n_rows = 0 then
           result := ''f'';
           PERFORM acs_log__error(''acs_object.check_representation'',
                     ''Table '' || v_rec.table_name || 
                     '' (primary storage for '' ||
		     v_rec.object_type || 
                     '') doesn''''t have a row for object '' ||
		     check_representation__object_id || '' of type '' || 
                     check_representation__object_type || ''.'');
        end if;

   end loop;

   PERFORM acs_log__notice(''acs_object.check_representation'',
                  ''OBJECT CONTEXT INTEGRITY TEST'');

   if acs_object__check_object_ancestors(check_representation__object_id, 
                                         check_representation__object_id, 0) = ''f'' then
     result := ''f'';
   end if;

   if acs_object__check_object_descendants(check_representation__object_id, 
                                           check_representation__object_id, 0) = ''f'' then
     result := ''f'';
   end if;
   for row in  select object_id, ancestor_id, n_generations
	       from acs_object_context_index
	       where object_id = check_representation__object_id
	       or ancestor_id = check_representation__object_id 
   LOOP
     if acs_object__check_path(row.object_id, row.ancestor_id) = ''f'' then
       PERFORM acs_log__error(''acs_object.check_representation'',
		     ''acs_object_context_index contains an extraneous row: ''
                     || ''object_id = '' || row.object_id || 
                     '', ancestor_id = '' || row.ancestor_id || 
                     '', n_generations = '' || row.n_generations || ''.'');
       result := ''f'';
     end if;
   end loop;

   PERFORM acs_log__notice(''acs_object.check_representation'',
		  ''Done running acs_object.check_representation '' || 
		  ''on object_id = '' || check_representation__object_id || ''.'');

   return result;
  
end;' language 'plpgsql';


create or replace function acs_object__get_attr_storage_column(text) 
returns text as '
declare
        v_vals  alias for $1;
        v_idx   integer;
begin
        v_idx := strpos(v_vals,'','');
        if v_idx = 0 or v_vals is null then 
           raise exception ''invalid storage format: acs_object.get_attr_storage_column %'',v_vals;
        end if;

        return substr(v_vals,1,v_idx - 1);

end;' language 'plpgsql' immutable;

create or replace function acs_object__get_attr_storage_table(text) 
returns text as '
declare
        v_vals  alias for $1;
        v_idx   integer;
        v_tmp   varchar;
begin
        v_idx := strpos(v_vals,'','');

        if v_idx = 0 or v_vals is null then 
           raise exception ''invalid storage format: acs_object.get_attr_storage_table %'',v_vals;
        end if;

        v_tmp := substr(v_vals,v_idx + 1);
        v_idx := strpos(v_tmp,'','');
        if v_idx = 0 then 
           raise exception ''invalid storage format: acs_object.get_attr_storage_table %'',v_vals;
        end if;

        return substr(v_tmp,1,v_idx - 1);

end;' language 'plpgsql' immutable;

create or replace function acs_object__get_attr_storage_sql(text) 
returns text as '
declare
        v_vals  alias for $1;
        v_idx   integer;
        v_tmp   varchar;
begin
        v_idx := strpos(v_vals, '','');

        if v_idx = 0 or v_vals is null then 
           raise exception ''invalid storage format: acs_object.get_attr_storage_sql %'',v_vals;
        end if;

        v_tmp := substr(v_vals, v_idx + 1);
        v_idx := strpos(v_tmp, '','');
        if v_idx = 0 then 
           raise exception ''invalid storage format: acs_object.get_attr_storage_sql %'',v_vals;
        end if;

        return substr(v_tmp, v_idx + 1);

end;' language 'plpgsql' immutable;



create or replace function acs_object__get_attribute_storage (integer,varchar)
returns text as '
declare
  object_id_in           alias for $1;  
  attribute_name_in      alias for $2;  

--  these three are the out variables
  v_column               varchar;  
  v_table_name           varchar;  
  v_key_sql              text;
  
  v_object_type          acs_attributes.object_type%TYPE;
  v_static               acs_attributes.static_p%TYPE;
  v_attr_id              acs_attributes.attribute_id%TYPE;
  v_storage              acs_attributes.storage%TYPE;
  v_attr_name            acs_attributes.attribute_name%TYPE;
  v_id_column            varchar(200);   
  v_sql                  text;  
  v_return               text;  
  v_rec                  record;
begin
   --   select 
   --     object_type, id_column
   --   from
   --     acs_object_types
   --   connect by
   --     object_type = prior supertype
   --   start with
   --     object_type = (select object_type from acs_objects 
   --                    where object_id = object_id_in)

   -- Determine the attribute parameters
   select
     a.attribute_id, a.static_p, a.storage, a.table_name, a.attribute_name,
     a.object_type, a.column_name, t.id_column 
   into 
     v_attr_id, v_static, v_storage, v_table_name, v_attr_name, 
     v_object_type, v_column, v_id_column
   from 
     acs_attributes a,
     (select o2.object_type, o2.id_column
       from acs_object_types o1, acs_object_types o2
      where o1.object_type = (select object_type
                                from acs_objects o
                               where o.object_id = object_id_in)
        and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
     ) t
   where   
     a.attribute_name = attribute_name_in
   and
     a.object_type = t.object_type;

   if NOT FOUND then 
      raise EXCEPTION ''-20000: No such attribute % for object % in acs_object.get_attribute_storage.'', attribute_name_in, object_id_in;
   end if;

   -- This should really be done in a trigger on acs_attributes,
   -- instead of generating it each time in this function

   -- If there is no specific table name for this attribute,
   -- figure it out based on the object type
   if v_table_name is null or v_table_name = '''' then

     -- Determine the appropriate table name
     if v_storage = ''generic'' then
       -- Generic attribute: table name/column are hardcoded

       v_column := ''attr_value'';

       if v_static = ''f'' then
         v_table_name := ''acs_attribute_values'';
         v_key_sql := ''(object_id = '' || object_id_in || '' and '' ||
                      ''attribute_id = '' || v_attr_id || '')'';
       else
         v_table_name := ''acs_static_attr_values'';
         v_key_sql := ''(object_type = '''''' || v_object_type || '''''' and '' ||
                      ''attribute_id = '' || v_attr_id || '')'';
       end if;

     else
       -- Specific attribute: table name/column need to be retrieved
 
       if v_static = ''f'' then
         select 
           table_name, id_column 
         into 
           v_table_name, v_id_column
         from 
           acs_object_types 
         where 
           object_type = v_object_type;
         if NOT FOUND then 
            raise EXCEPTION ''-20000: No data found for attribute %::% object_id % in acs_object.get_attribute_storage'', v_object_type, attribute_name_in, object_id_in;
         end if;
       else
         raise EXCEPTION ''-20000: No table name specified for storage specific static attribute %::% object_id % in acs_object.get_attribute_storage.'',v_object_type, attribute_name_in, object_id_in;
       end if;
  
     end if;
   else 
     -- There is a custom table name for this attribute.
     -- Get the id column out of the acs_object_tables
     -- Raise an error if not found
     select id_column into v_id_column from acs_object_type_tables
       where object_type = v_object_type 
       and table_name = v_table_name;
       if NOT FOUND then 
          raise EXCEPTION ''-20000: No data found for attribute %::% object_id % in acs_object.get_attribute_storage'', v_object_type, attribute_name_in, object_id_in;
       end if;
   end if;

   if v_column is null or v_column = '''' then

     if v_storage = ''generic'' then
       v_column := ''attr_value'';
     else
       v_column := v_attr_name;
     end if;

   end if;

   if v_key_sql is null or v_key_sql = '''' then
     if v_static = ''f'' then   
       v_key_sql := v_id_column || '' = '' || object_id_in ; 
     else
       v_key_sql := v_id_column || '' = '''''' || v_object_type || '''''''';
     end if;
   end if;

   return v_column || '','' || v_table_name || '','' || v_key_sql; 

end;' language 'plpgsql' strict;


create or replace function acs_object__initialize_attributes (integer)
returns integer as '
declare
  initialize_attributes__object_id              alias for $1;  
  v_object_type                                 acs_objects.object_type%TYPE;
begin
   if  initialize_attributes__object_id is null then 
	raise exception ''acs_object__initialize_attributes called with null object_id'';
   end if;

   -- Initialize dynamic attributes
   insert into acs_attribute_values
    (object_id, attribute_id, attr_value)
   select
    initialize_attributes__object_id, a.attribute_id, a.default_value
   from acs_attributes a, acs_objects o
   where a.object_type = o.object_type
   and o.object_id = initialize_attributes__object_id
   and a.storage = ''generic''
   and a.static_p = ''f'';

   -- Retrieve type for static attributes
   select object_type into v_object_type from acs_objects
     where object_id = initialize_attributes__object_id;

   -- Initialize static attributes
   -- begin
     insert into acs_static_attr_values
      (object_type, attribute_id, attr_value)
     select
      v_object_type, a.attribute_id, a.default_value
     from acs_attributes a, acs_objects o
     where a.object_type = o.object_type
       and o.object_id = initialize_attributes__object_id
       and a.storage = ''generic''
       and a.static_p = ''t''
       and not exists (select 1 from acs_static_attr_values
                       where object_type = a.object_type);
   -- exception when no_data_found then null;

   return 0; 
end;' language 'plpgsql';



create or replace function acs_object__set_attribute (integer,varchar,varchar)
returns integer as '
declare
  object_id_in           alias for $1;  
  attribute_name_in      alias for $2;  
  value_in               alias for $3;  
  v_table_name           varchar;  
  v_column               varchar;  
  v_key_sql              text; 
  v_return               text; 
  v_storage              text;
begin
   if value_in is null then
	-- this will fail more cryptically in the execute so catch now. 
	raise exception ''acs_object__set_attribute: attempt to set % to null for object_id %'',attribute_name_in, object_id_in;
   end if;

   v_storage := acs_object__get_attribute_storage(object_id_in, attribute_name_in);

   v_column     := acs_object__get_attr_storage_column(v_storage);
   v_table_name := acs_object__get_attr_storage_table(v_storage);
   v_key_sql    := acs_object__get_attr_storage_sql(v_storage);

   execute ''update '' || v_table_name || '' set '' || quote_ident(v_column) || '' = '' || quote_literal(value_in) || '' where '' || v_key_sql;

   return 0; 
end;' language 'plpgsql';


create or replace function acs_object_util__get_object_type (integer)
returns varchar as '
declare
    p_object_id         alias for $1;
    v_object_type       varchar(100);
begin
    select object_type into v_object_type
    from acs_objects
    where object_id = p_object_id;

    if not found then
        raise exception ''acs_object_util__get_object_type: Invalid Object id: % '', p_object_id;
    end if;

    return v_object_type;

end;' language 'plpgsql' stable;

create or replace function acs_objects_get_tree_sortkey(integer) returns varbit as '
declare
  p_object_id    alias for $1;
begin
  return tree_sortkey from acs_objects where object_id = p_object_id;
end;' language 'plpgsql' stable strict;

create or replace function acs_rel_type__drop_type (varchar,boolean)
returns integer as '
declare
  drop_type__rel_type               alias for $1;  
  drop_type__cascade_p              alias for $2;  -- default ''f''  
  v_cascade_p                       boolean;
begin
    -- XXX do cascade_p.
    -- JCD: cascade_p seems to be ignored in acs_o_type__drop_type anyway...
    if drop_type__cascade_p is null then 
	v_cascade_p := ''f'';
    else 
	v_cascade_p := drop_type__cascade_p;
    end if;

    delete from acs_rel_types
	  where rel_type = drop_type__rel_type;

    PERFORM acs_object_type__drop_type(drop_type__rel_type, 
                                       v_cascade_p);

    return 0; 
end;' language 'plpgsql';


create or replace function apm__unregister_package (varchar,boolean)
returns integer as '
declare
  package_key            alias for $1;  
  cascade_p              alias for $2;  -- default ''t''
  v_cascade_p            boolean;
begin
   v_cascade_p := cascade_p;
   if cascade_p is null then 
	v_cascade_p := ''t'';
   end if;

   PERFORM apm_package_type__drop_type(
	package_key,
	v_cascade_p
   );

   return 0; 
end;' language 'plpgsql';


create or replace function apm__unregister_service (varchar,boolean)
returns integer as '
declare
  package_key            alias for $1;  
  cascade_p              alias for $2;  -- default ''f''
  v_cascade_p            boolean;  
begin
   v_cascade_p := cascade_p;
   if cascade_p is null then 
	v_cascade_p := ''f'';
   end if;

   PERFORM apm__unregister_package (
	package_key,
	v_cascade_p
   );

   return 0; 
end;' language 'plpgsql';

create or replace function apm_package__num_instances (varchar) returns integer as '
declare
        num_instances__package_key     alias for $1;
        v_num_instances                integer;
begin
        select count(*) into v_num_instances
	from apm_packages
	where package_key = num_instances__package_key;

        return v_num_instances;

end;' language 'plpgsql' stable;



create or replace function lob_copy(integer, integer) returns integer as '
declare
        from_id         alias for $1;
        to_id           alias for $2;
begin
	if from_id is null then 
	    raise exception ''lob_copy: attempt to copy null from_id to % to_id'',to_id;
        end if;

        insert into lobs (lob_id,refcount) values (to_id,0);

        insert into lob_data
             select to_id as lob_id, segment, byte_len, data
               from lob_data
              where lob_id = from_id;

        return null;

end;' language 'plpgsql';


create or replace function apm_package__parent_id (integer) returns integer as '
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

    return v_package_id;

end;' language 'plpgsql' stable strict;

create or replace function apm_package__singleton_p (varchar) returns integer as '
declare
	singleton_p__package_key        alias for $1;
        v_singleton_p                   integer;
begin
        select count(*) into v_singleton_p
	from apm_package_types
	where package_key = singleton_p__package_key
        and singleton_p = ''t'';

        return v_singleton_p;
end;' language 'plpgsql' stable;

create or replace function number_src(text) returns text as '
declare
        v_src   alias for $1;
        v_pos   integer;
        v_ret   text default '''';
        v_tmp   text;
        v_cnt   integer default -1;
begin
        if v_src is null then 
	     return null;
        end if;
        v_tmp := v_src;
        LOOP
            v_pos := position(''\n'' in v_tmp);
            v_cnt := v_cnt + 1;

            exit when v_pos = 0;

            if v_cnt != 0 then
              v_ret := v_ret || rpad(v_cnt,10) || substr(v_tmp,1,v_pos);
            end if;
            v_tmp := substr(v_tmp,v_pos + 1);
        end LOOP;

        return v_ret || rpad(v_cnt,10) || v_tmp;

end;' language 'plpgsql' immutable strict;

create or replace function party__email (integer)
returns varchar as '
declare
  email__party_id		alias for $1;
begin

  return email from parties where party_id = email__party_id;

end;' language 'plpgsql' stable strict;

create or replace function person__first_names (integer)
returns varchar as '
declare
  first_names__person_id        alias for $1;  
begin
  return first_names
  from persons
  where person_id = first_names__person_id;
  
end;' language 'plpgsql' stable strict;


create or replace function person__last_name (integer)
returns varchar as '
declare
  last_name__person_id        alias for $1;  
begin
  return last_name
  from persons
  where person_id = last_name__person_id;

end;' language 'plpgsql' stable strict;


create or replace function person__name (integer)
returns varchar as '
declare
  name__person_id        alias for $1;  
begin

  return first_names || '' '' || last_name
  from persons
  where person_id = name__person_id;

end;' language 'plpgsql';


create or replace function rel_constraint__get_constraint_id (integer,char,integer)
returns integer as '
declare
  get_constraint_id__rel_segment            alias for $1;  
  get_constraint_id__rel_side               alias for $2;  
  get_constraint_id__required_rel_segment   alias for $3;  
  v_constraint_id                           rel_constraints.constraint_id%TYPE;
begin
    return constraint_id
    from rel_constraints
    where rel_segment = get_constraint_id__rel_segment
      and rel_side = get_constraint_id__rel_side
      and required_rel_segment = get_constraint_id__required_rel_segment;

end;' language 'plpgsql' stable strict;

create or replace function rel_segment__get (integer,varchar)
returns integer as '
declare
  get__group_id         alias for $1;  
  get__rel_type         alias for $2;  
begin

   return min(segment_id)
   from rel_segments
   where group_id = get__group_id
     and rel_type = get__rel_type;
  
end;' language 'plpgsql' stable strict;

create or replace function rel_segment__name (integer)
returns varchar as '
declare
  name__segment_id             alias for $1;  
  name__segment_name           varchar(200);  
begin
  return segment_name
  from rel_segments
  where segment_id = name__segment_id;

end;' language 'plpgsql' stable strict;

---- DRB: fixes bug 1144

drop view registered_users CASCADE;
create view registered_users
as
  select p.email, p.url, pe.first_names, pe.last_name, u.*, mr.member_state
  from parties p, persons pe, users u, group_member_map m, membership_rels mr, acs_magic_objects amo
  where party_id = person_id
  and person_id = user_id
  and u.user_id = m.member_id
  and m.rel_id = mr.rel_id
  and amo.name = 'registered_users'
  and m.group_id = amo.object_id
  and m.container_id = m.group_id
  and m.rel_type = 'membership_rel'
  and mr.member_state = 'approved'
  and u.email_verified_p = 't';

create view registered_users_of_package_id
as
SELECT u.*, au.package_id
FROM application_users au, registered_users u
WHERE (au.user_id = u.user_id);

drop view cc_users CASCADE;
create view cc_users
as
select o.*, pa.*, pe.*, u.*, mr.member_state, mr.rel_id
from acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr, acs_magic_objects amo
where o.object_id = pa.party_id
  and pa.party_id = pe.person_id
  and pe.person_id = u.user_id
  and u.user_id = m.member_id
  and amo.name = 'registered_users'
  and m.group_id = amo.object_id
  and m.rel_id = mr.rel_id
  and m.container_id = m.group_id
  and m.rel_type = 'membership_rel';

create view cc_users_of_package_id
as
SELECT u.*, au.package_id
FROM application_users au, cc_users u
WHERE (au.user_id = u.user_id);

drop function acs__add_user(int4,varchar,timestamptz,int4,varchar,varchar,varchar,varchar,varchar,bpchar,bpchar,varchar,varchar,varchar,bool,varchar);

create or replace function acs__add_user (
    integer,      -- user_id
    varchar,      -- object_type
    timestamptz,  -- creation_date
    integer,      -- creation_user
    varchar,      -- cretion_ip
    integer,      -- authority_id; default 'local'
    varchar,      -- username
    varchar,      -- email
    varchar,      -- url
    varchar,      -- first_names
    varchar,      -- last_name
    char,         -- password
    char,         -- salt
    varchar,      -- screen_name
    boolean,      -- email_verified_p
    varchar       -- member_state
)
returns integer as '
declare
    p_user_id              alias for $1;  -- default null    
    p_object_type          alias for $2;  -- default ''user''
    p_creation_date        alias for $3;  -- default now()
    p_creation_user        alias for $4;  -- default null
    p_creation_ip          alias for $5;  -- default null
    p_authority_id         alias for $6;  -- defaults to local authority
    p_username             alias for $7;  --
    p_email                alias for $8;  
    p_url                  alias for $9;  -- default null
    p_first_names          alias for $10;  
    p_last_name            alias for $11;  
    p_password             alias for $12; 
    p_salt                 alias for $13; 
    p_screen_name          alias for $14; -- default null
    p_email_verified_p     alias for $15; -- default ''t''
    p_member_state         alias for $16; -- default ''approved''
    v_user_id              users.user_id%TYPE;
    v_rel_id               membership_rels.rel_id%TYPE;
begin
    v_user_id := acs_user__new (
        p_user_id, 
        p_object_type, 
        p_creation_date,
        p_creation_user, 
        p_creation_ip, 
        p_authority_id,
        p_username,
        p_email,
        p_url, 
        p_first_names, 
        p_last_name, 
        p_password,
	p_salt, 
        p_screen_name, 
        p_email_verified_p,
        null                  -- context_id
    );
   
    v_rel_id := membership_rel__new (
      null,
      ''membership_rel'',
      acs__magic_object_id(''registered_users''),      
      v_user_id,
      p_member_state,
      null,
      null);

    PERFORM acs_permission__grant_permission (
      v_user_id,
      v_user_id,
      ''read''
      );

    PERFORM acs_permission__grant_permission (
      v_user_id,
      v_user_id,
      ''write''
      );

    return v_user_id;
   
end;' language 'plpgsql';


drop function acs_user__new(int4,varchar,timestamptz,int4,varchar,varchar,varchar,varchar,varchar,bpchar,bpchar,varchar,varchar,varchar,bool,int4);

create or replace function acs_user__new (
    integer,      -- user_id
    varchar,      -- object_type
    timestamptz,  -- creation_date
    integer,      -- creation_user
    varchar,      -- creation_ip
    integer,      -- authority_id; default 'local'
    varchar,      -- username
    varchar,      -- email
    varchar,      -- url
    varchar,      -- first_names
    varchar,      -- last_name
    char,         -- password
    char,         -- salt
    varchar,      -- screen_name
    boolean,      -- email_verified_p
    integer       -- context_id
)
returns integer as '
declare
    p_user_id                  alias for $1;  -- default null  
    p_object_type              alias for $2;  -- default ''user''
    p_creation_date            alias for $3;  -- default now()
    p_creation_user            alias for $4;  -- default null
    p_creation_ip              alias for $5;  -- default null
    p_authority_id             alias for $6;  -- defaults to local authority
    p_username                 alias for $7;  --
    p_email                    alias for $8;  
    p_url                      alias for $9;  -- default null
    p_first_names              alias for $10;  
    p_last_name                alias for $11;  
    p_password                 alias for $12; 
    p_salt                     alias for $13; 
    p_screen_name              alias for $14; -- default null
    p_email_verified_p         alias for $15; -- default ''t''
    p_context_id               alias for $16; -- default null
    v_user_id                  users.user_id%TYPE;
    v_authority_id             auth_authorities.authority_id%TYPE;
    v_person_exists            varchar;			
begin
    v_user_id := p_user_id;

    select case when count(*) = 0 then ''f'' else ''t'' end into v_person_exists
    from persons where person_id = v_user_id;

    if v_person_exists = ''f'' then
        v_user_id := person__new(
            v_user_id, 
            p_object_type,
            p_creation_date, 
            p_creation_user, 
            p_creation_ip,
            p_email, 
            p_url, 
            p_first_names, 
            p_last_name, 
            p_context_id
        );
    else
     update acs_objects set object_type = ''user'' where object_id = v_user_id;
    end if;

    -- default to local authority
    if p_authority_id is null then
        select authority_id
        into   v_authority_id
        from   auth_authorities
        where  short_name = ''local'';
    else
        v_authority_id := p_authority_id;
    end if;

    insert into users
       (user_id, authority_id, username, password, salt, screen_name, email_verified_p)
    values
       (v_user_id, v_authority_id, p_username, p_password, p_salt, p_screen_name, p_email_verified_p);

    insert into user_preferences
      (user_id)
      values
      (v_user_id);

    return v_user_id;
  
end;' language 'plpgsql';
