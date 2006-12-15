-- procedure merge
create or replace function membership_rel__merge (integer)
returns integer as '
declare
  merge__rel_id                alias for $1;  
begin
    update membership_rels
    set member_state = ''merged''
    where rel_id = merge__rel_id;

    return 0; 
end;' language 'plpgsql';


alter table membership_rels drop constraint membership_rel_mem_ck;

alter table membership_rels add constraint membership_rel_mem_ck check (member_state in ('approved','needs approval','banned','rejected','deleted','merged'));
create function inline_0 ()
returns integer as '
declare
 attr_id acs_attributes.attribute_id%TYPE;
begin
 attr_id := acs_attribute__create_attribute (
	''acs_object'',
	''package_id'',
	''integer'',
	''Package ID'',
	''Package IDs'',
	null,
	null,
	null,
	0,
	1,
	null,
	''type_specific'',
	''f''
	);

 attr_id := acs_attribute__create_attribute (
	''acs_object'',
	''title'',
	''string'',
	''Title'',
	''Titles'',
	null,
	null,
	null,
	0,
	1,
	null,
	''type_specific'',
	''f''
	);

  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

alter table acs_objects add column title varchar(1000);
alter table acs_objects alter column title set default null;
alter table acs_objects add column package_id integer
  constraint acs_objects_package_id_fk
  references apm_packages(package_id) on delete set null;
alter table acs_objects alter column package_id set default null;

create index acs_objects_package_object_idx on acs_objects (package_id, object_id);
create index acs_objects_title_idx on acs_objects(title);

comment on column acs_objects.package_id is '
 Which package instance this object belongs to.
 Please note that in mid-term this column will replace all
 package_ids of package specific tables.
';

comment on column acs_objects.title is '
 Title of the object if applicable.
 Please note that in mid-term this column will replace all
 titles or object_names of package specific tables.
';

----------
-- update data
----------

update acs_objects
set title = (select group_name
             from groups
             where group_id = object_id)
where object_id in (select group_id from groups);

update acs_objects
set title = (select email
             from parties
             where party_id = object_id)
where object_type = 'party';

update acs_objects
set title = (select first_names || ' ' || last_name
             from persons
             where person_id = object_id)
where object_type in ('user','person');

update acs_objects
set title = (select short_name
             from auth_authorities
             where authority_id = object_id)
where object_type = 'authority';

update acs_objects
set title = (select action
             from journal_entries
             where journal_id = object_id)
where object_type = 'journal_entry';

update acs_objects
set title = (select name
             from site_nodes
             where node_id = acs_objects.object_id),
    package_id = (select object_id
                  from site_nodes
                  where node_id = acs_objects.object_id)
where object_type = 'site_node';

update acs_objects
set title = (select instance_name
             from apm_packages
             where package_id = object_id),
    package_id = object_id
where object_type in ('apm_package','apm_application','apm_service');

update acs_objects
set title = (select package_key || ', Version ' || version_name
             from apm_package_versions
             where version_id = object_id)
where object_type = 'apm_package_version';

update acs_objects
set title = (select package_key || ': Parameter ' || parameter_name
             from apm_parameters
             where parameter_id = object_id)
where object_type = 'apm_parameter';

update acs_objects
set title = (select rel_type || ': ' || object_id_one || ' - ' || object_id_two
             from acs_rels
             where rel_id = object_id)
where object_id in (select rel_id from acs_rels);

update acs_objects
set title = (select segment_name
             from rel_segments
             where segment_id = object_id)
where object_type = 'rel_segment';

update acs_objects
set title = (select constraint_name
             from rel_constraints
             where constraint_id = object_id)
where object_type = 'rel_constraint';

update acs_objects
set title = 'Unregistered Visitor'
where object_id = 0;

update acs_objects
set title = 'Default Context'
where object_id = -3;

update acs_objects
set title = 'Root Security Context'
where object_id = -4;

------------------------
-- ACS_OBJECT PACKAGE --
------------------------

drop function acs_object__new (integer,varchar,timestamptz,integer,varchar,integer,boolean);
drop function acs_object__new (integer,varchar,timestamptz,integer,varchar,integer);

