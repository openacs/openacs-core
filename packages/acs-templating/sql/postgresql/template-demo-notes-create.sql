--
-- packages/notes/sql/notes-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-10-22
-- @cvs-id $Id$
--
-- openacs port: vinod kurup vkurup@massmed.org
--

create function inline_0 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
    ''template_demo_note'',     -- object_type
    ''Template Demo Note'',     -- pretty_name
    ''Template Demo Notes'',    -- pretty_plural
    ''acs_object'',             -- supertype
    ''template_demo_notes'',    -- table_name
    ''template_demo_note_id'',  -- id_column
    null,                       -- package_name
    ''f'',                      -- abstract_p
    null,                       -- type_extension_table
    ''template_demo_note.name'' -- name_method
    );

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

create function inline_1 ()
returns integer as '
begin
    PERFORM acs_attribute__create_attribute (
      ''template_demo_note'',  -- object_type
      ''title'',               -- attribute_name
      ''string'',              -- datatype
      ''Title'',               -- pretty_name
      ''Titles'',              -- pretty_plural
      null,                    -- table_name
      null,                    -- column_name
      null,                    -- default_value
      1,                       -- min_n_values
      1,                       -- max_n_values
      null,                    -- sort_order
      ''type_specific'',       -- storage
      ''f''                    -- static_p
    );

    PERFORM acs_attribute__create_attribute (
      ''template_demo_note'',  -- object_type
      ''body'',                -- attribute_name
      ''string'',              -- datatype
      ''Body'',                -- pretty_name
      ''Bodies'',              -- pretty_plural
      null,                    -- table_name
      null,                    -- column_name
      null,                    -- default_value
      1,                       -- min_n_values
      1,                       -- max_n_values
      null,                    -- sort_order
      ''type_specific'',       -- storage
      ''f''                    -- static_p
    );

    PERFORM acs_attribute__create_attribute (
      ''template_demo_note'',  -- object_type
      ''color'',               -- attribute_name
      ''string'',              -- datatype
      ''Color'',               -- pretty_name
      ''Colors'',              -- pretty_plural
      null,                    -- table_name
      null,                    -- column_name
      null,                    -- default_value
      1,                       -- min_n_values
      1,                       -- max_n_values
      null,                    -- sort_order
      ''type_specific'',       -- storage
      ''f''                    -- static_p
    );

    return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();

create table template_demo_notes (
    template_demo_note_id
               integer 
               constraint template_demo_notes_note_id_fk
               references acs_objects(object_id) 
               constraint template_demo_notes_note_id_pk
               primary key,
    title      varchar(255) 
               constraint template_demo_notes_title_nn
               not null,
    body       text,
    color      text
);

select define_function_args('template_demo_note__new','template_demo_note_id,title,body,color,object_type;template_demo_note,creation_date;now,creation_user,creation_ip,context_id');

create function template_demo_note__new (integer,varchar,varchar,varchar,varchar,timestamptz,integer,varchar,integer)
returns integer as '
declare
  p_template_demo_note_id      alias for $1;  -- default null
  p_title                      alias for $2;
  p_body                       alias for $3;
  p_color                      alias for $4;
  p_object_type                alias for $5;  -- default ''template_demo_note''
  p_creation_date              alias for $6;  -- default now()
  p_creation_user              alias for $7;  -- default null
  p_creation_ip                alias for $8;  -- default null
  p_context_id                 alias for $9;  -- default null
  v_template_demo_note_id      template_demo_notes.template_demo_note_id%TYPE;
begin
    v_template_demo_note_id := acs_object__new (
        p_template_demo_note_id,
        p_object_type,
        p_creation_date,
        p_creation_user,
        p_creation_ip,
        p_context_id
    );

    insert into template_demo_notes
      (template_demo_note_id, title, body, color)
    values
      (v_template_demo_note_id, p_title, p_body, p_color);

    if p_creation_user is not null then
      PERFORM acs_permission__grant_permission(
            v_template_demo_note_id,
            p_creation_user,
            ''admin''
      );
    end if;

    return v_template_demo_note_id;

end;' language 'plpgsql';

select define_function_args('template_demo_note__del','template_demo_note_id');

create function template_demo_note__del (integer)
returns integer as '
declare
  p_template_demo_note_id                alias for $1;
begin
    delete from acs_permissions
           where object_id = p_template_demo_note_id;

    delete from template_demo_notes
           where template_demo_note_id = p_template_demo_note_id;

    raise NOTICE ''Deleting note...'';
    PERFORM acs_object__delete(p_template_demo_note_id);

    return 0;

end;' language 'plpgsql';

create function template_demo_note__name (integer)
returns varchar as '
declare
    p_template_demo_note_id      alias for $1;
    v_template_demo_note_name    template_demo_notes.title%TYPE;
begin
    select title into v_template_demo_note_name
        from template_demo_notes
        where template_demo_note_id = p_template_demo_note_id;

    return v_template_demo_note_name;
end;
' language 'plpgsql';


-- neophytosd

