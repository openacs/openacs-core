select define_function_args('content_keyword__new','heading,description,parent_id,keyword_id,creation_date;now,creation_user,creation_ip,object_type;content_keyword,package_id');

create or replace function inline_0() returns integer as '

declare v_row record;

begin

    for v_row in select o.object_type,o.table_name 
        from acs_object_type_supertype_map m,
	     acs_object_types o
        where m.ancestor_type=''content_revision''
        and o.object_type=m.object_type
    loop
	if table_exists(v_row.table_name) then 
            perform content_type__refresh_view(v_row.object_type);
	    perform content_type__refresh_trigger(v_row.object_type);
	end if;
    end loop;
return 0;
end;' language 'plpgsql';

select inline_0();

drop function inline_0();

-- add new versions of content_keyword__new that support package_id

create or replace function content_keyword__new (varchar,varchar,integer,integer,timestamptz,integer,varchar,varchar,integer)
returns integer as '
declare
  new__heading                alias for $1;  
  new__description            alias for $2;  -- default null  
  new__parent_id              alias for $3;  -- default null
  new__keyword_id             alias for $4;  -- default null
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__creation_ip            alias for $7;  -- default null
  new__object_type            alias for $8;  -- default ''content_keyword''
  new__package_id             alias for $9;  -- default null
  v_id                        integer;       
  v_package_id                acs_objects.package_id%TYPE;
begin

  if new__package_id is null then
    v_package_id := acs_object__package_id(new__parent_id);
  else
    v_package_id := new__package_id;
  end if;

  v_id := acs_object__new (new__keyword_id,
                           new__object_type,
                           new__creation_date, 
                           new__creation_user, 
                           new__creation_ip,
                           new__parent_id,
                           ''t'',
                           new__heading,
                           v_package_id
  );
    
  insert into cr_keywords 
    (heading, description, keyword_id, parent_id)
  values
    (new__heading, new__description, v_id, new__parent_id);

  return v_id;
 
end;' language 'plpgsql';

create or replace function content_keyword__new (varchar,varchar,integer,integer,timestamptz,integer,varchar,varchar)
returns integer as '
declare
  new__heading                alias for $1;  
  new__description            alias for $2;  -- default null  
  new__parent_id              alias for $3;  -- default null
  new__keyword_id             alias for $4;  -- default null
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__creation_ip            alias for $7;  -- default null
  new__object_type            alias for $8;  -- default ''content_keyword''
begin
  return content_keyword__new(new__heading,
                              new__description,
                              new__parent_id,
                              new__keyword_id,
                              new__creation_date,
                              new__creation_user,
                              new__creation_ip,
                              new__object_type,
                              null
  );

end;' language 'plpgsql';