create or replace function acs_object__new (integer,varchar,timestamptz,integer,varchar,integer,boolean,varchar,integer)
returns integer as '
declare
  new__object_id              alias for $1;  -- default null
  new__object_type            alias for $2;  -- default ''acs_object''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__context_id             alias for $6;  -- default null
  new__security_inherit_p     alias for $7;  -- default ''t''
  new__title                  alias for $8;  -- default null
  new__package_id             alias for $9;  -- default null
  v_object_id                 acs_objects.object_id%TYPE;
  v_creation_date	      timestamptz;
  v_title                     acs_objects.title%TYPE;
  v_object_type_pretty_name   acs_object_types.pretty_name%TYPE;
begin
  if new__object_id is null then
   select acs_object_id_seq.nextval
   into v_object_id from dual;
  else
    v_object_id := new__object_id;
  end if;

  if new__object_id is null then
   select pretty_name
   into v_object_type_pretty_name
   from acs_object_types
   where object_type = new__object_type;

    v_title := v_object_type_pretty_name || '' '' || v_object_id;
  else
    v_title := new__title;
  end if;

  if new__creation_date is null then
   v_creation_date:= now();
  else
   v_creation_date := new__creation_date;
  end if;

  insert into acs_objects
   (object_id, object_type, title, package_id, context_id,
    creation_date, creation_user, creation_ip, security_inherit_p)
  values
   (v_object_id, new__object_type, v_title, new__package_id, new__context_id,
    v_creation_date, new__creation_user, new__creation_ip, 
    new__security_inherit_p);

  PERFORM acs_object__initialize_attributes(v_object_id);

  return v_object_id;
  
end;' language 'plpgsql';

create or replace function acs_object__new (integer,varchar,timestamptz,integer,varchar,integer)
returns integer as '
declare
  new__object_id              alias for $1;  -- default null
  new__object_type            alias for $2;  -- default ''acs_object''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__context_id             alias for $6;  -- default null
  v_object_id                 acs_objects.object_id%TYPE;
  v_creation_date	      timestamptz;
begin
  return acs_object__new(new__object_id, new__object_type, new__creation_date,
                         new__creation_user, new__creation_ip, new__context_id,
                         ''t'', null, null);
end;' language 'plpgsql';

create or replace function acs_object__new (integer,varchar,timestamptz,integer,varchar,integer,boolean)
returns integer as '
declare
  new__object_id              alias for $1;  -- default null
  new__object_type            alias for $2;  -- default ''acs_object''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__context_id             alias for $6;  -- default null
  new__security_inherit_p     alias for $7;  -- default ''t''
begin
  return acs_object__new(new__object_id, new__object_type, new__creation_date,
                         new__creation_user, new__creation_ip, new__context_id,
                         new__security_inherit_p, null, null);
end;' language 'plpgsql';

create or replace function acs_object__new (integer,varchar,timestamptz,integer,varchar,integer,boolean,varchar)
returns integer as '
declare
  new__object_id              alias for $1;  -- default null
  new__object_type            alias for $2;  -- default ''acs_object''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__context_id             alias for $6;  -- default null
  new__security_inherit_p     alias for $7;  -- default ''t''
  new__title                  alias for $8;  -- default null
begin
  return acs_object__new(new__object_id, new__object_type, new__creation_date,
                         new__creation_user, new__creation_ip, new__context_id,
                         new__security_inherit_p, new__title, null);
end;' language 'plpgsql';

create or replace function acs_object__new (integer,varchar,timestamptz,integer,varchar,integer,varchar,integer)
returns integer as '
declare
  new__object_id              alias for $1;  -- default null
  new__object_type            alias for $2;  -- default ''acs_object''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__context_id             alias for $6;  -- default null
  new__title                  alias for $7;  -- default null
  new__package_id             alias for $8;  -- default null
begin
  return acs_object__new(new__object_id, new__object_type, new__creation_date,
                         new__creation_user, new__creation_ip, new__context_id,
                         ''t'', new__title, new__package_id);
end;' language 'plpgsql';

create or replace function acs_object__new (integer,varchar,timestamptz,integer,varchar,integer,varchar)
returns integer as '
declare
  new__object_id              alias for $1;  -- default null
  new__object_type            alias for $2;  -- default ''acs_object''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__context_id             alias for $6;  -- default null
  new__title                  alias for $7;  -- default null
begin
  return acs_object__new(new__object_id, new__object_type, new__creation_date,
                         new__creation_user, new__creation_ip, new__context_id,
                         ''t'', new__title, null);
end;' language 'plpgsql';

drop function acs_object__name (integer);

create function acs_object__name (integer)
returns varchar as '
declare
  name__object_id        alias for $1;  
  object_name            varchar;  
  v_object_id            integer;
  obj_type               record;  
  obj                    record;      
