--
-- @author Lars Pind (lars@collaboraid.biz)
-- @creation-date 2003-07-03

-- Make groups registered users and the public closed (security)

update groups set join_policy = 'closed' where group_id in (-1,-2);

-- Make object_id 0 ("Unregistered Visitor") a user, not a person.

insert into users (user_id) values (0);
update acs_objects set object_type = 'user' where object_id = 0;


-- Add 'admin_rel' relationship type for administrators of a group

create table admin_rels (
        rel_id          integer constraint admin_rel_rel_id_fk
                        references membership_rels (rel_id)
                        constraint admin_rel_rel_id_pk
                        primary key
);

-- Create the admin role if it doesn't already exist
create function inline_0 ()
returns integer as '
declare
  v_role_exists_p    integer;
begin
  -- dotlrn may have created the admin role already
  select count(*) into v_role_exists_p
  from acs_rel_roles
  where role = ''admin'';

  if v_role_exists_p = 0 then
    PERFORM acs_rel_type__create_role (''admin'', ''Administrator'', ''Administrators'');
  end if;

  return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

select acs_rel_type__create_type (
   'admin_rel',                        -- rel_type
   'Administrator Relation',           -- pretty_name
   'Administrator Relationships',      -- pretty_plural
   'membership_rel',                   -- supertype
   'admin_rels',                       -- table_name
   'rel_id',                           -- id_column
   'admin_rel',                        -- package_name
   'group',                            -- object_type_one
   null,                               -- role_one
   0,                                  -- min_n_rels_one
   null,                               -- max_n_rels_one
   'person',                           -- object_type_two
   'admin',                            -- role_two
   0,                                  -- min_n_rels_two
   null                                -- max_n_rels_two   
);


-- create or replace package body admin_rel
-- function new
select define_function_args('admin_rel__new','rel_id,rel_type;admin_rel,object_id_one,object_id_two,member_state;approved,creation_user,creation_ip');

create or replace function admin_rel__new (integer,varchar,integer,integer,varchar,integer,varchar)
returns integer as '
declare
  p_rel_id               alias for $1;  -- default null  
  p_rel_type             alias for $2;  -- default ''admin_rel''
  p_object_id_one        alias for $3;  
  p_object_id_two        alias for $4;  
  p_member_state      alias for $5;  -- default ''approved''
  p_creation_user        alias for $6;  -- default null
  p_creation_ip          alias for $7;  -- default null
  v_rel_id               integer;       
begin
    v_rel_id := membership_rel__new (
      p_rel_id,           -- rel_id
      p_rel_type,         -- rel_type
      p_object_id_one,    -- object_id_one
      p_object_id_two,    -- object_id_two
      p_member_state,     -- member_state
      p_creation_user,    -- creation_usre
      p_creation_ip       -- creation_ip
    );

    insert into admin_rels
     (rel_id)
    values
     (v_rel_id);

    return v_rel_id;
   
end;' language 'plpgsql';

-- function new
create or replace function admin_rel__new (integer,integer)
returns integer as '
declare
  object_id_one          alias for $1;  
  object_id_two          alias for $2;  
begin
    return membership_rel__new(
        null,                  -- rel_id
        ''admin_rel'',         -- rel_type
        object_id_one,         -- object_id_one
        object_id_two,         -- object_id_two
        ''approved'',          -- member_state
        null,                  -- creation_user
        null                   -- creation_ip
    );
end;' language 'plpgsql';

-- procedure delete
create or replace function admin_rel__delete (integer)
returns integer as '
declare
  rel_id                 alias for $1;  
begin
    PERFORM membership_rel__delete(rel_id);

    return 0; 
end;' language 'plpgsql';


-- Internationalize role "member"
update acs_rel_roles
set pretty_name = '#acs-kernel.member_role_pretty_name#',
pretty_plural = '#acs-kernel.member_role_pretty_plural#'
where role = 'member';