--
-- packages/acs-subsite/sql/application_groups-create.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-02-02
-- @cvs-id $Id$
--

------------------------
-- APPLICATION GROUPS --
------------------------

select acs_object_type__create_type (
       'application_group',
       'Application Group',
       'Application Groups',
       'group',
       'application_groups',
       'group_id',
       'application_group',
       'f',
       'group_types',
       'acs_group__name'
);



create table application_groups (
	group_id		integer constraint application_groups_group_id_fk
				references groups (group_id)
				constraint application_groups_group_id_pk
				primary key,
        package_id              integer constraint application_groups_package_id_fk
                                references apm_packages,
                                constraint application_groups_package_id_un
                                unique (package_id)
);

select define_function_args('application_group__new','group_id,object_type;application_group,creation_date;now(),creation_user,creation_ip,email,url,group_name,package_id,context_id');

create function application_group__new(integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  new__group_id              alias for $1;
  new__object_type           alias for $2; -- default ''application_group'',
  new__creation_date         alias for $3; -- default sysdate,
  new__creation_user         alias for $4; -- default null,
  new__creation_ip           alias for $5; -- default null,
  new__email                 alias for $6; -- default null,
  new__url                   alias for $7; -- default null,
  new__group_name            alias for $8;
  new__package_id            alias for $9;
  new__context_id	     alias for $10; -- default null
  v_group_id		     application_groups.group_id%TYPE;
begin
  v_group_id := acs_group__new (
    new__group_id,
    new__object_type,
    new__creation_date,
    new__creation_user,
    new__creation_ip,
    new__email,
    new__url,
    new__group_name,
    null,
    new__context_id
  );

  insert into application_groups (group_id, package_id) 
    values (v_group_id, new__package_id);

  return v_group_id;

end;' language 'plpgsql';

create function application_group__delete(integer)
returns integer as '
declare
  group_id		alias for $1;
begin
    PERFORM acs_group__delete(group_id);

    return 0;
end;' language 'plpgsql';


create function application_group__group_id_from_package_id(integer,boolean)
returns integer as '
declare
  group_id_from_package_id__package_id    alias for $1;
  group_id_from_package_id__no_complain_p alias for $2; -- default ''f''
  v_group_id				  application_groups.group_id%TYPE;
  v_object_name				  varchar;
begin

  select group_id 
    into v_group_id
    from application_groups 
    where package_id = group_id_from_package_id__package_id;

-- TODO: does this shortcut the exception in Oracle?
--    return v_group_id;

  if not found then
    if group_id_from_package_id__no_complain_p != ''t'' then
      v_object_name := acs_object__name(group_id_from_package_id__package_id);
      raise EXCEPTION ''-20000: No group_id found for package % (%)'', group_id_from_package_id__package_id, v_object_name;
    end if;
    return null;
  else
    return v_group_id;
  end if;

end;' language 'plpgsql' stable;

insert into group_type_rels
(group_rel_type_id, group_type, rel_type)
values
(acs_object_id_seq.nextval, 'application_group', 'composition_rel');

insert into group_type_rels
(group_rel_type_id, group_type, rel_type)
values
(acs_object_id_seq.nextval, 'application_group', 'membership_rel');

insert into group_type_rels
(group_rel_type_id, group_type, rel_type)
values
(acs_object_id_seq.nextval, 'application_group', 'admin_rel');

-----------
-- Views --
-----------

create view application_group_element_map as
select g.package_id, g.group_id, 
       m.element_id, m.container_id, m.rel_id, m.rel_type, m.ancestor_rel_type
from application_groups g,
     group_element_map m
where g.group_id = m.group_id;

create view app_group_distinct_element_map as
select distinct package_id, group_id, element_id
from application_group_element_map;

create view app_group_distinct_rel_map as
select distinct package_id, group_id, rel_id, rel_type, ancestor_rel_type
from application_group_element_map;

create view application_group_segments as
select g.package_id, s.segment_id, s.group_id, s.rel_type, s.segment_name
from application_groups g,
     group_element_map m,
     rel_segments s
where g.group_id = m.group_id
  and m.element_id = s.group_id
UNION ALL
select g.package_id, s.segment_id, s.group_id, s.rel_type, s.segment_name
from application_groups g,
     rel_segments s
where g.group_id = s.group_id;