begin
  -- Find the name function for this object, which is stored in the
  -- name_method column of acs_object_types. Starting with this
  -- object''s actual type, traverse the type hierarchy upwards until
  -- a non-null name_method value is found.
  --
  -- select name_method
  --  from acs_object_types
  -- start with object_type = (select object_type
  --                             from acs_objects o
  --                            where o.object_id = name__object_id)
  -- connect by object_type = prior supertype

  select title into object_name
  from acs_objects
  where object_id = name__object_id;

  if (object_name is not null) then
    return object_name;
  end if;

  for obj_type
  in select o2.name_method
        from acs_object_types o1, acs_object_types o2
       where o1.object_type = (select object_type
                                 from acs_objects o
                                where o.object_id = name__object_id)
         and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
    order by o2.tree_sortkey desc
  loop
   if obj_type.name_method != '''' and obj_type.name_method is NOT null then

    -- Execute the first name_method we find (since we''re traversing
    -- up the type hierarchy from the object''s exact type) using
    -- Native Dynamic SQL, to ascertain the name of this object.
    --
    --execute ''select '' || object_type.name_method || ''(:1) from dual''

    for obj in execute ''select '' || obj_type.name_method || ''('' || name__object_id || '')::varchar as object_name'' loop
        object_name := obj.object_name;
        exit;
    end loop;

    exit;
   end if;
  end loop;

  return object_name;
  
end;' language 'plpgsql' stable strict;

-- function package_id
create or replace function acs_object__package_id (integer)
returns integer as '
declare
  p_object_id  alias for $1;
  v_package_id acs_objects.package_id%TYPE;
begin
  if p_object_id is null then
    return null;
  end if;

  select package_id into v_package_id
  from acs_objects
  where object_id = p_object_id;

  return v_package_id;
end;' language 'plpgsql' stable strict;


-------
-- Acs_Rels
-------

drop function acs_rel__new (integer,varchar,integer,integer,integer,integer,varchar);

create function acs_rel__new (integer,varchar,integer,integer,integer,integer,varchar)
returns integer as '
declare
  new__rel_id            alias for $1;  -- default null  
  new__rel_type          alias for $2;  -- default ''relationship''
  new__object_id_one     alias for $3;  
  new__object_id_two     alias for $4;  
  context_id             alias for $5;  -- default null
  creation_user          alias for $6;  -- default null
  creation_ip            alias for $7;  -- default null
  v_rel_id               acs_rels.rel_id%TYPE;
begin
    -- XXX This should check that object_id_one and object_id_two are
    -- of the appropriate types.
    v_rel_id := acs_object__new (
      new__rel_id,
      new__rel_type,
      now(),
      creation_user,
      creation_ip,
      context_id,
      ''t'',
      new__rel_type || '': '' || new__object_id_one || '' - '' || new__object_id_two,
      null
    );

    insert into acs_rels
     (rel_id, rel_type, object_id_one, object_id_two)
    values
     (v_rel_id, new__rel_type, new__object_id_one, new__object_id_two);

    return v_rel_id;
   
end;' language 'plpgsql';

---------
-- APM
---------

drop function apm__register_parameter (integer,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer);

create or replace function apm__register_parameter (integer,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  register_parameter__parameter_id           alias for $1;  -- default null  
  register_parameter__package_key            alias for $2;  
  register_parameter__parameter_name         alias for $3;  
  register_parameter__description            alias for $4;  -- default null  
  register_parameter__datatype               alias for $5;  -- default ''string''  
  register_parameter__default_value          alias for $6;  -- default null  
  register_parameter__section_name           alias for $7;  -- default null 
  register_parameter__min_n_values           alias for $8;  -- default 1
  register_parameter__max_n_values           alias for $9;  -- default 1

  v_parameter_id         apm_parameters.parameter_id%TYPE;
  v_value_id             apm_parameter_values.value_id%TYPE;
  v_pkg                  record;

begin
    -- Create the new parameter.    
    v_parameter_id := acs_object__new(
       register_parameter__parameter_id,
       ''apm_parameter'',
       now(),
       null,
       null,
       null,
       ''t'',
       register_parameter__package_key || '' - '' || register_parameter__parameter_name,
       null
    );
    
    insert into apm_parameters 
    (parameter_id, parameter_name, description, package_key, datatype, 
    default_value, section_name, min_n_values, max_n_values)
    values
    (v_parameter_id, register_parameter__parameter_name, 
     register_parameter__description, register_parameter__package_key, 
     register_parameter__datatype, register_parameter__default_value, 
     register_parameter__section_name, register_parameter__min_n_values, 
     register_parameter__max_n_values);

    -- Propagate parameter to new instances.	
    for v_pkg in
        select package_id
	from apm_packages
	where package_key = register_parameter__package_key
      loop
      	v_value_id := apm_parameter_value__new(
	    null,
	    v_pkg.package_id,
	    v_parameter_id, 
	    register_parameter__default_value
	    ); 	
      end loop;		
	
    return v_parameter_id;
   
end;' language 'plpgsql';


create or replace function apm__register_package (varchar,varchar,varchar,varchar,varchar,boolean,boolean,varchar,integer)
returns integer as '
declare
  package_key            alias for $1;  
  pretty_name            alias for $2;  
  pretty_plural          alias for $3;  
  package_uri            alias for $4;  
  package_type           alias for $5;  
  initial_install_p      alias for $6;  -- default ''f''  
  singleton_p            alias for $7;  -- default ''f''  
  spec_file_path         alias for $8;  -- default null
  spec_file_mtime        alias for $9;  -- default null
begin
    PERFORM apm_package_type__create_type(
    	package_key,
	pretty_name,
	pretty_plural,
	package_uri,
	package_type,
	initial_install_p,
	singleton_p,
	spec_file_path,
	spec_file_mtime
    );

    return 0; 
end;' language 'plpgsql';

drop function apm__update_parameter (integer,varchar,varchar,varchar,varchar,varchar,integer,integer);

create or replace function apm__update_parameter (integer,varchar,varchar,varchar,varchar,varchar,integer,integer)
returns varchar as '
declare
  update_parameter__parameter_id           alias for $1;  
  update_parameter__parameter_name         alias for $2;  -- default null  
  update_parameter__description            alias for $3;  -- default null
  update_parameter__datatype               alias for $4;  -- default ''string''
  update_parameter__default_value          alias for $5;  -- default null
  update_parameter__section_name           alias for $6;  -- default null
  update_parameter__min_n_values           alias for $7;  -- default 1
  update_parameter__max_n_values           alias for $8;  -- default 1
begin
    update apm_parameters 
	set parameter_name = coalesce(update_parameter__parameter_name, parameter_name),
            default_value  = coalesce(update_parameter__default_value, default_value),
            datatype       = coalesce(update_parameter__datatype, datatype), 
	    description	   = coalesce(update_parameter__description, description),
	    section_name   = coalesce(update_parameter__section_name, section_name),
            min_n_values   = coalesce(update_parameter__min_n_values, min_n_values),
            max_n_values   = coalesce(update_parameter__max_n_values, max_n_values)
      where parameter_id = update_parameter__parameter_id;

    update acs_objects
       set title = (select package_key || '': Parameter '' || parameter_name
                    from apm_parameters
                    where parameter_id = update_parameter__parameter_id)
     where object_id = update_parameter__parameter_id;

    return parameter_id;
     
end;' language 'plpgsql';

drop function apm_package__new (integer,varchar,varchar,varchar,timestamptz,integer,varchar,integer);
create or replace function apm_package__new (integer,varchar,varchar,varchar,timestamptz,integer,varchar,integer)
returns integer as '
declare
  new__package_id             alias for $1;  -- default null  
  new__instance_name          alias for $2;  -- default null
  new__package_key            alias for $3;  
  new__object_type            alias for $4;  -- default ''apm_package''
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__creation_ip            alias for $7;  -- default null
  new__context_id             alias for $8;  -- default null
  v_singleton_p               integer;       
  v_package_type              apm_package_types.package_type%TYPE;
  v_num_instances             integer;       
  v_package_id                apm_packages.package_id%TYPE;
  v_instance_name             apm_packages.instance_name%TYPE;
begin
   v_singleton_p := apm_package__singleton_p(
			new__package_key
		    );
   v_num_instances := apm_package__num_instances(
			new__package_key
		    );
  
   if v_singleton_p = 1 and v_num_instances >= 1 then
       select package_id into v_package_id 
       from apm_packages
       where package_key = new__package_key;

       return v_package_id;
   else
       v_package_id := acs_object__new(
          new__package_id,
          new__object_type,
          new__creation_date,
          new__creation_user,
	  new__creation_ip,
	  new__context_id
	 );
       if new__instance_name is null or new__instance_name = '''' then 
	 v_instance_name := new__package_key || '' '' || v_package_id;
       else
	 v_instance_name := new__instance_name;
       end if;

       select package_type into v_package_type
       from apm_package_types
       where package_key = new__package_key;

       insert into apm_packages
       (package_id, package_key, instance_name)
       values
       (v_package_id, new__package_key, v_instance_name);

       update acs_objects
       set title = v_instance_name,
           package_id = v_package_id
       where object_id = v_package_id;

       if v_package_type = ''apm_application'' then
	   insert into apm_applications
	   (application_id)
	   values
	   (v_package_id);
       else
	   insert into apm_services
	   (service_id)
	   values
	   (v_package_id);
       end if;

       PERFORM apm_package__initialize_parameters(
	   v_package_id,
	   new__package_key
       );

       return v_package_id;

  end if;
