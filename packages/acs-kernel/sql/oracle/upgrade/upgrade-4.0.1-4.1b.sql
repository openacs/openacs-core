--
-- /packages/acs-kernel/sql/upgrade/upgrade-4.0.1-4.0.2.sql
-- 
-- Upgrades ACS Kernel 4.0.1 to ACS Kernel 4.0.2
--
-- @author Multiple
-- @creation-date Wed Nov  1 10:32:08 2000
-- @cvs-id $Id$

-- security upgrade (richardl@arsdigita.com)

alter table sec_sessions drop primary key cascade;
alter table sec_session_properties add (last_hit integer);
drop table sec_sessions;
drop package sec;
alter sequence sec_id_seq increment by 100;


-- fixing two bugs in the package body.
-- version.new now uses the v_version_id it constructs.
-- The sortable_version_name procedure now fails gracefully.

create or replace package body apm_package_version 
as
    function new (
      version_id		in apm_package_versions.version_id%TYPE
				default null,
      package_key		in apm_package_versions.package_key%TYPE,
      version_name		in apm_package_versions.version_name%TYPE 
				default null,
      version_uri		in apm_package_versions.version_uri%TYPE,
      summary			in apm_package_versions.summary%TYPE,
      description_format	in apm_package_versions.description_format%TYPE,
      description		in apm_package_versions.description%TYPE,
      release_date		in apm_package_versions.release_date%TYPE,
      vendor			in apm_package_versions.vendor%TYPE,
      vendor_uri		in apm_package_versions.vendor_uri%TYPE,
      installed_p		in apm_package_versions.installed_p%TYPE
				default 'f',
      data_model_loaded_p	in apm_package_versions.data_model_loaded_p%TYPE
				default 'f'
    ) return apm_package_versions.version_id%TYPE
    is
      v_version_id apm_package_versions.version_id%TYPE;
    begin
      if version_id is null then
         select acs_object_id_seq.nextval
	 into v_version_id
	 from dual;
      else
         v_version_id := version_id;
      end if;
	v_version_id := acs_object.new(
		object_id => v_version_id,
		object_type => 'apm_package_version'
        );
      insert into apm_package_versions
      (version_id, package_key, version_name, version_uri, summary, description_format, description,
      release_date, vendor, vendor_uri, installed_p, data_model_loaded_p)
      values
      (v_version_id, package_key, version_name, version_uri,
       summary, description_format, description,
       release_date, vendor, vendor_uri,
       installed_p, data_model_loaded_p);
      return v_version_id;		
    end new;

    procedure delete (
      version_id		in apm_packages.package_id%TYPE
    )
    is
    begin
      delete from apm_package_owners 
      where version_id = apm_package_version.delete.version_id; 

      delete from apm_package_files
      where version_id = apm_package_version.delete.version_id;

      delete from apm_package_dependencies
      where version_id = apm_package_version.delete.version_id;

      delete from apm_package_versions 
	where version_id = apm_package_version.delete.version_id;

      acs_object.delete(apm_package_version.delete.version_id);

    end delete;

    procedure enable (
       version_id			in apm_package_versions.version_id%TYPE
    )
    is
    begin
      update apm_package_versions set enabled_p = 't'
      where version_id = enable.version_id;	
    end enable;
    
    procedure disable (
       version_id			in apm_package_versions.version_id%TYPE
    )
    is
    begin
      update apm_package_versions 
      set enabled_p = 'f'
      where version_id = disable.version_id;	
    end disable;


  function copy(
	version_id in apm_package_versions.version_id%TYPE,
	new_version_id in apm_package_versions.version_id%TYPE default null,
	new_version_name in apm_package_versions.version_name%TYPE,
	new_version_uri in apm_package_versions.version_uri%TYPE
  ) return apm_package_versions.version_id%TYPE
    is
	v_version_id integer;
    begin
	v_version_id := acs_object.new(
		object_id => new_version_id,
		object_type => 'apm_package_version'
        );    

	insert into apm_package_versions(version_id, package_key, version_name,
					version_uri, summary, description_format, description,
					release_date, vendor, vendor_uri)
	    select v_version_id, package_key, copy.new_version_name,
		   copy.new_version_uri, summary, description_format, description,
		   release_date, vendor, vendor_uri
	    from apm_package_versions
	    where version_id = copy.version_id;
    
	insert into apm_package_dependencies(dependency_id, version_id, dependency_type, service_uri, service_version)
	    select acs_object_id_seq.nextval, v_version_id, dependency_type, service_uri, service_version
	    from apm_package_dependencies
	    where version_id = copy.version_id;
    
	insert into apm_package_files(file_id, version_id, path, file_type)
	    select acs_object_id_seq.nextval, v_version_id, path, file_type
	    from apm_package_files
	    where version_id = copy.version_id;
    
	insert into apm_package_owners(version_id, owner_uri, owner_name, sort_key)
	    select v_version_id, owner_uri, owner_name, sort_key
	    from apm_package_owners
	    where version_id = copy.version_id;
    
	return v_version_id;
    end copy;
    
    function edit (
      new_version_id		in apm_package_versions.version_id%TYPE
				default null,
      version_id		in apm_package_versions.version_id%TYPE,
      version_name		in apm_package_versions.version_name%TYPE 
				default null,
      version_uri		in apm_package_versions.version_uri%TYPE,
      summary			in apm_package_versions.summary%TYPE,
      description_format	in apm_package_versions.description_format%TYPE,
      description		in apm_package_versions.description%TYPE,
      release_date		in apm_package_versions.release_date%TYPE,
      vendor			in apm_package_versions.vendor%TYPE,
      vendor_uri		in apm_package_versions.vendor_uri%TYPE,
      installed_p		in apm_package_versions.installed_p%TYPE
				default 'f',
      data_model_loaded_p	in apm_package_versions.data_model_loaded_p%TYPE
				default 'f'
    ) return apm_package_versions.version_id%TYPE
    is 
      v_version_id apm_package_versions.version_id%TYPE;
      version_unchanged_p integer;
    begin
       -- Determine if version has changed.
       select decode(count(*),0,0,1) into version_unchanged_p
       from apm_package_versions
       where version_id = edit.version_id
       and version_name = edit.version_name;
       if version_unchanged_p <> 1 then
         v_version_id := copy(
			 version_id => edit.version_id,
			 new_version_id => edit.new_version_id,
			 new_version_name => edit.version_name,
			 new_version_uri => edit.version_uri
			);
         else 
	   v_version_id := edit.version_id;			
       end if;
       
       update apm_package_versions 
		set version_uri = edit.version_uri,
		summary = edit.summary,
		description_format = edit.description_format,
		description = edit.description,
		release_date = trunc(sysdate),
		vendor = edit.vendor,
		vendor_uri = edit.vendor_uri,
		installed_p = edit.installed_p,
		data_model_loaded_p = edit.data_model_loaded_p
	    where version_id = v_version_id;
	return v_version_id;
    end edit;

  function add_file(
    file_id			in apm_package_files.file_id%TYPE
				default null,
    version_id			in apm_package_versions.version_id%TYPE,
    path			in apm_package_files.path%TYPE,
    file_type			in apm_package_file_types.file_type_key%TYPE
  ) return apm_package_files.file_id%TYPE
  is
    v_file_id apm_package_files.file_id%TYPE;
    v_file_exists_p integer;
  begin
	select file_id into v_file_id from apm_package_files
  	where version_id = add_file.version_id 
	and path = add_file.path;
        return v_file_id;
	exception 
	       when NO_DATA_FOUND
	       then
	       	if file_id is null then
	          select acs_object_id_seq.nextval into v_file_id from dual;
	        else
	          v_file_id := file_id;
	        end if;

  	        insert into apm_package_files 
		(file_id, version_id, path, file_type) 
		values 
		(v_file_id, add_file.version_id, add_file.path, add_file.file_type);
	        return v_file_id;
     end add_file;

  -- Remove a file from the indicated version.
  procedure remove_file(
    version_id			in apm_package_versions.version_id%TYPE,
    path			in apm_package_files.path%TYPE
  )
  is
  begin
    delete from apm_package_files 
    where version_id = remove_file.version_id
    and path = remove_file.path;
  end remove_file; 