end;' language 'plpgsql';

drop function apm_package_version__new (integer,varchar,varchar,varchar,varchar,varchar,varchar,timestamptz,varchar,varchar,varchar,boolean,boolean);

create or replace function apm_package_version__new (integer,varchar,varchar,varchar,varchar,varchar,varchar,timestamptz,varchar,varchar,varchar,boolean,boolean) returns integer as '
declare
      apm_pkg_ver__version_id           alias for $1;  -- default null
      apm_pkg_ver__package_key		alias for $2;
      apm_pkg_ver__version_name		alias for $3;  -- default null
      apm_pkg_ver__version_uri		alias for $4;
      apm_pkg_ver__summary              alias for $5;
      apm_pkg_ver__description_format	alias for $6;
      apm_pkg_ver__description		alias for $7;
      apm_pkg_ver__release_date		alias for $8;
      apm_pkg_ver__vendor               alias for $9;
      apm_pkg_ver__vendor_uri		alias for $10;
      apm_pkg_ver__auto_mount           alias for $11;
      apm_pkg_ver__installed_p		alias for $12; -- default ''f''		
      apm_pkg_ver__data_model_loaded_p	alias for $13; -- default ''f''
      v_version_id                      apm_package_versions.version_id%TYPE;
begin
      if apm_pkg_ver__version_id is null then
         select nextval(''t_acs_object_id_seq'')
	 into v_version_id
	 from dual;
      else
         v_version_id := apm_pkg_ver__version_id;
      end if;

      v_version_id := acs_object__new(
		v_version_id,
		''apm_package_version'',
                now(),
                null,
                null,
                null,
                ''t'',
                apm_pkg_ver__package_key || '', Version '' || apm_pkg_ver__version_name,
                null
        );

      insert into apm_package_versions
      (version_id, package_key, version_name, version_uri, summary, description_format, description,
      release_date, vendor, vendor_uri, auto_mount, installed_p, data_model_loaded_p)
      values
      (v_version_id, apm_pkg_ver__package_key, apm_pkg_ver__version_name, 
       apm_pkg_ver__version_uri, apm_pkg_ver__summary, 
       apm_pkg_ver__description_format, apm_pkg_ver__description,
       apm_pkg_ver__release_date, apm_pkg_ver__vendor, apm_pkg_ver__vendor_uri, apm_pkg_ver__auto_mount,
       apm_pkg_ver__installed_p, apm_pkg_ver__data_model_loaded_p);

      return v_version_id;		
  
end;' language 'plpgsql';

drop function apm_package_version__copy (integer,integer,varchar,varchar,boolean);

create or replace function apm_package_version__copy (integer,integer,varchar,varchar,boolean)
returns integer as '
declare
  copy__version_id             alias for $1;  
  copy__new_version_id         alias for $2;  -- default null  
  copy__new_version_name       alias for $3;  
  copy__new_version_uri        alias for $4;  
  copy__copy_owners_p          alias for $5;
  v_version_id                 integer;       
begin
	v_version_id := acs_object__new(
		copy__new_version_id,
		''apm_package_version'',
                now(),
                null,
                null,
                null
        );    

	insert into apm_package_versions(version_id, package_key, version_name,
					version_uri, summary, description_format, description,
					release_date, vendor, vendor_uri, auto_mount)
	    select v_version_id, package_key, copy__new_version_name,
		   copy__new_version_uri, summary, description_format, description,
		   release_date, vendor, vendor_uri, auto_mount
	    from apm_package_versions
	    where version_id = copy__version_id;
    
        update acs_objects
        set title = (select v.package_key || '', Version '' || v.version_name
                     from apm_package_versions v
                     where v.version_id = copy__version_id)
        where object_id = copy__version_id;

	insert into apm_package_dependencies(dependency_id, version_id, dependency_type, service_uri, service_version)
	    select nextval(''t_acs_object_id_seq''), v_version_id, dependency_type, service_uri, service_version
	    from apm_package_dependencies
	    where version_id = copy__version_id;
    
        insert into apm_package_callbacks (version_id, type, proc)
                select v_version_id, type, proc
                from apm_package_callbacks
                where version_id = copy__version_id;
    
        if copy__copy_owners_p then
            insert into apm_package_owners(version_id, owner_uri, owner_name, sort_key)
                select v_version_id, owner_uri, owner_name, sort_key
                from apm_package_owners
                where version_id = copy__version_id;
        end if;
    
	return v_version_id;
   