-- Add an interface provided by this version.
  function add_interface(
    interface_id		in apm_package_dependencies.dependency_id%TYPE
			        default null,
    version_id			in apm_package_versions.version_id%TYPE,
    interface_uri		in apm_package_dependencies.service_uri%TYPE,
    interface_version		in apm_package_dependencies.service_version%TYPE
  ) return apm_package_dependencies.dependency_id%TYPE
  is
    v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      if add_interface.interface_id is null then
          select acs_object_id_seq.nextval into v_dep_id from dual;
      else
          v_dep_id := add_interface.interface_id;
      end if;
  
      insert into apm_package_dependencies
      (dependency_id, version_id, dependency_type, service_uri, service_version)
      values
      (v_dep_id, add_interface.version_id, 'provides', add_interface.interface_uri,
	add_interface.interface_version);
      return v_dep_id;
  end add_interface;

  procedure remove_interface(
    interface_id		in apm_package_dependencies.dependency_id%TYPE
  )
  is
  begin
    delete from apm_package_dependencies 
    where dependency_id = remove_interface.interface_id;
  end remove_interface;

  procedure remove_interface(
    interface_uri		in apm_package_dependencies.service_uri%TYPE,
    interface_version		in apm_package_dependencies.service_version%TYPE,
    version_id			in apm_package_versions.version_id%TYPE
  )
  is
      v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      select dependency_id into v_dep_id from apm_package_dependencies
      where service_uri = remove_interface.interface_uri 
      and interface_version = remove_interface.interface_version;
      remove_interface(v_dep_id);
  end remove_interface;

  -- Add a requirement for this version.  A requirement is some interface that this
  -- version depends on.
  function add_dependency(
    dependency_id		in apm_package_dependencies.dependency_id%TYPE
			        default null,
    version_id			in apm_package_versions.version_id%TYPE,
    dependency_uri		in apm_package_dependencies.service_uri%TYPE,
    dependency_version		in apm_package_dependencies.service_version%TYPE
  ) return apm_package_dependencies.dependency_id%TYPE
  is
    v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      if add_dependency.dependency_id is null then
          select acs_object_id_seq.nextval into v_dep_id from dual;
      else
          v_dep_id := add_dependency.dependency_id;
      end if;
  
      insert into apm_package_dependencies
      (dependency_id, version_id, dependency_type, service_uri, service_version)
      values
      (v_dep_id, add_dependency.version_id, 'requires', add_dependency.dependency_uri,
	add_dependency.dependency_version);
      return v_dep_id;
  end add_dependency;

  procedure remove_dependency(
    dependency_id		in apm_package_dependencies.dependency_id%TYPE
  )
  is
  begin
    delete from apm_package_dependencies 
    where dependency_id = remove_dependency.dependency_id;
  end remove_dependency;


  procedure remove_dependency(
    dependency_uri		in apm_package_dependencies.service_uri%TYPE,
    dependency_version		in apm_package_dependencies.service_version%TYPE,
    version_id			in apm_package_versions.version_id%TYPE
  )
  is
    v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      select dependency_id into v_dep_id from apm_package_dependencies 
      where service_uri = remove_dependency.dependency_uri 
      and service_version = remove_dependency.dependency_version;
      remove_dependency(v_dep_id);
  end remove_dependency;

   function sortable_version_name (
    version_name		in apm_package_versions.version_name%TYPE
  ) return varchar2
    is
	a_start integer;
	a_end   integer;
	a_order varchar2(1000);
	a_char  char(1);
	a_seen_letter char(1) := 'f';
    begin
	a_start := 1;
	loop
	    a_end := a_start;
    
	    -- keep incrementing a_end until we run into a non-number        
	    while substr(version_name, a_end, 1) >= '0' and substr(version_name, a_end, 1) <= '9' loop
		a_end := a_end + 1;
	    end loop;
	    if a_end = a_start then
	    	return -1;
		-- raise_application_error(-20000, 'Expected number at position ' || a_start);
	    end if;
	    if a_end - a_start > 4 then
	    	return -1;
		-- raise_application_error(-20000, 'Numbers within versions can only be up to 4 digits long');
	    end if;
    
	    -- zero-pad and append the number
	    a_order := a_order || substr('0000', 1, 4 - (a_end - a_start)) ||
		substr(version_name, a_start, a_end - a_start) || '.';
	    if a_end > length(version_name) then
		-- end of string - we're outta here
		if a_seen_letter = 'f' then
		    -- append the "final" suffix if there haven't been any letters
		    -- so far (i.e., not development/alpha/beta)
		    a_order := a_order || '  3F.';
		end if;
		return a_order;
	    end if;
    
	    -- what's the next character? if a period, just skip it
	    a_char := substr(version_name, a_end, 1);
	    if a_char = '.' then
		null;
	    else
		-- if the next character was a letter, append the appropriate characters
		if a_char = 'd' then
		    a_order := a_order || '  0D.';
		elsif a_char = 'a' then
		    a_order := a_order || '  1A.';
		elsif a_char = 'b' then
		    a_order := a_order || '  2B.';
		end if;
    
		-- can't have something like 3.3a1b2 - just one letter allowed!
		if a_seen_letter = 't' then
		    return -1;
		    -- raise_application_error(-20000, 'Not allowed to have two letters in version name '''
		    --	|| version_name || '''');
		end if;
		a_seen_letter := 't';
    
		-- end of string - we're done!
		if a_end = length(version_name) then
		    return a_order;
		end if;
	    end if;
	    a_start := a_end + 1;
	end loop;
    end sortable_version_name;

  function version_name_greater(
    version_name_one		in apm_package_versions.version_name%TYPE,
    version_name_two		in apm_package_versions.version_name%TYPE
  ) return integer is
	a_order_a varchar2(1000);
	a_order_b varchar2(1000);
    begin
	a_order_a := sortable_version_name(version_name_one);
	a_order_b := sortable_version_name(version_name_two);
	if a_order_a < a_order_b then
	    return -1;
	elsif a_order_a > a_order_b then
	    return 1;
	end if;
	return 0;
    end version_name_greater;

  function upgrade_p(
    path			in apm_package_files.path%TYPE,
    initial_version_name	in apm_package_versions.version_name%TYPE,
    final_version_name		in apm_package_versions.version_name%TYPE
   ) return integer
    is
	v_pos1 integer;
	v_pos2 integer;
	v_path apm_package_files.path%TYPE;
	v_version_from apm_package_versions.version_name%TYPE;
	v_version_to apm_package_versions.version_name%TYPE;
    begin

	-- Set v_path to the tail of the path (the file name).
	v_path := substr(upgrade_p.path, instr(upgrade_p.path, '/', -1) + 1);

	-- Remove the extension, if it's .sql.
	v_pos1 := instr(v_path, '.', -1);
	if v_pos1 > 0 and substr(v_path, v_pos1) = '.sql' then
	    v_path := substr(v_path, 1, v_pos1 - 1);
	end if;

	-- Figure out the from/to version numbers for the individual file.
	v_pos1 := instr(v_path, '-', -1, 2);
	v_pos2 := instr(v_path, '-', -1);
	if v_pos1 = 0 or v_pos2 = 0 then
	    -- There aren't two hyphens in the file name. Bail.
	    return 0;
	end if;

	v_version_from := substr(v_path, v_pos1 + 1, v_pos2 - v_pos1 - 1);
	v_version_to := substr(v_path, v_pos2 + 1);

	if version_name_greater(upgrade_p.initial_version_name, v_version_from) <= 0 and
	   version_name_greater(upgrade_p.final_version_name, v_version_to) >= 0 then
	    return 1;
	end if;

	return 0;
    exception when others then
	-- Invalid version number.
	return 0;
    end upgrade_p;
    
  procedure upgrade(
    version_id                  in apm_package_versions.version_id%TYPE
  )
  is
  begin
    update apm_package_versions
    	set enabled_p = 'f',
	    installed_p = 'f'
	where package_key = (select package_key from apm_package_versions
	    	    	     where version_id = upgrade.version_id);
    update apm_package_versions
    	set enabled_p = 't',
	    installed_p = 't'
	where version_id = upgrade.version_id;			  
    
  end upgrade;

end apm_package_version;
/
show errors


--------------------------------------
-- RELATIONAL SEGMENTATION UPGRADE
-- oumi@arsdigita.com
-- 1/5/2001
--------------------------------------

-- PATCH GROUPS SYSTEM based on changes to groups-create.sql

-- combine group_member_index and group_component_index into
-- group_element_index.  


create table group_element_index (
	group_id	not null
			constraint group_element_index_grp_id_fk
			references groups (group_id),
	element_id	not null
			constraint group_element_index_elem_id_fk
			references parties (party_id),
	rel_id		not null
			constraint group_element_index_rel_id_fk
			references acs_rels (rel_id),
	container_id	not null
			constraint group_element_index_cont_id_fk
			references groups (group_id),
        rel_type        not null
                        constraint group_elem_index_rel_type_fk
                        references acs_rel_types (rel_type),
        ancestor_rel_type varchar2(100) not null
                        constraint grp_el_idx_ancstr_rel_type_ck
                        check (ancestor_rel_type in ('composition_rel','membership_rel')),
	constraint group_element_index_pk
	primary key (element_id, group_id, rel_id)
) organization index;


comment on table group_element_index is '
 This table is for internal use by the parties system.  It as an auxiliary
 table, a denormalization of data, that is used to improve performance.
 Do not query on this table or insert into it.  Query on group_element_map
 instead.  And insert by using the API''s for membership_rel, composition_rel, 
 or some sub-type of those relationship types.
';

-- populate with data from group_member_map and group_component_map

insert into group_element_index
(group_id, element_id, rel_id, container_id, rel_type, ancestor_rel_type)
select gmm.group_id, gmm.member_id, gmm.rel_id, gmm.container_id,
       acs_rels.rel_type, 'membership_rel' as ancestor_rel_type
from group_member_map gmm,
     acs_rels
where gmm.rel_id = acs_rels.rel_id;

insert into group_element_index
(group_id, element_id, rel_id, container_id, rel_type, ancestor_rel_type)
select gcm.group_id, gcm.component_id, gcm.rel_id, gcm.container_id,
       acs_rels.rel_type, 'composition_rel' as ancestor_rel_type
from group_component_map gcm,
     acs_rels
where gcm.rel_id = acs_rels.rel_id;


create index group_elem_idx_group_idx on group_element_index (group_id);
create index group_elem_idx_element_idx on group_element_index (element_id);
create index group_elem_idx_rel_id_idx on group_element_index (rel_id);
create index group_elem_idx_container_idx on group_element_index (container_id);
create index group_elem_idx_rel_type_idx on group_element_index (rel_type);

-- create wrapper view for the above table.

create or replace view group_element_map
as select group_id, element_id, rel_id, container_id, 
          rel_type, ancestor_rel_type
   from group_element_index;


-- Re-write the group_member_map and group_component_map views
-- as wrappers around group_element_index.

create or replace view group_component_map
as select group_id, element_id as component_id, rel_id, container_id, rel_type
   from group_element_map
   where ancestor_rel_type='composition_rel';

create or replace view group_member_map
as select group_id, element_id as member_id, rel_id, container_id, rel_type
   from group_element_map
   where ancestor_rel_type='membership_rel';



-- replace function that queried directly on group_component_index

create or replace function group_contains_p (group_id integer, component_id integer, rel_id integer default null) return char
is
begin
  if group_id = component_id then
    return 't';
  else
    if rel_id is null then
      for map in (select *
                  from group_component_map
                  where component_id = group_contains_p.component_id
                  and group_id = container_id) loop
        if group_contains_p(group_id, map.group_id) = 't' then
          return 't';
        end if;
      end loop;
    else
      for map in (select *
                  from group_component_map
                  where component_id = group_contains_p.component_id
                  and rel_id = group_contains_p.rel_id
                  and group_id = container_id) loop
        if group_contains_p(group_id, map.group_id) = 't' then
          return 't';
        end if;
      end loop;
    end if;

    return 'f';
  end if;
end;
/
show errors


-- If we're really confident, then we can drop the group_member_index
-- and group_component_index. 
drop table group_component_index;
drop table group_member_index;

-- Just in case someone is still querying the group_component_index and
-- group_member_index directly, lets make them views.
create or replace view group_component_index as select * from group_component_map;
create or replace view group_member_index as select * from group_member_map;


----------------------------
-- CREATE REL SEGMENTS
-- oumi@arsdigita.com
-- 1/5/2001
-- Corresponding ACS File: ../rel-segments-create.sql
----------------------------
--
-- packages/acs-kernel/sql/rel-segments-create.sql
--
-- @author Oumi Mehrotra oumi@arsdigita.com
-- @creation-date 2000-11-22
-- @cvs-id $Id$

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- WARNING!
-- Relational segments is a new and experimental concept.  The API may
-- change in the future, particularly the functions marked "EXPERIMENTAL".
-- 

begin
 --
 -- Relational Segment: a dynamically derived set of parties, defined
 --                     in terms of a particular type of membership or 
 --                     composition to a particular group.
 --
 acs_object_type.create_type (
   supertype => 'party',
   object_type => 'rel_segment',
   pretty_name => 'Relational Party Segment',
   pretty_plural => 'Relational Party Segments',
   table_name => 'rel_segments',
   id_column => 'segment_id',
   package_name => 'rel_segment',
   type_extension_table => 'rel_segment',
   name_method => 'rel_segment.name'
 );

end;
/
show errors


-- Note that we do not use on delete cascade on the group_id or
-- rel_type column because rel_segments are acs_objects. On delete
-- cascade only deletes the corresponding row in this table, not all
-- the rows up the type hierarchy. Thus, rel segments must be deleted
-- using rel_segment.delete before dropping a relationship type.

create table rel_segments (
        segment_id      not null
                        constraint rel_segments_segment_id_fk
                        references parties (party_id)
                        constraint rel_segments_pk primary key,
        segment_name    varchar2(230) not null,
        group_id        not null
                        constraint rel_segments_group_id_fk
                        references groups (group_id),
        rel_type        not null
                        constraint rel_segments_rel_type_fk
                        references acs_rel_types (rel_type),
        constraint rel_segments_grp_rel_type_uq unique(group_id, rel_type)
);

-- rel_type has a foreign key reference - create an index
create index rel_segments_rel_type_idx on rel_segments(rel_type);

comment on table rel_segments is '
  Defines relational segments. Each relational segment is a pair of
  <code>group_id</code> / <code>rel_type</code>, or, in english, the
  parties that have a relation of type rel_type to group_id.
';

comment on column rel_segments.segment_name is '
  The user-entered name of the relational segment.
';

comment on column rel_segments.group_id is '
  The group for which this segment was created.
';

comment on column rel_segments.rel_type is '
  The relationship type used to define elements in this segment.
';


-- create pl/sql package rel_segment

create or replace package rel_segment
is
 function new (
  --/** Creates a new relational segment
  -- 
  --    @author Oumi Mehrotra (oumi@arsdigita.com)
  --    @creation-date 12/2000
  -- 
  --*/
  segment_id            in rel_segments.segment_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'rel_segment',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  segment_name          in rel_segments.segment_name%TYPE,
  group_id              in rel_segments.group_id%TYPE,
  rel_type              in rel_segments.rel_type%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 ) return rel_segments.segment_id%TYPE;

 procedure delete (
    --/** Deletes a relational segment
    -- 
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    -- 
    --*/
   segment_id     in rel_segments.segment_id%TYPE
 );

 function name (
  segment_id      in rel_segments.segment_id%TYPE
 ) return rel_segments.segment_name%TYPE;

 function get (
    --/** EXPERIMENTAL / UNSTABLE -- use at your own risk
    --    Get the id of a segment given a group_id and rel_type.
    --    This depends on the uniqueness of group_id,rel_type.  We
    --    might remove the unique constraint in the future, in which
    --    case we would also probably remove this function.
    --
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    --
    --*/

   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE
 ) return rel_segments.segment_id%TYPE;

 function get_or_new (
    --/** EXPERIMENTAL / UNSTABLE -- use at your own risk
    --
    --    This function simplifies the use of segments a little by letting
    --    you not have to worry about creating and initializing segments.
    --    If the segment you're interested in exists, this function
    --    returns its segment_id.
    --    If the segment you're interested in doesn't exist, this function
    --    does a pretty minimal amount of initialization for the segment
    --    and returns a new segment_id.
    --
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    --
    --*/
   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE,
   segment_name   in rel_segments.segment_name%TYPE
                  default null
 ) return rel_segments.segment_id%TYPE;

end rel_segment;
/
show errors


-----------
-- Views --
-----------

create or replace view rel_segment_party_map
as select rs.segment_id, gem.element_id as party_id, gem.rel_id, gem.rel_type, 
          gem.group_id, gem.container_id, gem.ancestor_rel_type
   from rel_segments rs, 
        (select ancestor_type, object_type
         from acs_object_type_supertype_map
         union
         select object_type, object_type
         from acs_object_types) otsm,
        group_element_map gem 
   where rs.rel_type = otsm.ancestor_type
     and otsm.object_type = gem.rel_type
     and gem.group_id = rs.group_id;


create or replace view rel_segment_distinct_party_map
as select distinct segment_id, party_id, ancestor_rel_type
   from rel_segment_party_map;

create or replace view rel_segment_member_map
as select segment_id, party_id as member_id, rel_id, rel_type, 
          group_id, container_id
   from rel_segment_party_map
   where ancestor_rel_type = 'membership_rel';

create or replace view rel_seg_approved_member_map
as select rspm.segment_id, rspm.party_id as member_id, rspm.rel_id,
          rspm.rel_type, rspm.group_id, rspm.container_id
   from rel_segment_party_map rspm, membership_rels mr
   where rspm.rel_id = mr.rel_id
     and mr.member_state = 'approved';

create or replace view rel_seg_distinct_member_map
as select distinct segment_id, member_id
   from rel_seg_approved_member_map;


-- party_member_map can be used to expand any party into its members.  
-- Every party is considered to be a member of itself.

-- By the way, aren't the party_member_map and party_approved_member_map 
-- views equivalent??  (TO DO: RESOLVE THIS QUESTION)

create or replace view party_member_map
as select segment_id as party_id, member_id
   from rel_seg_distinct_member_map
   union
   select group_id as party_id, member_id
   from group_distinct_member_map
   union
   select party_id, party_id as member_id
   from parties;

create or replace view party_approved_member_map
as select distinct segment_id as party_id, member_id
   from rel_seg_approved_member_map
   union
   select distinct group_id as party_id, member_id
   from group_approved_member_map
   union
   select party_id, party_id as member_id
   from parties;

-- party_element_map tells us all the parties that "belong to" a party,
-- whether through somet type of membership, composition, or identity.

create or replace view party_element_map
as select distinct group_id as party_id, element_id
   from group_element_map
   union
   select distinct segment_id as party_id, party_id as element_id
   from rel_segment_party_map
   union
   select party_id, party_id as element_id
   from parties;





----------------------------
-- RELATIONAL CONSTRAINTS --
-- oumi@arsdigita.com
-- 1/5/2001
-- Corresponding ACS File: ../rel-constraints-create
----------------------------
--
-- /packages/acs-kernel/sql/rel-constraints-create.sql
-- 
-- Add support for relational constraints based on relational segmentation.
--
-- @author Oumi Mehrotra (oumi@arsdigita.com)
-- @creation-date 2000-11-22
-- @cvs-id $Id$

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- WARNING!
-- Relational constraints is a new and experimental concept.  The API may
-- change in the future, particularly the functions marked "EXPERIMENTAL".
--

begin
    acs_object_type.create_type(
      object_type => 'rel_constraint',
      pretty_name => 'Relational Constraint',
      pretty_plural => 'Relational Constraints',
      supertype => 'acs_object',
      table_name => 'rel_constraints',
      id_column => 'constraint_id',
      package_name => 'rel_constraint'
    );
end;
/
show errors


create table rel_constraints (
    constraint_id		integer
				constraint rel_constraints_pk
					primary key
				constraint rc_constraint_id_fk
					references acs_objects(object_id),
    constraint_name		varchar(100) not null,
    rel_segment 		not null
				constraint rc_rel_segment_fk
					references rel_segments (segment_id),
    rel_side                    char(3) default 'two' not null
				constraint rc_rel_side_ck
					check (rel_side in
					('one', 'two')),
    required_rel_segment	not null
				constraint rc_required_rel_segment
					references rel_segments (segment_id),
    constraint rel_constraints_uq
	unique (rel_segment, rel_side, required_rel_segment)
);

-- required_rel_segment has a foreign key reference - create an index
create index rel_constraint_req_rel_seg_idx on rel_constraints(required_rel_segment)


comment on table rel_constraints is '
  Defines relational constraints. The relational constraints system is
  intended to support applications in modelling and applying
  constraint rules on inter-party relatinships based on relational
  party segmentation.
';


comment on column rel_constraints.constraint_name is '
  The user-defined name of this constraint.
';

comment on column rel_constraints.rel_segment is '
  The segment for which the constraint is defined.
';

comment on column rel_constraints.rel_side is '
  The side of the relation the constraint applies to.
';

comment on column rel_constraints.required_rel_segment is '
  The segment in which elements must be in to satisfy the constraint.
';



-----------
-- VIEWS --
-----------

-- View rel_constraints_violated_one
--
-- pseudo sql:
--
-- select all the side 'one' constraints
-- from the constraints and the associated relations of rel_segment
-- where the relation's container_id (i.e., object_id_one) is not in the 
-- relational segment required_rel_segment.

create or replace view rel_constraints_violated_one as
select constrained_rels.*
from (select rel_constraints.constraint_id, rel_constraints.constraint_name, 
             r.rel_id, r.container_id, r.party_id, r.rel_type, 
             rel_constraints.rel_segment,
             rel_constraints.rel_side, 
             rel_constraints.required_rel_segment
      from rel_constraints, rel_segment_party_map r
      where rel_constraints.rel_side = 'one'
        and rel_constraints.rel_segment = r.segment_id
     ) constrained_rels,
     rel_segment_party_map rspm
where rspm.segment_id(+) = constrained_rels.required_rel_segment
  and rspm.party_id(+) = constrained_rels.container_id
  and rspm.party_id is null;

-- Originally, we tried this view.  It was slow.  The one above is much
-- less slow.  It moves the "not exists" query to an outer join, checking
-- for null rows in the outer join table.  This turns out to be much faster
-- than "not exists".
--
-- create or replace view rel_constraints_violated_one as
-- select rel_constraints.constraint_id, rel_constraints.constraint_name, 
--        r.rel_id, r.container_id, r.party_id, r.rel_type, 
--        rel_constraints.rel_segment,
--        rel_constraints.rel_side, 
--        rel_constraints.required_rel_segment
-- from rel_constraints, rel_segment_party_map r
-- where rel_constraints.rel_side = 'one'
--   and rel_constraints.rel_segment = r.segment_id
--   and not exists (
--         select 1 from rel_segment_party_map rspm
--         where rspm.segment_id = rel_constraints.required_rel_segment
--           and rspm.party_id = r.container_id
--  );


-- View rel_constraints_violated_two
--
-- pseudo sql:
--
-- select all the side 'two' constraints
-- from the constraints and the associated relations of rel_segment
-- where the relation's party_id (i.e., object_id_two) is not in the 
-- relational segment required_rel_segment.

create or replace view rel_constraints_violated_two as
select constrained_rels.*
from (select rel_constraints.constraint_id, rel_constraints.constraint_name, 
             r.rel_id, r.container_id, r.party_id, r.rel_type, 
             rel_constraints.rel_segment,
             rel_constraints.rel_side, 
             rel_constraints.required_rel_segment
      from rel_constraints, rel_segment_party_map r
      where rel_constraints.rel_side = 'two'
        and rel_constraints.rel_segment = r.segment_id
     ) constrained_rels,
     rel_segment_party_map rspm
where rspm.segment_id(+) = constrained_rels.required_rel_segment
  and rspm.party_id(+) = constrained_rels.party_id
  and rspm.party_id is null;

-- Originally, we tried this view.  It was slow.  The one above is much
-- less slow.  It moves the "not exists" query to an outer join, checking
-- for null rows in the outer join table.  This turns out to be much faster
-- than "not exists".
--
-- create or replace view rel_constraints_violated_two as
-- select rel_constraints.constraint_id, rel_constraints.constraint_name, 
--        r.rel_id, r.container_id, r.party_id, r.rel_type, 
--        rel_constraints.rel_segment,
--        rel_constraints.rel_side, 
--        rel_constraints.required_rel_segment
-- from rel_constraints, rel_segment_party_map r
-- where rel_constraints.rel_side = 'two'
--   and rel_constraints.rel_segment = r.segment_id
--   and not exists (
--         select 1 from rel_segment_party_map rspm
--         where rspm.segment_id = rel_constraints.required_rel_segment
--           and rspm.party_id = r.party_id
--   );


-- View: rc_required_rel_segments
--
-- Question: Given group :group_id and rel_type :rel_type . . .
--
--           What segments must a party be in 
--           if the party were to be belong to group :group_id 
--           through a relation of type :rel_type ?
--
-- Answer:   select required_rel_segment
--           from rc_required_rel_segments
--           where group_id = :group_id
--             and rel_type = :rel_type
--

create or replace view rc_required_rel_segments as
                select group_ancestor_map.group_id, 
                       rel_segments.rel_type, 
                       required_rel_segment
                from (select component_id as group_id,
                             group_id as ancestor_group_id
                        from group_component_map
                      union
                      select group_id as component_group_id,
                             group_id as ancestor_group_id
                        from groups) group_ancestor_map,
                     rel_segments,
                     rel_constraints
                where rel_segments.group_id = group_ancestor_map.ancestor_group_id
                  and rel_constraints.rel_segment = rel_segments.segment_id
                  and rel_constraints.rel_side = 'two';

                    
-- View: rc_parties_in_required_segs
--
-- Question: Given group :group_id and rel_type :rel_type . . .
--
--           What parties are "allowed" to be in group :group_id
--           through a relation of type :rel_type ?  By "allowed",
--           we mean that no relational constraints would be violated.
--
-- Answer:   select party_id, acs_object.name(party_id)
--           from parties_in_rc_required_rel_segments
--           where group_id = :group_id
--             and rel_type = :rel_type
--
create or replace view rc_parties_in_required_segs as
select parties_in_required_segs.group_id,
       parties_in_required_segs.rel_type,
       parties_in_required_segs.party_id
from
   (select required_segs.group_id, 
           required_segs.rel_type, 
           seg_parties.party_id,
           count(*) as num_matching_segs
    from rc_required_rel_segments required_segs,
         rel_segment_party_map seg_parties
    where required_segs.required_rel_segment = seg_parties.segment_id
    group by required_segs.group_id, 
             required_segs.rel_type, 
             seg_parties.party_id) parties_in_required_segs,
   (select group_id, rel_type, count(*) as total
    from rc_required_rel_segments
    group by group_id, rel_type) total_num_required_segs
where
      parties_in_required_segs.group_id = total_num_required_segs.group_id
  and parties_in_required_segs.rel_type = total_num_required_segs.rel_type
  and parties_in_required_segs.num_matching_segs = total_num_required_segs.total
UNION ALL
select group_rel_type_party_combos.group_id,
       group_rel_type_party_combos.rel_type,
       parties.party_id
from rc_required_rel_segments, 
     (select groups.group_id, acs_rel_types.rel_type
      from groups, acs_rel_types) group_rel_type_party_combos,
     parties
where rc_required_rel_segments.group_id(+) = group_rel_type_party_combos.group_id
  and rc_required_rel_segments.rel_type(+) = group_rel_type_party_combos.rel_type
  and rc_required_rel_segments.group_id is null;


-- View: rc_violations_by_removing_rel
--
-- Question: Given relation :rel_id
--
--           If we were to remove the relation specified by rel_id, 
--           what constraints would be violated and by what parties?
--
-- Answer:   select r.rel_id, r.constraint_id, r.constraint_name
--	            acs_object_type.pretty_name(r.rel_type) as rel_type_pretty_name,
--	            acs_object.name(r.object_id_one) as object_id_one_name, 
--	            acs_object.name(r.object_id_two) as object_id_two_name
--	       from rc_violations_by_removing_rel r
--	      where r.segment_rel_id = :rel_id
--        

create or replace view rc_violations_by_removing_rel as
select r.rel_type as viol_rel_type, r.rel_id as viol_rel_id, 
       r.object_id_one as viol_object_id_one, r.object_id_two as viol_object_id_two,
       s.rel_id,
       cons.constraint_id, cons.constraint_name,
       map.segment_id, map.party_id, map.group_id, map.container_id, map.ancestor_rel_type
  from acs_rels r, rel_segment_party_map map, rel_constraints cons,
               (select s.segment_id, r.rel_id
                  from rel_segments s, acs_rels r
                 where r.object_id_one = s.group_id
                   and r.rel_type = s.rel_type) s
 where map.party_id = r.object_id_two
   and map.rel_id = r.rel_id
   and cons.rel_segment = map.segment_id
   and cons.required_rel_segment = s.segment_id;



create or replace package rel_constraint
as

  function new (
    --/** Creates a new relational constraint
    -- 
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    -- 
    --*/
    constraint_id	in rel_constraints.constraint_id%TYPE default null,
    constraint_type     in acs_objects.object_type%TYPE default 'rel_constraint',
    constraint_name	in rel_constraints.constraint_name%TYPE,
    rel_segment		in rel_constraints.rel_segment%TYPE,
    rel_side	        in rel_constraints.rel_side%TYPE default 'two',
    required_rel_segment in rel_constraints.required_rel_segment%TYPE,
    context_id		in acs_objects.context_id%TYPE default null,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null
  ) return rel_constraints.constraint_id%TYPE;

  procedure delete (
    constraint_id	in rel_constraints.constraint_id%TYPE
  );

  function get_constraint_id (
    --/** Returns the constraint_id associated with the specified
    --    rel_segment and required_rel_segment for the specified site.
    -- 
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    -- 
    --*/
    rel_segment		in rel_constraints.rel_segment%TYPE,
    rel_side	        in rel_constraints.rel_side%TYPE default 'two',
    required_rel_segment in rel_constraints.required_rel_segment%TYPE
  ) return rel_constraints.constraint_id%TYPE;

  function violation (
    --/** Checks to see if there a relational constraint is violated
    --    by the precense of the specified relation. If not, returns 
    --    null. If so, returns an appropriate error string.
    -- 
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    -- 
    --    @param rel_id  The relation for which we want to find 
    --                   any violations
    --*/
    rel_id	in acs_rels.rel_id%TYPE
  ) return varchar;


  function violation_if_removed (
    --/** Checks to see if removing the specified relation would violate
    --    a relational constraint. If not, returns null. If so, returns
    --    an appropriate error string.
    -- 
    --    @author Michael Bryzek (mbryzek@arsdigita.com)
    --    @creation-date 1/2001
    -- 
    --    @param rel_id  The relation that we are planning to remove
    --*/
    rel_id	in acs_rels.rel_id%TYPE
  ) return varchar;

end;
/
show errors




-----------------------------
-- UPDATE ACS_OBJECT_TYPES AND ACS_REL_ROLES
-- mbryzek@arsdigita.com
-- 1/5/2001
--
-- CHANGES
-- add dynamic_p column to acs_object_types
-- add pretty_name, pretty_plural to acs_rel_roles and setup defaults
-----------------------------

-- we need a flag to know if object types were created dynamically and
-- can thus be administered through the web
alter table acs_object_types add ( dynamic_p char(1) default 'f' 
                       			     constraint acs_obj_types_dynamic_p_ck
                       			     check (dynamic_p in ('t', 'f')));



comment on column acs_object_types.dynamic_p is '
  This flag is used to identify object types created dynamically
  (e.g. through a web interface). Dynamically created object types can
  be administered differently. For example, the group type admin pages
  only allow users to add attributes or otherwise modify dynamic
  object types. This column is still experimental and may not be supported in the
  future. That is the reason it is not yet part of the API.
';


-- Roles need pretty names and the such. Note we add them separately
-- in case one has already been added on an acs installation

alter table acs_rel_roles add (
	pretty_name	varchar2(100)
);

alter table acs_rel_roles add (
	pretty_plural	varchar2(100)
);

-- do these two updates separately in case the installation we are upgrading
-- has altered these two columns
update acs_rel_roles set pretty_name='Member', pretty_plural='Members' where role='member';
update acs_rel_roles set pretty_name='Composite', pretty_plural='Composites' where role='composite';
update acs_rel_roles set pretty_name='Component', pretty_plural='Components' where role='component';

update acs_rel_roles set pretty_name=role where pretty_name is null;
update acs_rel_roles set pretty_plural=role where pretty_plural is null;

alter table acs_rel_roles modify pretty_name not null;
alter table acs_rel_roles modify pretty_plural not null;


-----------------------------
-- PACKAGE BODY PARTY      --
-- mbryzek@arsdigita.com
-- 1/5/2001
--
-- CHANGES
-- fix delete to simply call acs_object.delete
------------------------------

create or replace package body party
as

 function new (
  party_id	in parties.party_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'party',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  context_id	in acs_objects.context_id%TYPE default null
 )
 return parties.party_id%TYPE
 is
  v_party_id parties.party_id%TYPE;
 begin
  v_party_id :=
   acs_object.new(party_id, object_type,
                  creation_date, creation_user, creation_ip, context_id);

  insert into parties
   (party_id, email, url)
  values
   (v_party_id, lower(email), url);

  return v_party_id;
 end new;

 procedure delete (
  party_id	in parties.party_id%TYPE
 )
 is
 begin
  acs_object.delete(party_id);
 end delete;

 function name (
  party_id	in parties.party_id%TYPE
 )
 return varchar2
 is
 begin
  if party_id = -1 then 
   return 'The Public';
  else
   return null;
  end if;
 end name;

end party;
/
show errors


-----------------------------
-- MODIFICATIONS TO GROUPS --
-- mbryzek@arsdigita.com
-- 1/5/2001
--
-- CHANGES
-- defined default and permissible relationship types for group 
-- types and groups
-- NEW TABLES: group_type_rels, group_rels with defaults set for existing groups
-----------------------------

create table group_type_rels (
       group_rel_type_id      integer constraint gtr_group_rel_type_id_pk primary key,
       rel_type		      not null 
                              constraint gtr_rel_type_fk
                              references acs_rel_types (rel_type)
                              on delete cascade,
       group_type	      not null 
                              constraint gtr_group_type_fk
                              references acs_object_types (object_type)
                              on delete cascade,
       constraint gtr_group_rel_types_un unique (group_type, rel_type)
);

-- rel_type references acs_rel_types. Create an index
create index group_type_rels_rel_type_idx on group_type_rels(rel_type);

comment on table group_type_rels is '
  Stores the default relationship types available for use by groups of
  a given type. We May want to generalize this table to object_types and
  put it in the relationships sql file, though there is no need to do so
  right now.
';


-- define standard types for groups of type 'group'
insert into group_type_rels 
(group_rel_type_id, rel_type, group_type)
values
(acs_object_id_seq.nextval, 'membership_rel', 'group');

insert into group_type_rels 
(group_rel_type_id, rel_type, group_type)
values
(acs_object_id_seq.nextval, 'composition_rel', 'group');


create table group_rels (
       group_rel_id           integer constraint group_rels_group_rel_id_pk primary key,
       rel_type		      not null 
                              constraint group_rels_rel_type_fk
                              references acs_rel_types (rel_type)
                              on delete cascade,
       group_id	              not null 
                              constraint group_rels_group_id_fk
                              references groups (group_id)
                              on delete cascade,
       constraint group_rels_group_rel_type_un unique (group_id, rel_type)
);

-- rel_type references acs_rel_types. Create an index
create index group_rels_rel_type_idx on group_rels(rel_type);

comment on table group_rels is '
  Stores the relationship types available for use by each group. Only
  relationship types in this table are offered for adding
  relations. Note that there is no restriction that says groups can
  only have relationship types specified for their group type. The
  <code>group_type_rels</code> table just stores defaults for groups
  of a new type.
';


-- insert defaults for all groups. 
BEGIN

  for rel_types in (select rel_type from acs_rel_types where rel_type in ('membership_rel','composition_rel')) loop
    for row in (select group_id from groups) loop
      insert into group_rels
      (group_rel_id, rel_type, group_id) 
      values
      (acs_object_id_seq.nextval, rel_types.rel_type, row.group_id);
    end loop;
  end loop;

END;
/
show errors

-------------------------------
-- ACS_OBJECT_ATTRIBUTE_VIEW
-- mbryzek@arsdigita.com
-- 1/5/2001
-------------------------------
-- Create a view to show us all the attributes for one object,
-- including attributes for each of its supertypes

create or replace view acs_object_type_attributes as 
select all_types.object_type, all_types.ancestor_type, 
       attr.attribute_id, attr.table_name, attr.attribute_name, 
       attr.pretty_name, attr.pretty_plural, attr.sort_order, 
       attr.datatype, attr.default_value, attr.min_n_values, 
       attr.max_n_values, attr.storage, attr.static_p, attr.column_name
from acs_attributes attr,
     (select map.object_type, map.ancestor_type
      from acs_object_type_supertype_map map, acs_object_types t
      where map.object_type=t.object_type
      UNION 
      select t.object_type, t.object_type as ancestor_type
        from acs_object_types t) all_types
where attr.object_type = all_types.ancestor_type;


-----------------------------
-- PACKAGE ACS_OBJECT_TYPE
-- mbryzek@arsdigita.com
-- 1/5/2001
--
-- CHANGES
-- Add a type->pretty_name lookup function
-- Drop all attributes of an object type when dropping the object type
-----------------------------

create or replace package acs_object_type
is
  -- define an object type
  procedure create_type (
    object_type		in acs_object_types.object_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'acs_object',
    table_name		in acs_object_types.table_name%TYPE,
    id_column		in acs_object_types.id_column%TYPE default 'XXX',
    package_name	in acs_object_types.package_name%TYPE default null,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null
  );

  -- delete an object type definition
  procedure drop_type (
    object_type		in acs_object_types.object_type%TYPE,
    cascade_p		in char default 'f'
  );

  -- look up an object type's pretty_name
  function pretty_name (
    object_type 	in acs_object_types.object_type%TYPE
  ) return acs_object_types.pretty_name%TYPE;

end acs_object_type;
/
show errors



create or replace package body acs_object_type
is

  procedure create_type (
    object_type		in acs_object_types.object_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'acs_object',
    table_name		in acs_object_types.table_name%TYPE,
    id_column		in acs_object_types.id_column%TYPE,
    package_name	in acs_object_types.package_name%TYPE default null,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null
  )
  is
    v_package_name acs_object_types.package_name%TYPE;
  begin
    -- XXX This is a hack for losers who haven't created packages yet.
    if package_name is null then
      v_package_name := object_type;
    else
      v_package_name := package_name;
    end if;

    insert into acs_object_types
      (object_type, pretty_name, pretty_plural, supertype, table_name,
       id_column, abstract_p, type_extension_table, package_name,
       name_method)
    values
      (object_type, pretty_name, pretty_plural, supertype, table_name,
       id_column, abstract_p, type_extension_table, v_package_name,
       name_method);
  end create_type;

  procedure drop_type (
    object_type		in acs_object_types.object_type%TYPE,
    cascade_p		in char default 'f'
  )
  is
    cursor c_attributes (object_type IN varchar) is
      select attribute_name from acs_attributes where object_type = object_type;
  begin

    -- drop all the attributes associated with this type
    for row in c_attributes (drop_type.object_type) loop
       acs_attribute.drop_attribute ( drop_type.object_type, row.attribute_name );
    end loop;

    delete from acs_attributes
    where object_type = drop_type.object_type;

    delete from acs_object_types
    where object_type = drop_type.object_type;
  end drop_type;


  function pretty_name (
    object_type 	in acs_object_types.object_type%TYPE 
  ) return acs_object_types.pretty_name%TYPE
  is
    v_pretty_name       acs_object_types.pretty_name%TYPE;
  begin
    select t.pretty_name into v_pretty_name
      from acs_object_types t
     where t.object_type = pretty_name.object_type;

    return v_pretty_name;

  end pretty_name;

end acs_object_type;
/
show errors


-----------------------------
-- PACKAGE BODY ACS_ATTRIBUTE
-- mbryzek@arsdigita.com
-- 1/5/2001
--
-- CHANGES
-- Modified drop_attribute to delete all values from acs_enum_values
-- when dropping an attribute
-----------------------------

create or replace package body acs_attribute
is

  function create_attribute (
    object_type		in acs_attributes.object_type%TYPE,
    attribute_name	in acs_attributes.attribute_name%TYPE,
    datatype		in acs_attributes.datatype%TYPE,
    pretty_name		in acs_attributes.pretty_name%TYPE,
    pretty_plural	in acs_attributes.pretty_plural%TYPE default null,
    table_name		in acs_attributes.table_name%TYPE default null,
    column_name		in acs_attributes.column_name%TYPE default null,
    default_value	in acs_attributes.default_value%TYPE default null,
    min_n_values	in acs_attributes.min_n_values%TYPE default 1,
    max_n_values	in acs_attributes.max_n_values%TYPE default 1,
    sort_order		in acs_attributes.sort_order%TYPE default null,
    storage		in acs_attributes.storage%TYPE default 'type_specific',
    static_p		in acs_attributes.static_p%TYPE default 'f'
  ) return acs_attributes.attribute_id%TYPE
  is
    v_sort_order acs_attributes.sort_order%TYPE;
    v_attribute_id    acs_attributes.attribute_id%TYPE;
  begin
    if sort_order is null then
      select nvl(max(sort_order), 1) into v_sort_order
      from acs_attributes
      where object_type = create_attribute.object_type
      and attribute_name = create_attribute.attribute_name;
    else
      v_sort_order := sort_order;
    end if;

    select acs_attribute_id_seq.nextval into v_attribute_id from dual;

    insert into acs_attributes
      (attribute_id, object_type, table_name, column_name, attribute_name,
       pretty_name, pretty_plural, sort_order, datatype, default_value,
       min_n_values, max_n_values, storage, static_p)
    values
      (v_attribute_id, object_type, table_name, column_name, attribute_name,
       pretty_name, pretty_plural, v_sort_order, datatype, default_value,
       min_n_values, max_n_values, storage, static_p);

    return v_attribute_id;
  end create_attribute;

  procedure drop_attribute (
    object_type in varchar2,
    attribute_name in varchar2
  )
  is
  begin
    -- first remove possible values for the enumeration
    delete from acs_enum_values
      where attribute_id in (select a.attribute_id 
                               from acs_attributes a 
                              where a.object_type = drop_attribute.object_type
                                and a.attribute_name = drop_attribute.attribute_name);

    delete from acs_attributes
     where object_type = drop_attribute.object_type
       and attribute_name = drop_attribute.attribute_name;
  end drop_attribute;

  procedure add_description (
    object_type		in acs_attribute_descriptions.object_type%TYPE,
    attribute_name	in acs_attribute_descriptions.attribute_name%TYPE,
    description_key	in acs_attribute_descriptions.description_key%TYPE,
    description		in acs_attribute_descriptions.description%TYPE
  )
  is
  begin
    insert into acs_attribute_descriptions
     (object_type, attribute_name, description_key, description)
    values
     (add_description.object_type, add_description.attribute_name,
      add_description.description_key, add_description.description);
  end;

  procedure drop_description (
    object_type		in acs_attribute_descriptions.object_type%TYPE,
    attribute_name	in acs_attribute_descriptions.attribute_name%TYPE,
    description_key	in acs_attribute_descriptions.description_key%TYPE
  )
  is
  begin
    delete from acs_attribute_descriptions
    where object_type = drop_description.object_type
    and attribute_name = drop_description.attribute_name
    and description_key = drop_description.description_key;
  end;

end acs_attribute;
/
show errors


-----------------------------
-- PACKAGE ACS_REL_TYPE
-- mbryzek@arsdigita.com
-- 1/5/2001
--
-- CHANGES
-- Modified create_role to accept pretty_name and pretty_plural
-- added role_pretty_name, role_pretty_plural functions
-- Modified drop_type to call acs_object_type.drop_type
-----------------------------

create or replace package acs_rel_type
as

  procedure create_role (
    role	  in acs_rel_roles.role%TYPE,
    pretty_name   in acs_rel_roles.pretty_name%TYPE default null,
    pretty_plural in acs_rel_roles.pretty_plural%TYPE default null
  );

  procedure drop_role (
    role	in acs_rel_roles.role%TYPE
  );

  function role_pretty_name (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_name%TYPE;

  function role_pretty_plural (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_plural%TYPE;

  procedure create_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'relationship',
    table_name		in acs_object_types.table_name%TYPE,
    id_column		in acs_object_types.id_column%TYPE,
    package_name	in acs_object_types.package_name%TYPE,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null,
    object_type_one	in acs_rel_types.object_type_one%TYPE,
    role_one		in acs_rel_types.role_one%TYPE default null,
    min_n_rels_one	in acs_rel_types.min_n_rels_one%TYPE,
    max_n_rels_one	in acs_rel_types.max_n_rels_one%TYPE,
    object_type_two	in acs_rel_types.object_type_two%TYPE,
    role_two		in acs_rel_types.role_two%TYPE default null,
    min_n_rels_two	in acs_rel_types.min_n_rels_two%TYPE,
    max_n_rels_two	in acs_rel_types.max_n_rels_two%TYPE
  );

  procedure drop_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    cascade_p		in char default 'f'
  );

end acs_rel_type;
/
show errors

create or replace package body acs_rel_type
as

  procedure create_role (
    role	  in acs_rel_roles.role%TYPE,
    pretty_name   in acs_rel_roles.pretty_name%TYPE default null,
    pretty_plural in acs_rel_roles.pretty_plural%TYPE default null
  )
  is
  begin
    insert into acs_rel_roles
     (role, pretty_name, pretty_plural)
    values
     (create_role.role, nvl(create_role.pretty_name,create_role.role), nvl(create_role.pretty_plural,create_role.role));
  end;

  procedure drop_role (
    role	in acs_rel_roles.role%TYPE
  )
  is
  begin
    delete from acs_rel_roles
    where role = drop_role.role;
  end;

  function role_pretty_name (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_name%TYPE
  is
    v_pretty_name acs_rel_roles.pretty_name%TYPE;
  begin
    select r.pretty_name into v_pretty_name
      from acs_rel_roles r
     where r.role = role_pretty_name.role;

    return v_pretty_name;
  end role_pretty_name;


  function role_pretty_plural (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_plural%TYPE
  is
    v_pretty_plural acs_rel_roles.pretty_plural%TYPE;
  begin
    select r.pretty_plural into v_pretty_plural
      from acs_rel_roles r
     where r.role = role_pretty_plural.role;

    return v_pretty_plural;
  end role_pretty_plural;

  procedure create_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'relationship',
    table_name		in acs_object_types.table_name%TYPE,
    id_column		in acs_object_types.id_column%TYPE,
    package_name	in acs_object_types.package_name%TYPE,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null,
    object_type_one	in acs_rel_types.object_type_one%TYPE,
    role_one		in acs_rel_types.role_one%TYPE default null,
    min_n_rels_one	in acs_rel_types.min_n_rels_one%TYPE,
    max_n_rels_one	in acs_rel_types.max_n_rels_one%TYPE,
    object_type_two	in acs_rel_types.object_type_two%TYPE,
    role_two		in acs_rel_types.role_two%TYPE default null,
    min_n_rels_two	in acs_rel_types.min_n_rels_two%TYPE,
    max_n_rels_two	in acs_rel_types.max_n_rels_two%TYPE
  )
  is
  begin
    acs_object_type.create_type(
      object_type => rel_type,
      pretty_name => pretty_name,
      pretty_plural => pretty_plural,
      supertype => supertype,
      table_name => table_name,
      id_column => id_column,
      package_name => package_name,
      abstract_p => abstract_p,
      type_extension_table => type_extension_table,
      name_method => name_method
    );

    insert into acs_rel_types
     (rel_type,
      object_type_one, role_one,
      min_n_rels_one, max_n_rels_one,
      object_type_two, role_two,
      min_n_rels_two, max_n_rels_two)
    values
     (create_type.rel_type,
      create_type.object_type_one, create_type.role_one,
      create_type.min_n_rels_one, create_type.max_n_rels_one,
      create_type.object_type_two, create_type.role_two,
      create_type.min_n_rels_two, create_type.max_n_rels_two);
  end;

  procedure drop_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    cascade_p		in char default 'f'
  )
  is
  begin
    -- XXX do cascade_p
    delete from acs_rel_types
    where rel_type = drop_type.rel_type;

    acs_object_type.drop_type(drop_type.rel_type, drop_type.cascade_p);
  end;

end acs_rel_type;
/
show errors



-----------------------------
-- PACKAGE BODY ACS_REL
-- mbryzek@arsdigita.com
-- 1/5/2001
--
-- CHANGES
-- fixes the delete proc to not delete from acs_rels (handled by acs_object.delete)
-----------------------------

create or replace package body acs_rel
as

  function new (
    rel_id		in acs_rels.rel_id%TYPE default null,
    rel_type		in acs_rels.rel_type%TYPE default 'relationship',
    object_id_one	in acs_rels.object_id_one%TYPE,
    object_id_two	in acs_rels.object_id_two%TYPE,
    context_id		in acs_objects.context_id%TYPE default null,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null
  ) return acs_rels.rel_id%TYPE
  is
    v_rel_id acs_rels.rel_id%TYPE;
  begin
    -- XXX This should check that object_id_one and object_id_two are
    -- of the appropriate types.
    v_rel_id := acs_object.new (
      object_id => rel_id,
      object_type => rel_type,
      context_id => context_id,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into acs_rels
     (rel_id, rel_type, object_id_one, object_id_two)
    values
     (v_rel_id, new.rel_type, new.object_id_one, new.object_id_two);

     return v_rel_id;
  end;

  procedure delete (
    rel_id	in acs_rels.rel_id%TYPE
  )
  is
  begin
    acs_object.delete(rel_id);
  end;

end;
/
show errors


-----------------------------
-- PACKAGE BODY COMPOSITION_REL
-- mbryzek@arsdigita.com
-- 1/5/2001
--
-- CHANGES
-- fixes the delete proc to not delete from composition_rels (handled by acs_object.delete)
-----------------------------
create or replace package body composition_rel
as

  function new (
    rel_id              in composition_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'composition_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return composition_rels.rel_id%TYPE
  is
    v_rel_id integer;
  begin
    v_rel_id := acs_rel.new (
      rel_id => rel_id,
      rel_type => rel_type,
      object_id_one => object_id_one,
      object_id_two => object_id_two,
      context_id => object_id_one,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into composition_rels
     (rel_id)
    values
     (v_rel_id);

    return v_rel_id;
  end;

  procedure delete (
    rel_id      in composition_rels.rel_id%TYPE
  )
  is
  begin
    acs_rel.delete(rel_id);
  end;

  function check_path_exists_p (
    component_id        in groups.group_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
  begin
    if component_id = container_id then
      return 't';
    end if;

    for row in (select r.object_id_one as parent_id
                from acs_rels r, composition_rels c
                where r.rel_id = c.rel_id
                and r.object_id_two = component_id) loop
      if check_path_exists_p(row.parent_id, container_id) = 't' then
        return 't';
      end if;
    end loop;

    return 'f';
  end;

  function check_index (
    component_id        in groups.group_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
    result char(1);
    n_rows integer;
  begin
    result := 't';

    -- Loop through all the direct containers (DC) of COMPONENT_ID
    -- that are also contained by CONTAINER_ID and verify that the
    -- GROUP_COMPONENT_INDEX contains the (GROUP_ID, DC.REL_ID,
    -- CONTAINER_ID) triple.
    for dc in (select r.rel_id, r.object_id_one as container_id
               from acs_rels r, composition_rels c
               where r.rel_id = c.rel_id
               and r.object_id_two = component_id) loop

      if check_path_exists_p(dc.container_id,
                             check_index.container_id) = 't' then
        select decode(count(*),0,0,1) into n_rows
        from group_component_index
        where group_id = check_index.container_id
        and component_id = check_index.component_id
        and rel_id = dc.rel_id;

        if n_rows = 0 then
          result := 'f';
          acs_log.error('composition_rel.check_representation',
                        'Row missing from group_component_index for (' ||
                        'group_id = ' || container_id || ', ' ||
                        'component_id = ' || component_id || ', ' ||
                        'rel_id = ' || dc.rel_id || ')');
        end if;

      end if;

    end loop;

    -- Loop through all the containers of CONTAINER_ID.
    for r1 in (select r.object_id_one as container_id
               from acs_rels r, composition_rels c
               where r.rel_id = c.rel_id
               and r.object_id_two = check_index.container_id
               union
               select check_index.container_id
               from dual) loop
      -- Loop through all the components of COMPONENT_ID and make a
      -- recursive call.
      for r2 in (select r.object_id_two as component_id
                 from acs_rels r, composition_rels c
                 where r.rel_id = c.rel_id
                 and r.object_id_one = check_index.component_id
                 union
                 select check_index.component_id
                 from dual) loop
        if (r1.container_id != check_index.container_id or
            r2.component_id != check_index.component_id) and
           check_index(r2.component_id, r1.container_id) = 'f' then
          result := 'f';
        end if;
      end loop;
    end loop;

    return result;
  end;

  function check_representation (
    rel_id      in composition_rels.rel_id%TYPE
  ) return char
  is
    container_id groups.group_id%TYPE;
    component_id groups.group_id%TYPE;
    result char(1);
  begin
    result := 't';

    if acs_object.check_representation(rel_id) = 'f' then
      result := 'f';
    end if;

    select object_id_one, object_id_two
    into container_id, component_id
    from acs_rels
    where rel_id = check_representation.rel_id;

    -- First let's check that the index has all the rows it should.
    if check_index(component_id, container_id) = 'f' then
      result := 'f';
    end if;

    -- Now let's check that the index doesn't have any extraneous rows
    -- relating to this relation.
    for row in (select *
                from group_component_index
                where rel_id = check_representation.rel_id) loop
      if check_path_exists_p(row.component_id, row.group_id) = 'f' then
        result := 'f';
        acs_log.error('composition_rel.check_representation',
                      'Extraneous row in group_component_index: ' ||
                      'group_id = ' || row.group_id || ', ' ||
                      'component_id = ' || row.component_id || ', ' ||
                      'rel_id = ' || row.rel_id || ', ' ||
                      'container_id = ' || row.container_id || '.');
      end if;
    end loop;

    return result;
  end;

end composition_rel;
/
show errors



-----------------------------
-- PACKAGE BODY MEMBERSHIP_REL
-- mbryzek@arsdigita.com
-- 1/5/2001
--
-- CHANGES
-- fixes the delete proc to not delete from composition_rels (handled by acs_object.delete)
-----------------------------

create or replace package body membership_rel
as

  function new (
    rel_id              in membership_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'membership_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default null,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return membership_rels.rel_id%TYPE
  is
    v_rel_id integer;
  begin
    v_rel_id := acs_rel.new (
      rel_id => rel_id,
      rel_type => rel_type,
      object_id_one => object_id_one,
      object_id_two => object_id_two,
      context_id => object_id_one,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into membership_rels
     (rel_id, member_state)
    values
     (v_rel_id, new.member_state);

    return v_rel_id;
  end;

  procedure ban (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'banned'
    where rel_id = ban.rel_id;
  end;

  procedure approve (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'approved'
    where rel_id = approve.rel_id;
  end;

  procedure reject (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'rejected'
    where rel_id = reject.rel_id;
  end;

  procedure unapprove (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = ''
    where rel_id = unapprove.rel_id;
  end;

  procedure deleted (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'deleted'
    where rel_id = deleted.rel_id;
  end;

  procedure delete (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    acs_rel.delete(rel_id);
  end;

  function check_index (
    group_id            in groups.group_id%TYPE,
    member_id           in parties.party_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
    result char(1);
    n_rows integer;
  begin

    select count(*) into n_rows
    from group_member_index
    where group_id = check_index.group_id
    and member_id = check_index.member_id
    and container_id = check_index.container_id;

    if n_rows = 0 then
      result := 'f';
      acs_log.error('membership_rel.check_representation',
                    'Row missing from group_member_index: ' ||
                    'group_id = ' || group_id || ', ' ||
                    'member_id = ' || member_id || ', ' ||
                    'container_id = ' || container_id || '.');
    end if;

    for row in (select r.object_id_one as container_id
                from acs_rels r, composition_rels c
                where r.rel_id = c.rel_id
                and r.object_id_two = group_id) loop
      if check_index(row.container_id, member_id, container_id) = 'f' then
        result := 'f';
      end if;
    end loop;

    return result;
  end;

  function check_representation (
    rel_id      in membership_rels.rel_id%TYPE
  ) return char
  is
    group_id  groups.group_id%TYPE;
    member_id parties.party_id%TYPE;
    result    char(1);
  begin
    result := 't';

    if acs_object.check_representation(rel_id) = 'f' then
      result := 'f';
    end if;

    select r.object_id_one, r.object_id_two
    into group_id, member_id
    from acs_rels r, membership_rels m
    where r.rel_id = m.rel_id
    and m.rel_id = check_representation.rel_id;

    if check_index(group_id, member_id, group_id) = 'f' then
      result := 'f';
    end if;

    for row in (select *
                from group_member_index
                where rel_id = check_representation.rel_id) loop
      if composition_rel.check_path_exists_p(row.container_id,
                                             row.group_id) = 'f' then
        result := 'f';
        acs_log.error('membership_rel.check_representation',
                      'Extra row in group_member_index: ' ||
                      'group_id = ' || row.group_id || ', ' ||
                      'member_id = ' || row.member_id || ', ' ||
                      'container_id = ' || row.container_id || '.');
      end if;
    end loop;

    return result;
  end;

end membership_rel;
/
show errors



-----------------------------
-- PACKAGE BODY ACS_GROUP
-- mbryzek@arsdigita.com
-- 1/5/2001
--
-- CHANGES
-- changed delete proc to delete all relations of any type. 
-----------------------------

create or replace package body acs_group
is
 function new (
  group_id              in groups.group_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'group',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  group_name            in groups.group_name%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 )
 return groups.group_id%TYPE
 is
  v_group_id groups.group_id%TYPE;
 begin
  v_group_id :=
   party.new(group_id, object_type, creation_date, creation_user,
             creation_ip, email, url, context_id);

  insert into groups
   (group_id, group_name)
  values
   (v_group_id, group_name);

  -- setup the permissible relationship types for this group
  insert into group_rels
  (group_rel_id, group_id, rel_type)
  select acs_object_id_seq.nextval, v_group_id, g.rel_type
    from group_type_rels g
   where g.group_type = new.object_type;

  return v_group_id;
 end new;


 procedure delete (
    group_id     in groups.group_id%TYPE
  )
  is
  begin
 
   -- Delete all the relations of any type to this group
   for row in (select r.rel_id, t.package_name
                 from acs_rels r, acs_object_types t
                where r.rel_type = t.object_type
                  and (r.object_id_one = acs_group.delete.group_id
                       or r.object_id_two = acs_group.delete.group_id)) loop
      execute immediate 'begin ' ||  row.package_name || '.delete(' || row.rel_id || '); end;';
   end loop;
 
   party.delete(group_id);
 end delete;

 function name (
  group_id      in groups.group_id%TYPE
 )
 return varchar2
 is
  group_name varchar(200);
 begin
  select group_name
  into group_name
  from groups
  where group_id = name.group_id;

  return group_name;
 end name;

 function member_p (
  party_id      in parties.party_id%TYPE
 )
 return char
 is
 begin
  -- TO DO: implement this for real
  return 't';
 end member_p;

 function check_representation (
  group_id      in groups.group_id%TYPE
 ) return char
 is
   result char(1);
 begin
   result := 't';
   acs_log.notice('acs_group.check_representation',
                  'Running check_representation on group ' || group_id);

   if acs_object.check_representation(group_id) = 'f' then
     result := 'f';
   end if;

   for c in (select c.rel_id
             from acs_rels r, composition_rels c
             where r.rel_id = c.rel_id
             and r.object_id_one = group_id) loop
     if composition_rel.check_representation(c.rel_id) = 'f' then
       result := 'f';
     end if;
   end loop;

   for m in (select m.rel_id
             from acs_rels r, membership_rels m
             where r.rel_id = m.rel_id
             and r.object_id_one = group_id) loop
     if membership_rel.check_representation(m.rel_id) = 'f' then
       result := 'f';
     end if;
   end loop;

   acs_log.notice('acs_group.check_representation',
                  'Done running check_representation on group ' || group_id);
   return result;
 end;

end acs_group;
/
show errors



-----------------------------
-- CREATE NEW ATTRIBUTES
-- mbryzek@arsdigita.com
-- 1/5/2001
--
-- CHANGES
-- creates additional attributes for group, party, and acs_object
-----------------------------

declare
  attr_id acs_attributes.attribute_id%TYPE;
begin 

 attr_id := acs_attribute.create_attribute (
        object_type => 'group',
        attribute_name => 'group_name',
        datatype => 'string',
        pretty_name => 'Group name',
        pretty_plural => 'Group names',
	min_n_values => 1,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'party',
        attribute_name => 'email',
        datatype => 'string',
        pretty_name => 'Email Address',
        pretty_plural => 'Email Addresses',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'party',
        attribute_name => 'url',
        datatype => 'string',
        pretty_name => 'URL',
        pretty_plural => 'URLs',
	min_n_values => 0,
	max_n_values => 1
      );


 attr_id := acs_attribute.create_attribute (
        object_type => 'acs_object',
        attribute_name => 'creation_user',
        datatype => 'integer',
        pretty_name => 'Creation user',
        pretty_plural => 'Creation users',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'acs_object',
        attribute_name => 'context_id',
        datatype => 'integer',
        pretty_name => 'Context ID',
        pretty_plural => 'Context IDs',
	min_n_values => 0,
	max_n_values => 1
      );

end;
/
show errors;
commit;


-----------------------------
-- UPDATE VIEW acs_object_party_privilege_map
-- mbryzek@arsdigita.com
-- 1/8/2001
--
-- CHANGES
-- looks at rel_segment_member_map also
-----------------------------

create or replace view acs_object_party_privilege_map
as select ogpm.object_id, gmm.member_id as party_id, ogpm.privilege
   from acs_object_grantee_priv_map ogpm, group_member_map gmm
   where ogpm.grantee_id = gmm.group_id
   union
   select ogpm.object_id, rsmm.member_id as party_id, ogpm.privilege
   from acs_object_grantee_priv_map ogpm, rel_segment_member_map rsmm
   where ogpm.grantee_id = rsmm.segment_id
   union
   select object_id, grantee_id as party_id, privilege
   from acs_object_grantee_priv_map
   union
   select object_id, u.user_id as party_id, privilege
   from acs_object_grantee_priv_map m, users u
   where m.grantee_id = -1
   union
   select object_id, 0 as party_id, privilege
   from acs_object_grantee_priv_map
   where grantee_id = -1;



---------------------------------
-- UPDATE PACKAGE ACS PERMISSION
---------------------------------

create or replace package body acs_permission
as

  procedure grant_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  )
  as
  begin
    insert into acs_permissions
      (object_id, grantee_id, privilege)
    values
      (object_id, grantee_id, privilege);
  exception
    when dup_val_on_index then
      return;
  end grant_permission;

  procedure revoke_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  )
  as
  begin
    delete from acs_permissions
    where object_id = revoke_permission.object_id
    and grantee_id = revoke_permission.grantee_id
    and privilege = revoke_permission.privilege;
  end revoke_permission;

  function permission_p (
    object_id	 acs_objects.object_id%TYPE,
    party_id	 parties.party_id%TYPE,
    privilege	 acs_privileges.privilege%TYPE
  ) return char
  as
    exists_p char(1);
  begin
    -- We should question whether we really want to use the
    -- acs_object_party_privilege_map since it unions the
    -- difference queries. UNION ALL would be more efficient.
    -- Also, we may want to test replacing the decode with
    --  select count(*) from dual where exists ...
    -- 1/12/2001, mbryzek
    select decode(count(*),0,'f','t') into exists_p
      from acs_object_party_privilege_map
     where object_id = permission_p.object_id
       and party_id = permission_p.party_id
       and privilege = permission_p.privilege;
    return exists_p;
  end;

end acs_permission;
/
show errors




----------------------------------------
-- CREATE VALIDATION TRIGGER ON ACS_RELS
-- oumi@arsdigita.com
-- 1/11/2001
--
-- CHANGES
-- add a trigger: before insert or update 
-- on acs_rels, validate that the relation
-- is between objects of the correct 
-- object type. 
-----------------------------

create or replace trigger acs_rels_in_tr
before insert or update on acs_rels
for each row
declare
  dummy integer;
  target_object_type_one acs_object_types.object_type%TYPE;
  target_object_type_two acs_object_types.object_type%TYPE;
  actual_object_type_one acs_object_types.object_type%TYPE;
  actual_object_type_two acs_object_types.object_type%TYPE;
begin

    -- validate that the relation being added is between objects of the
    -- correct object_type.  If no rows are returned by this query,
    -- then the types are wrong and we should return an error.
    select 1 into dummy
    from acs_rel_types rt,
         acs_objects o1, 
         acs_objects o2
    where exists (select 1 
                   from acs_object_types t
                  where t.object_type = o1.object_type
                connect by prior t.object_type = t.supertype
                  start with t.object_type = rt.object_type_one)
      and exists (select 1 
                   from acs_object_types t
                  where t.object_type = o2.object_type
                connect by prior t.object_type = t.supertype
                  start with t.object_type = rt.object_type_two)
      and rt.rel_type = :new.rel_type
      and o1.object_id = :new.object_id_one
      and o2.object_id = :new.object_id_two;

exception
  when NO_DATA_FOUND then

      -- At least one of the object types must have been wrong.
      -- Get all the object type information and print it out.
      select rt.object_type_one, rt.object_type_two,
             o1.object_type, o2.object_type
      into target_object_type_one, target_object_type_two,
           actual_object_type_one, actual_object_type_two
      from acs_rel_types rt, acs_objects o1, acs_objects o2
      where rt.rel_type = :new.rel_type
        and o1.object_id = :new.object_id_one
        and o2.object_id = :new.object_id_two;

      raise_application_error (-20001,
          :new.rel_type || ' violation: Invalid object types.  ' ||
          'Object ' || :new.object_id_one || 
          ' (' || actual_object_type_one || ') ' || 
          'must be of type ' || target_object_type_one || '. ' ||
          'Object ' || :new.object_id_two || 
          ' (' || actual_object_type_two || ') ' || 
          'must be of type ' || target_object_type_two || '.');
          

end;
/
show errors




------------------------------------------------------------
-- RECREATE GROUP TRIGGERS TO ENFORE RELATIONAL CONSTRAINTS
-- oumi@arsdigita.com
-- 1/11/2001
--
-- CHANGES
-- Modify insert and delete triggers to first check for 
--  violations of relational constraint
-- Replace triggers that insert into group_member_index and 
--  group_component_index, so that they insert into group_element_index.-- 
-- Replace triggers that delete from group_member_index and 
--  group_component_index
--
-- Corresponding ACS File: ../groups-body-create.sql
------------------------------------------------------------
--
-- packages/acs-kernel/sql/groups-body-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-08-22
-- @cvs-id $Id$
--

--------------
-- TRIGGERS --
--------------

create or replace trigger membership_rels_in_tr
after insert on membership_rels
for each row
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_error varchar2(4000);
begin
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint.violation(:new.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  select object_id_one, object_id_two, rel_type
  into v_object_id_one, v_object_id_two, v_rel_type
  from acs_rels
  where rel_id = :new.rel_id;

  -- Insert a row for me in the group_member_index.
  insert into group_element_index
   (group_id, element_id, rel_id, container_id, 
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, :new.rel_id, v_object_id_one, 
    v_rel_type, 'membership_rel');

  -- For all groups of which I am a component, insert a
  -- row in the group_member_index.
  for map in (select distinct group_id
	      from group_component_map
	      where component_id = v_object_id_one) loop
    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    values
     (map.group_id, v_object_id_two, :new.rel_id, v_object_id_one,
      v_rel_type, 'membership_rel');
  end loop;
end;
/
show errors

create or replace trigger composition_rels_in_tr
after insert on composition_rels
for each row
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_error varchar2(4000);
begin
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint.violation(:new.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  select object_id_one, object_id_two, rel_type
  into v_object_id_one, v_object_id_two, v_rel_type
  from acs_rels
  where rel_id = :new.rel_id;

  -- Insert a row for me in group_element_index
  insert into group_element_index
   (group_id, element_id, rel_id, container_id,
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, :new.rel_id, v_object_id_one,
    v_rel_type, 'composition_rel');

  -- Make my elements be elements of my new composite group
  insert into group_element_index
   (group_id, element_id, rel_id, container_id,
    rel_type, ancestor_rel_type)
  select distinct
   v_object_id_one, element_id, rel_id, container_id,
   rel_type, ancestor_rel_type
  from group_element_map m
  where group_id = v_object_id_two
  and not exists (select 1
		  from group_element_map
		  where group_id = v_object_id_one
		  and element_id = m.element_id
		  and rel_id = m.rel_id);

  -- For all direct or indirect containers of my new composite group, 
  -- add me and add my elements
  for map in (select distinct group_id
	      from group_component_map
	      where component_id = v_object_id_one) loop

    -- Add a row for me
    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    values
     (map.group_id, v_object_id_two, :new.rel_id, v_object_id_one,
      v_rel_type, 'composition_rel');

    -- Add rows for my elements
    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    select distinct
     map.group_id, element_id, rel_id, container_id,
     rel_type, ancestor_rel_type
    from group_element_map m
    where group_id = v_object_id_two
    and not exists (select 1
		    from group_element_map
		    where group_id = map.group_id
		    and element_id = m.element_id
		    and rel_id = m.rel_id);
  end loop;

end;
/
show errors

create or replace trigger membership_rels_del_tr
before delete on membership_rels
for each row
declare 
  v_error varchar2(4000);
begin
  -- First check if removing this relation would violate any relational constraints
  v_error := rel_constraint.violation_if_removed(:old.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  delete from group_element_index
  where rel_id = :old.rel_id;
end;
/
show errors;

--
-- TO DO: See if this can be optimized now that the member and component
-- mapping tables have been combined
--
create or replace trigger composition_rels_del_tr
before delete on composition_rels
for each row
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  n_rows integer;
  v_error varchar2(4000);
begin
  -- First check if removing this relation would violate any relational constraints
  v_error := rel_constraint.violation_if_removed(:old.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  select object_id_one, object_id_two into v_object_id_one, v_object_id_two
  from acs_rels
  where rel_id = :old.rel_id;

  for map in (select *
	      from group_component_map
	      where rel_id = :old.rel_id) loop

    delete from group_element_index
    where rel_id = :old.rel_id;

    select count(*) into n_rows
    from group_component_map
    where group_id = map.group_id
    and component_id = map.component_id;

    if n_rows = 0 then
      delete from group_element_index
      where group_id = map.group_id
      and container_id = map.component_id
      and ancestor_rel_type = 'membership_rel';
    end if;

  end loop;


  for map in (select *
              from group_component_map
	      where group_id in (select group_id
		               from group_component_map
		               where component_id = v_object_id_one
			       union
			       select v_object_id_one
			       from dual)
              and component_id in (select component_id
			           from group_component_map
			           where group_id = v_object_id_two
				   union
				   select v_object_id_two
				   from dual)
              and group_contains_p(group_id, component_id, rel_id) = 'f') loop

    delete from group_element_index
    where group_id = map.group_id
    and element_id = map.component_id
    and rel_id = map.rel_id;

    select count(*) into n_rows
    from group_component_map
    where group_id = map.group_id
    and component_id = map.component_id;

    if n_rows = 0 then
      delete from group_element_index
      where group_id = map.group_id
      and container_id = map.component_id
      and ancestor_rel_type = 'membership_rel';
    end if;

  end loop;
end;
/
show errors


--------------------
-- PACKAGE BODIES --
--------------------

create or replace package body composition_rel
as

  function new (
    rel_id              in composition_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'composition_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return composition_rels.rel_id%TYPE
  is
    v_rel_id integer;
  begin
    v_rel_id := acs_rel.new (
      rel_id => rel_id,
      rel_type => rel_type,
      object_id_one => object_id_one,
      object_id_two => object_id_two,
      context_id => object_id_one,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into composition_rels
     (rel_id)
    values
     (v_rel_id);

    return v_rel_id;
  end;

  procedure delete (
    rel_id      in composition_rels.rel_id%TYPE
  )
  is
  begin
    acs_rel.delete(rel_id);
  end;

  function check_path_exists_p (
    component_id        in groups.group_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
  begin
    if component_id = container_id then
      return 't';
    end if;

    for row in (select r.object_id_one as parent_id
                from acs_rels r, composition_rels c
                where r.rel_id = c.rel_id
                and r.object_id_two = component_id) loop
      if check_path_exists_p(row.parent_id, container_id) = 't' then
        return 't';
      end if;
    end loop;

    return 'f';
  end;

  function check_index (
    component_id        in groups.group_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
    result char(1);
    n_rows integer;
  begin
    result := 't';

    -- Loop through all the direct containers (DC) of COMPONENT_ID
    -- that are also contained by CONTAINER_ID and verify that the
    -- GROUP_COMPONENT_INDEX contains the (GROUP_ID, DC.REL_ID,
    -- CONTAINER_ID) triple.
    for dc in (select r.rel_id, r.object_id_one as container_id
               from acs_rels r, composition_rels c
               where r.rel_id = c.rel_id
               and r.object_id_two = component_id) loop

      if check_path_exists_p(dc.container_id,
                             check_index.container_id) = 't' then
        select decode(count(*),0,0,1) into n_rows
        from group_component_index
        where group_id = check_index.container_id
        and component_id = check_index.component_id
        and rel_id = dc.rel_id;

        if n_rows = 0 then
          result := 'f';
          acs_log.error('composition_rel.check_representation',
                        'Row missing from group_component_index for (' ||
                        'group_id = ' || container_id || ', ' ||
                        'component_id = ' || component_id || ', ' ||
                        'rel_id = ' || dc.rel_id || ')');
        end if;

      end if;

    end loop;

    -- Loop through all the containers of CONTAINER_ID.
    for r1 in (select r.object_id_one as container_id
               from acs_rels r, composition_rels c
               where r.rel_id = c.rel_id
               and r.object_id_two = check_index.container_id
               union
               select check_index.container_id
               from dual) loop
      -- Loop through all the components of COMPONENT_ID and make a
      -- recursive call.
      for r2 in (select r.object_id_two as component_id
                 from acs_rels r, composition_rels c
                 where r.rel_id = c.rel_id
                 and r.object_id_one = check_index.component_id
                 union
                 select check_index.component_id
                 from dual) loop
        if (r1.container_id != check_index.container_id or
            r2.component_id != check_index.component_id) and
           check_index(r2.component_id, r1.container_id) = 'f' then
          result := 'f';
        end if;
      end loop;
    end loop;

    return result;
  end;

  function check_representation (
    rel_id      in composition_rels.rel_id%TYPE
  ) return char
  is
    container_id groups.group_id%TYPE;
    component_id groups.group_id%TYPE;
    result char(1);
  begin
    result := 't';

    if acs_object.check_representation(rel_id) = 'f' then
      result := 'f';
    end if;

    select object_id_one, object_id_two
    into container_id, component_id
    from acs_rels
    where rel_id = check_representation.rel_id;

    -- First let's check that the index has all the rows it should.
    if check_index(component_id, container_id) = 'f' then
      result := 'f';
    end if;

    -- Now let's check that the index doesn't have any extraneous rows
    -- relating to this relation.
    for row in (select *
                from group_component_index
                where rel_id = check_representation.rel_id) loop
      if check_path_exists_p(row.component_id, row.group_id) = 'f' then
        result := 'f';
        acs_log.error('composition_rel.check_representation',
                      'Extraneous row in group_component_index: ' ||
                      'group_id = ' || row.group_id || ', ' ||
                      'component_id = ' || row.component_id || ', ' ||
                      'rel_id = ' || row.rel_id || ', ' ||
                      'container_id = ' || row.container_id || '.');
      end if;
    end loop;

    return result;
  end;

end composition_rel;
/
show errors




create or replace package body membership_rel
as

  function new (
    rel_id              in membership_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'membership_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default null,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return membership_rels.rel_id%TYPE
  is
    v_rel_id integer;
  begin
    v_rel_id := acs_rel.new (
      rel_id => rel_id,
      rel_type => rel_type,
      object_id_one => object_id_one,
      object_id_two => object_id_two,
      context_id => object_id_one,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into membership_rels
     (rel_id, member_state)
    values
     (v_rel_id, new.member_state);

    return v_rel_id;
  end;

  procedure ban (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'banned'
    where rel_id = ban.rel_id;
  end;

  procedure approve (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'approved'
    where rel_id = approve.rel_id;
  end;

  procedure reject (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'rejected'
    where rel_id = reject.rel_id;
  end;

  procedure unapprove (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = ''
    where rel_id = unapprove.rel_id;
  end;

  procedure deleted (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'deleted'
    where rel_id = deleted.rel_id;
  end;

  procedure delete (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    acs_rel.delete(rel_id);
  end;

  function check_index (
    group_id            in groups.group_id%TYPE,
    member_id           in parties.party_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
    result char(1);
    n_rows integer;
  begin

    select count(*) into n_rows
    from group_member_index
    where group_id = check_index.group_id
    and member_id = check_index.member_id
    and container_id = check_index.container_id;

    if n_rows = 0 then
      result := 'f';
      acs_log.error('membership_rel.check_representation',
                    'Row missing from group_member_index: ' ||
                    'group_id = ' || group_id || ', ' ||
                    'member_id = ' || member_id || ', ' ||
                    'container_id = ' || container_id || '.');
    end if;

    for row in (select r.object_id_one as container_id
                from acs_rels r, composition_rels c
                where r.rel_id = c.rel_id
                and r.object_id_two = group_id) loop
      if check_index(row.container_id, member_id, container_id) = 'f' then
        result := 'f';
      end if;
    end loop;

    return result;
  end;

  function check_representation (
    rel_id      in membership_rels.rel_id%TYPE
  ) return char
  is
    group_id  groups.group_id%TYPE;
    member_id parties.party_id%TYPE;
    result    char(1);
  begin
    result := 't';

    if acs_object.check_representation(rel_id) = 'f' then
      result := 'f';
    end if;

    select r.object_id_one, r.object_id_two
    into group_id, member_id
    from acs_rels r, membership_rels m
    where r.rel_id = m.rel_id
    and m.rel_id = check_representation.rel_id;

    if check_index(group_id, member_id, group_id) = 'f' then
      result := 'f';
    end if;

    for row in (select *
                from group_member_index
                where rel_id = check_representation.rel_id) loop
      if composition_rel.check_path_exists_p(row.container_id,
                                             row.group_id) = 'f' then
        result := 'f';
        acs_log.error('membership_rel.check_representation',
                      'Extra row in group_member_index: ' ||
                      'group_id = ' || row.group_id || ', ' ||
                      'member_id = ' || row.member_id || ', ' ||
                      'container_id = ' || row.container_id || '.');
      end if;
    end loop;

    return result;
  end;

end membership_rel;
/
show errors



create or replace package body acs_group
is
 function new (
  group_id              in groups.group_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'group',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  group_name            in groups.group_name%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 )
 return groups.group_id%TYPE
 is
  v_group_id groups.group_id%TYPE;
 begin
  v_group_id :=
   party.new(group_id, object_type, creation_date, creation_user,
             creation_ip, email, url, context_id);

  insert into groups
   (group_id, group_name)
  values
   (v_group_id, group_name);

  -- setup the permissible relationship types for this group
  insert into group_rels
  (group_rel_id, group_id, rel_type)
  select acs_object_id_seq.nextval, v_group_id, g.rel_type
    from group_type_rels g
   where g.group_type = new.object_type;

  return v_group_id;
 end new;


 procedure delete (
    group_id     in groups.group_id%TYPE
  )
  is
  begin
 
   -- Delete all segments defined for this group
   for row in (select segment_id 
                 from rel_segments 
                where group_id = acs_group.delete.group_id) loop

       rel_segment.delete(row.segment_id);

   end loop;

   -- Delete all the relations of any type to this group
   for row in (select r.rel_id, t.package_name
                 from acs_rels r, acs_object_types t
                where r.rel_type = t.object_type
                  and (r.object_id_one = acs_group.delete.group_id
                       or r.object_id_two = acs_group.delete.group_id)) loop
      execute immediate 'begin ' ||  row.package_name || '.delete(' || row.rel_id || '); end;';
   end loop;
 
   party.delete(group_id);
 end delete;

 function name (
  group_id      in groups.group_id%TYPE
 )
 return varchar2
 is
  group_name varchar(200);
 begin
  select group_name
  into group_name
  from groups
  where group_id = name.group_id;

  return group_name;
 end name;

 function member_p (
  party_id      in parties.party_id%TYPE
 )
 return char
 is
 begin
  -- TO DO: implement this for real
  return 't';
 end member_p;

 function check_representation (
  group_id      in groups.group_id%TYPE
 ) return char
 is
   result char(1);
 begin
   result := 't';
   acs_log.notice('acs_group.check_representation',
                  'Running check_representation on group ' || group_id);

   if acs_object.check_representation(group_id) = 'f' then
     result := 'f';
   end if;

   for c in (select c.rel_id
             from acs_rels r, composition_rels c
             where r.rel_id = c.rel_id
             and r.object_id_one = group_id) loop
     if composition_rel.check_representation(c.rel_id) = 'f' then
       result := 'f';
     end if;
   end loop;

   for m in (select m.rel_id
             from acs_rels r, membership_rels m
             where r.rel_id = m.rel_id
             and r.object_id_one = group_id) loop
     if membership_rel.check_representation(m.rel_id) = 'f' then
       result := 'f';
     end if;
   end loop;

   acs_log.notice('acs_group.check_representation',
                  'Done running check_representation on group ' || group_id);
   return result;
 end;

end acs_group;
/
show errors





------------------------------------------------------------
-- CREATE THE rel_segment package body
-- oumi@arsdigita.com
-- 1/11/2001
--
-- Corresponding ACS File: ../rel-segments-body-create.sql
------------------------------------------------------------
--
-- packages/acs-kernel/sql/rel-segments-create.sql
--
-- @author Oumi Mehrotra oumi@arsdigita.com
-- @creation-date 2000-11-22
-- @cvs-id $Id$

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

------------------
-- PACKAGE BODY --
------------------

create or replace package body rel_segment
is
 function new (
  segment_id            in rel_segments.segment_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'rel_segment',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  segment_name          in rel_segments.segment_name%TYPE,
  group_id              in rel_segments.group_id%TYPE,
  rel_type              in rel_segments.rel_type%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 ) return rel_segments.segment_id%TYPE
 is
  v_segment_id rel_segments.segment_id%TYPE;
 begin
  v_segment_id :=
   party.new(segment_id, object_type, creation_date, creation_user,
             creation_ip, email, url, context_id);

  insert into rel_segments
   (segment_id, segment_name, group_id, rel_type)
  values
   (v_segment_id, new.segment_name, new.group_id, new.rel_type);

  return v_segment_id;
 end new;

 procedure delete (
   segment_id     in rel_segments.segment_id%TYPE
 )
 is
 begin

   -- remove all constraints on this segment
   for row in (select constraint_id 
                 from rel_constraints 
                where rel_segment = rel_segment.delete.segment_id) loop

       rel_constraint.delete(row.constraint_id);

   end loop;

   party.delete(segment_id);

 end delete;

 -- EXPERIMENTAL / UNSTABLE -- use at your own risk
 --
 function get (
   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE
 ) return rel_segments.segment_id%TYPE
 is
   v_segment_id rel_segments.segment_id%TYPE;
 begin
   select min(segment_id) into v_segment_id
   from rel_segments
   where group_id = get.group_id
     and rel_type = get.rel_type;

   return v_segment_id;
 end get;


 -- EXPERIMENTAL / UNSTABLE -- use at your own risk
 --
 -- This function simplifies the use of segments a little by letting
 -- you not have to worry about creating and initializing segments.
 -- If the segment you're interested in exists, this function
 -- returns its segment_id.
 -- If the segment you're interested in doesn't exist, this function
 -- does a pretty minimal amount of initialization for the segment
 -- and returns a new segment_id.
 function get_or_new (
   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE,
   segment_name   in rel_segments.segment_name%TYPE
                  default null
 ) return rel_segments.segment_id%TYPE
 is
   v_segment_id rel_segments.segment_id%TYPE;
   v_segment_name rel_segments.segment_name%TYPE;
 begin

   v_segment_id := get(group_id, rel_type);

   if v_segment_id is null then

      if v_segment_name is not null then
         v_segment_name := segment_name;
      else
         select groups.group_name || ' - ' || acs_object_types.pretty_name ||
                  ' segment'
         into v_segment_name
         from groups, acs_object_types
         where groups.group_id = get_or_new.group_id
           and acs_object_types.object_type = get_or_new.rel_type;

      end if;

      v_segment_id := rel_segment.new (
          object_type => 'rel_segment',
          creation_user => null,
          creation_ip => null,
          email => null,
          url => null,
          segment_name => v_segment_name,
          group_id => get_or_new.group_id,
          rel_type => get_or_new.rel_type,
          context_id => get_or_new.group_id
      );

   end if;

   return v_segment_id;

 end get_or_new;

 function name (
  segment_id      in rel_segments.segment_id%TYPE
 )
 return rel_segments.segment_name%TYPE
 is
  segment_name varchar(200);
 begin
  select segment_name
  into segment_name
  from rel_segments
  where segment_id = name.segment_id;

  return segment_name;
 end name;

end rel_segment;
/
show errors





------------------------------------------------------------
-- CREATE THE rel_constraint package body
-- oumi@arsdigita.com
-- 1/11/2001
--
-- Corresponding ACS File: ../rel-constraints-body-create.sql
------------------------------------------------------------
--
-- /packages/acs-kernel/sql/rel-constraints-create.sql
-- 
-- Add support for relational constraints based on relational segmentation.
--
-- @author Oumi Mehrotra (oumi@arsdigita.com)
-- @creation-date 2000-11-22
-- @cvs-id $Id$

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html


create or replace package body rel_constraint
as

  function new (
    constraint_id	in rel_constraints.constraint_id%TYPE default null,
    constraint_type     in acs_objects.object_type%TYPE default 'rel_constraint',
    constraint_name	in rel_constraints.constraint_name%TYPE,
    rel_segment		in rel_constraints.rel_segment%TYPE,
    rel_side	        in rel_constraints.rel_side%TYPE default 'two',
    required_rel_segment in rel_constraints.required_rel_segment%TYPE,
    context_id		in acs_objects.context_id%TYPE default null,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null
  ) return rel_constraints.constraint_id%TYPE
  is
    v_constraint_id rel_constraints.constraint_id%TYPE;
  begin
    v_constraint_id := acs_object.new (
      object_id => constraint_id,
      object_type => constraint_type,
      context_id => context_id,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into rel_constraints
     (constraint_id, constraint_name, 
      rel_segment, rel_side, required_rel_segment)
    values
     (v_constraint_id, new.constraint_name, 
      new.rel_segment, new.rel_side, new.required_rel_segment);

     return v_constraint_id;
  end;

  procedure delete (
    constraint_id	in rel_constraints.constraint_id%TYPE
  )
  is
  begin
    acs_object.delete(constraint_id);
  end;

  function get_constraint_id (
    rel_segment		in rel_constraints.rel_segment%TYPE,
    rel_side	        in rel_constraints.rel_side%TYPE default 'two',
    required_rel_segment in rel_constraints.required_rel_segment%TYPE
  ) return rel_constraints.constraint_id%TYPE
  is
    v_constraint_id	rel_constraints.constraint_id%TYPE;
  begin
    select constraint_id into v_constraint_id
    from rel_constraints
    where rel_segment = get_constraint_id.rel_segment
      and rel_side = get_constraint_id.rel_side
      and required_rel_segment = get_constraint_id.required_rel_segment;

    return v_constraint_id;

  end;  


  function violation (
    rel_id	in acs_rels.rel_id%TYPE
  ) return varchar
  is
      v_error varchar(4000);
  begin

    v_error := null;

    for constraint_violated in
      (select /*+ FIRST_ROWS*/ constraint_id, constraint_name
       from rel_constraints_violated_one
       where rel_id = rel_constraint.violation.rel_id
         and rownum = 1) loop

	  v_error := v_error || 'Relational Constraint Violation: ' ||
                     constraint_violated.constraint_name || 
                     ' (constraint_id=' ||
                     constraint_violated.constraint_id || '). ';

          return v_error;
    end loop;

    for constraint_violated in
      (select /*+ FIRST_ROWS*/ constraint_id, constraint_name
       from rel_constraints_violated_two
       where rel_id = rel_constraint.violation.rel_id
         and rownum = 1) loop

           v_error := v_error || 'Relational Constraint Violation: ' ||
                     constraint_violated.constraint_name || 
                     ' (constraint_id=' ||
                     constraint_violated.constraint_id || '). ';

          return v_error;
    end loop;

    return v_error;

  end violation;

  function violation_if_removed (
    rel_id	in acs_rels.rel_id%TYPE
  ) return varchar
  is
      v_count integer;
      v_error varchar(4000);
  begin
    v_error := null;

    select count(*) into v_count
      from dual
     where exists (select 1 from rc_violations_by_removing_rel r where r.rel_id = violation_if_removed.rel_id);

    if v_count > 0 then
      -- some other relation depends on this one. Let's build up a string
      -- of the constraints we are violating
      for constraint_violated in (select constraint_id, constraint_name
                                    from rc_violations_by_removing_rel r
                                   where r.rel_id = violation_if_removed.rel_id) loop

          v_error := v_error || 'Relational Constraint Violation: ' ||
                     constraint_violated.constraint_name || 
                     ' (constraint_id=' ||
                     constraint_violated.constraint_id || '). ';

      end loop;

    end if;

    return v_error;

  end;


end;
/
show errors