end;' language 'plpgsql';

-----------
-- Authentication
-----------

drop function authority__new (integer,varchar,varchar,varchar,boolean,integer,integer,integer,varchar,varchar,integer,varchar,varchar,integer,varchar,integer);

create or replace function authority__new (
    integer, -- authority_id
    varchar, -- object_type
    varchar, -- short_name
    varchar, -- pretty_name
    boolean, -- enabled_p
    integer, -- sort_order
    integer, -- auth_impl_id
    integer, -- pwd_impl_id
    varchar, -- forgotten_pwd_url
    varchar, -- change_pwd_url
    integer, -- register_impl_id
    varchar, -- register_url
    varchar, -- help_contact_text
    integer, -- creation_user
    varchar, -- creation_ip
    integer  -- context_id
)
returns integer as '
declare
    p_authority_id alias for $1; -- default null,
    p_object_type alias for $2; -- default ''authority''
    p_short_name alias for $3;
    p_pretty_name alias for $4;
    p_enabled_p alias for $5; -- default ''t''
    p_sort_order alias for $6;
    p_auth_impl_id alias for $7; -- default null
    p_pwd_impl_id alias for $8; -- default null
    p_forgotten_pwd_url alias for $9; -- default null
    p_change_pwd_url alias for $10; -- default null
    p_register_impl_id alias for $11; -- default null
    p_register_url alias for $12; -- default null
    p_help_contact_text alias for $13; -- default null,
    p_creation_user alias for $14; -- default null
    p_creation_ip alias for $15; -- default null
    p_context_id alias for $16; -- default null
  
    v_authority_id           integer;
    v_object_type            varchar;    
    v_sort_order             integer;
  
begin
    if p_object_type is null then
        v_object_type := ''authority'';
    else
        v_object_type := p_object_type;
    end if;

    if p_sort_order is null then
          select into v_sort_order max(sort_order) + 1
                         from auth_authorities;
    else
        v_sort_order := p_sort_order;
    end if;

    -- Instantiate the ACS Object super type with auditing info
    v_authority_id  := acs_object__new(
        p_authority_id,
        v_object_type,
        now(),
        p_creation_user,
        p_creation_ip,
        p_context_id,
        ''t'',
        p_short_name,
        null
    );

    insert into auth_authorities (authority_id, short_name, pretty_name, enabled_p, 
                                  sort_order, auth_impl_id, pwd_impl_id, 
                                  forgotten_pwd_url, change_pwd_url, register_impl_id,
                                  help_contact_text)
    values (v_authority_id, p_short_name, p_pretty_name, p_enabled_p, 
                                  v_sort_order, p_auth_impl_id, p_pwd_impl_id, 
                                  p_forgotten_pwd_url, p_change_pwd_url, p_register_impl_id,
                                  p_help_contact_text);

   return v_authority_id;
end;
' language 'plpgsql';


-------------------
-- PARTY PACKAGE --
-------------------

drop function party__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,integer);

create or replace function party__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,integer)
returns integer as '
declare
  new__party_id               alias for $1;  -- default null  
  new__object_type            alias for $2;  -- default ''party''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__email                  alias for $6;  
  new__url                    alias for $7;  -- default null
  new__context_id             alias for $8;  -- default null
  v_party_id                  parties.party_id%TYPE;
begin
  v_party_id :=
   acs_object__new(new__party_id, new__object_type, new__creation_date, 
                   new__creation_user, new__creation_ip, new__context_id,
                   ''t'', new__email, null);

  insert into parties
   (party_id, email, url)
  values
   (v_party_id, lower(new__email), new__url);

  return v_party_id;
  
end;' language 'plpgsql';

--------------------
-- PERSON PACKAGE --
--------------------

drop function person__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,varchar,integer);

create or replace function person__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,varchar,integer)
returns integer as '
declare
  new__person_id              alias for $1;  -- default null  
  new__object_type            alias for $2;  -- default ''person''
  new__creation_date          alias for $3;  -- default now()
  new__creation_user          alias for $4;  -- default null
  new__creation_ip            alias for $5;  -- default null
  new__email                  alias for $6;  
  new__url                    alias for $7;  -- default null
  new__first_names            alias for $8; 
  new__last_name              alias for $9;  
  new__context_id             alias for $10; -- default null 
  v_person_id                 persons.person_id%TYPE;
begin
  v_person_id :=
   party__new(new__person_id, new__object_type,
             new__creation_date, new__creation_user, new__creation_ip,
             new__email, new__url, new__context_id);

  update acs_objects
  set title = new__first_names || '' '' || new__last_name
  where object_id = v_person_id;

  insert into persons
   (person_id, first_names, last_name)
  values
   (v_person_id, new__first_names, new__last_name);

  return v_person_id;
  
end;' language 'plpgsql';

---------
-- Acs Groups
---------

drop function acs_group__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,varchar,integer);

create or replace function acs_group__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,varchar,integer)
returns integer as '
declare
  new__group_id              alias for $1;  -- default null  
  new__object_type           alias for $2;  -- default ''group''
  new__creation_date         alias for $3;  -- default now()
  new__creation_user         alias for $4;  -- default null
  new__creation_ip           alias for $5;  -- default null
  new__email                 alias for $6;  -- default null
  new__url                   alias for $7;  -- default null
  new__group_name            alias for $8;  
  new__join_policy           alias for $9;  -- default null
  new__context_id            alias for $10; -- default null
  v_group_id                 groups.group_id%TYPE;
  v_group_type_exists_p      integer;
  v_join_policy              groups.join_policy%TYPE;
begin
  v_group_id :=
   party__new(new__group_id, new__object_type, new__creation_date, 
              new__creation_user, new__creation_ip, new__email, 
              new__url, new__context_id);

  v_join_policy := new__join_policy;

  -- if join policy was not specified, select the default based on group type
  if v_join_policy is null or v_join_policy = '''' then
      select count(*) into v_group_type_exists_p
      from group_types
      where group_type = new__object_type;

      if v_group_type_exists_p = 1 then
          select default_join_policy into v_join_policy
          from group_types
          where group_type = new__object_type;
      else
          v_join_policy := ''open'';
      end if;
  end if;

  update acs_objects
  set title = new__group_name
  where object_id = v_group_id;

  insert into groups
   (group_id, group_name, join_policy)
  values
   (v_group_id, new__group_name, v_join_policy);

  -- setup the permissible relationship types for this group

  -- DRB: we have to call nextval() directly because the select may
  -- return more than one row.  The sequence hack will only compute
  -- one nextval value causing the insert to fail ("may" in PG, which
  -- is actually broken.  It should ALWAYS return exactly one value for
  -- the view.  In PG it may or may not depending on the optimizer''s
  -- mood.  PG group seems uninterested in acknowledging the fact that
  -- this is a bug)

  insert into group_rels
  (group_rel_id, group_id, rel_type)
  select nextval(''t_acs_object_id_seq''), v_group_id, g.rel_type
    from group_type_rels g
   where g.group_type = new__object_type;

  return v_group_id;
  
end;' language 'plpgsql';

--------
-- Journal
--------

drop function journal_entry__new (integer,integer,varchar,varchar,timestamptz,integer,varchar,varchar);

create function journal_entry__new (integer,integer,varchar,varchar,timestamptz,integer,varchar,varchar)
returns integer as '
declare
  new__journal_id             alias for $1;  -- default null  
  new__object_id              alias for $2;  
  new__action                 alias for $3;  
  new__action_pretty          alias for $4;  -- default null
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__creation_ip            alias for $7;  -- default null
  new__msg                    alias for $8;  -- default null
  v_journal_id                journal_entries.journal_id%TYPE;
begin
	v_journal_id := acs_object__new (
	  new__journal_id,
	  ''journal_entry'',
	  new__creation_date,
	  new__creation_user,
	  new__creation_ip,
	  new__object_id,
          ''t'',
          new__action,
          null
	);

        insert into journal_entries (
            journal_id, object_id, action, action_pretty, msg
        ) values (
            v_journal_id, new__object_id, new__action, 
            new__action_pretty, new__msg
        );

        return v_journal_id;
     
end;' language 'plpgsql';

--------
-- Rel Segments
--------

drop function rel_segment__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,integer,varchar,integer);

create or replace function rel_segment__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,integer,varchar,integer)
returns integer as '
declare
  new__segment_id        alias for $1;  -- default null  
  object_type            alias for $2;  -- default ''rel_segment''
  creation_date          alias for $3;  -- default now()
  creation_user          alias for $4;  -- default null
  creation_ip            alias for $5;  -- default null
  email                  alias for $6;  -- default null
  url                    alias for $7;  -- default null
  new__segment_name      alias for $8;  
  new__group_id          alias for $9;  
  new__rel_type          alias for $10; 
  context_id             alias for $11; -- default null
  v_segment_id           rel_segments.segment_id%TYPE;
begin
  v_segment_id :=
   party__new(new__segment_id, object_type, creation_date, creation_user,
             creation_ip, email, url, context_id);

  update acs_objects
  set title = new__segment_name
  where object_id = v_segment_id;

  insert into rel_segments
   (segment_id, segment_name, group_id, rel_type)
  values
   (v_segment_id, new__segment_name, new__group_id, new__rel_type);

  return v_segment_id;
  
end;' language 'plpgsql';

--------
-- Rel Constraints
--------

drop function rel_constraint__new (integer,varchar,varchar,integer,char,integer,integer,integer,varchar);

create or replace function rel_constraint__new (integer,varchar,varchar,integer,char,integer,integer,integer,varchar)
returns integer as '
declare
  new__constraint_id          alias for $1;  -- default null  
  new__constraint_type        alias for $2;  -- default ''rel_constraint''
  new__constraint_name        alias for $3;  
  new__rel_segment            alias for $4;  
  new__rel_side               alias for $5;  -- default ''two''
  new__required_rel_segment   alias for $6;  
  new__context_id             alias for $7;  -- default null
  new__creation_user          alias for $8;  -- default null
  new__creation_ip            alias for $9;  -- default null
  v_constraint_id             rel_constraints.constraint_id%TYPE;
begin
    v_constraint_id := acs_object__new (
      new__constraint_id,
      new__constraint_type,
      now(),
      new__creation_user,
      new__creation_ip,
      new__context_id,
      ''t'',
      new__constraint_name,
      null
    );

    insert into rel_constraints
     (constraint_id, constraint_name, 
      rel_segment, rel_side, required_rel_segment)
    values
     (v_constraint_id, new__constraint_name, 
      new__rel_segment, new__rel_side, new__required_rel_segment);

     return v_constraint_id;
   
end;' language 'plpgsql';

--------
-- Site Nodes
--------

drop function site_node__new (integer,integer,varchar,integer,boolean,boolean,integer,varchar);

create or replace function site_node__new (integer,integer,varchar,integer,boolean,boolean,integer,varchar)
returns integer as '
declare
  new__node_id                alias for $1;  -- default null  
  new__parent_id              alias for $2;  -- default null    
  new__name                   alias for $3;  
  new__object_id              alias for $4;   -- default null   
  new__directory_p            alias for $5;  
  new__pattern_p              alias for $6;   -- default ''f'' 
  new__creation_user          alias for $7;   -- default null   
  new__creation_ip            alias for $8;   -- default null   
  v_node_id                   site_nodes.node_id%TYPE;
  v_directory_p               site_nodes.directory_p%TYPE;
begin
    if new__parent_id is not null then
      select directory_p into v_directory_p
      from site_nodes
      where node_id = new__parent_id;

      if v_directory_p = ''f'' then
        raise EXCEPTION ''-20000: Node % is not a directory'', new__parent_id;
      end if;
    end if;

    v_node_id := acs_object__new (
      new__node_id,
      ''site_node'',
      now(),
      new__creation_user,
      new__creation_ip,
      null,
      ''t'',
      new__name,
      new__object_id
    );

    insert into site_nodes
     (node_id, parent_id, name, object_id, directory_p, pattern_p)
    values
     (v_node_id, new__parent_id, new__name, new__object_id,
      new__directory_p, new__pattern_p);

     return v_node_id;
   
end;' language 'plpgsql';
