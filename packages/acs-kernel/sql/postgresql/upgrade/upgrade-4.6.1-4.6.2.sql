-- Callbacks
create table apm_package_callbacks (
    version_id         integer 
                       constraint apm_package_callbacks_vid_fk 
                       references apm_package_versions(version_id)
                       on delete cascade,
    type               varchar(40),
    proc               varchar(300),
    constraint apm_package_callbacks_vt_un
    unique (version_id, type)
);

comment on table apm_package_callbacks is '
  This table holds names of Tcl procedures to invoke at the time (before or after) the package is
  installed, instantiated, or mounted.        
';

comment on column apm_package_callbacks.proc is '
  Name of the Tcl proc.
';

comment on column apm_package_callbacks.type is '
  Indicates when the callback proc should be invoked, for example after-install. Valid
  values are given by the Tcl proc apm_supported_callback_types.
';

-- Add column for auto-mount
alter table apm_package_versions add auto_mount varchar(50);

-- DRB: Set it null for all existing versions (probably not necessary but doesn't hurt)
update apm_package_versions set auto_mount = NULL;

comment on column apm_package_versions.auto_mount is '
 A dir under the main site site node where an instance of the package will be mounted
 automatically upon installation. Useful for site-wide services that need mounting
 such as general-comments and notifications.
';

-- DRB: Need to drop this view first in PG 7.3 since "cascade" isn't implemented in
-- PG 7.2 and PG 7.3 doesn't let you drop a view if another depends on it.

drop view apm_enabled_package_versions;

-- Recreate views for auto-mount
drop view apm_package_version_info;
create view apm_package_version_info as
    select v.package_key, t.package_uri, t.pretty_name, t.singleton_p, t.initial_install_p,
           v.version_id, v.version_name,
           v.version_uri, v.summary, v.description_format, v.description, v.release_date,
           v.vendor, v.vendor_uri, v.auto_mount, v.enabled_p, v.installed_p, v.tagged_p, v.imported_p, v.data_model_loaded_p,
           v.activation_date, v.deactivation_date,
           coalesce(v.content_length,0) as tarball_length,
           distribution_uri, distribution_date
    from   apm_package_types t, apm_package_versions v 
    where  v.package_key = t.package_key;

create view apm_enabled_package_versions as
    select * from apm_package_version_info
    where  enabled_p = 't';
	
create or replace function apm_package__highest_version (varchar) returns integer as '
declare
     highest_version__package_key    alias for $1;
     v_version_id                    apm_package_versions.version_id%TYPE;
begin
     select version_id into v_version_id
	from apm_package_version_info i 
	where apm_package_version__sortable_version_name(version_name) = 
             (select max(apm_package_version__sortable_version_name(v.version_name))
	             from apm_package_version_info v where v.package_key = highest_version__package_key)
	and package_key = highest_version__package_key;
      if NOT FOUND then 
         return 0;
      else
         return v_version_id;
      end if;
end;' language 'plpgsql';

-- Recreate functions for auto-mount
create function apm_package_version__new (integer,varchar,varchar,varchar,varchar,varchar,varchar,timestamptz,varchar,varchar,varchar,boolean,boolean) returns integer as '
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

create or replace function apm_package_version__edit (integer,integer,varchar,varchar,varchar,varchar,varchar,timestamptz,varchar,varchar,varchar,boolean,boolean)
returns integer as '
declare
  edit__new_version_id         alias for $1;  -- default null  
  edit__version_id             alias for $2;  
  edit__version_name           alias for $3;  -- default null
  edit__version_uri            alias for $4;  
  edit__summary                alias for $5;  
  edit__description_format     alias for $6;  
  edit__description            alias for $7;  
  edit__release_date           alias for $8;  
  edit__vendor                 alias for $9;  
  edit__vendor_uri             alias for $10; 
  edit__auto_mount             alias for $11;
  edit__installed_p            alias for $12; -- default ''f''
  edit__data_model_loaded_p    alias for $13; -- default ''f''
  v_version_id                 apm_package_versions.version_id%TYPE;
  version_unchanged_p          integer;       
begin
       -- Determine if version has changed.
       select case when count(*) = 0 then 0 else 1 end into version_unchanged_p
       from apm_package_versions
       where version_id = edit__version_id
       and version_name = edit__version_name;
       if version_unchanged_p <> 1 then
         v_version_id := apm_package_version__copy(
			 edit__version_id,
			 edit__new_version_id,
			 edit__version_name,
			 edit__version_uri,
                         ''f''
			);
         else 
	   v_version_id := edit__version_id;			
       end if;
       
       update apm_package_versions 
		set version_uri = edit__version_uri,
		summary = edit__summary,
		description_format = edit__description_format,
		description = edit__description,
		release_date = date_trunc(''days'',now()),
		vendor = edit__vendor,
		vendor_uri = edit__vendor_uri,
                auto_mount = edit__auto_mount,
		installed_p = edit__installed_p,
		data_model_loaded_p = edit__data_model_loaded_p
	    where version_id = v_version_id;

	return v_version_id;
     
end;' language 'plpgsql';

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
    
	insert into apm_package_dependencies(dependency_id, version_id, dependency_type, service_uri, service_version)
	    select nextval(''t_acs_object_id_seq''), v_version_id, dependency_type, service_uri, service_version
	    from apm_package_dependencies
	    where version_id = copy__version_id;
    
	insert into apm_package_files(file_id, version_id, path, file_type, db_type)
	    select nextval(''t_acs_object_id_seq''), v_version_id, path, file_type, db_type
	    from apm_package_files
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

-- DRB: Fix the incredibly slow execution of acs_privilege__add_child()

drop view acs_privilege_descendant_map_view;
create view acs_privilege_descendant_map_view
as select distinct h1.privilege, h2.child_privilege as descendant
   from acs_privilege_hierarchy_index h1, acs_privilege_hierarchy_index h2
   where h2.tree_sortkey between h1.tree_sortkey and tree_right(h1.tree_sortkey)
   union
   select privilege, privilege
   from acs_privileges;

drop trigger acs_priv_hier_ins_del_tr on acs_privilege_hierarchy;
drop function acs_priv_hier_ins_del_tr ();
create or replace function acs_priv_hier_ins_del_tr () returns opaque as '
declare
        new_value       integer;
        new_key         varbit default null;
        v_rec           record;
        deleted_p       boolean;
begin

        -- if more than one node was deleted the second trigger call
        -- will error out.  This check avoids that problem.

        if TG_OP = ''DELETE'' then 
            select count(*) = 0 into deleted_p
              from acs_privilege_hierarchy_index 
             where old.privilege = privilege
               and old.child_privilege = child_privilege;     
       
            if deleted_p then

                return new;

            end if;
        end if;

        -- recalculate the table from scratch.

        delete from acs_privilege_hierarchy_index;

        -- first find the top nodes of the tree

        for v_rec in select privilege, child_privilege
                       from acs_privilege_hierarchy
                      where privilege 
                            NOT in (select distinct child_privilege
                                      from acs_privilege_hierarchy)
                                           
        LOOP

            -- top level node, so find the next key at this level.

            select max(tree_leaf_key_to_int(tree_sortkey)) into new_value 
              from acs_privilege_hierarchy_index
             where tree_level(tree_sortkey) = 1;

             -- insert the new node

            insert into acs_privilege_hierarchy_index 
                        (privilege, child_privilege, tree_sortkey)
                        values
                        (v_rec.privilege, v_rec.child_privilege, tree_next_key(null, new_value));

            -- now recurse down from this node

            PERFORM priv_recurse_subtree(tree_next_key(null, new_value), v_rec.child_privilege);

        end LOOP;

        -- materialize the map view to speed up queries
        -- DanW (dcwickstrom@earthlink.net) 30 Jan, 2003
        delete from acs_privilege_descendant_map;

        insert into acs_privilege_descendant_map (privilege, descendant) 
        select privilege, descendant from acs_privilege_descendant_map_view;

        return new;

end;' language 'plpgsql';

create trigger acs_priv_hier_ins_del_tr after insert or delete
on acs_privilege_hierarchy for each row
execute procedure acs_priv_hier_ins_del_tr ();

------------------------------------------------------------------------------------------------
-- DRB: composition_rel triggers for permission expansion failed to find its way into 4.6.1.
-- I'm not providing code to correct party_approved_member_map because this trigger's only 
-- important when a composition_rel is added to groups which already have members, something
-- existing code doesn't do.

drop trigger composition_rels_in_tr on composition_rels;
drop function composition_rels_in_tr ();

create or replace function composition_rels_in_tr () returns opaque as '
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_error         text;
  map             record;
begin
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint__violation(new.rel_id);

  if v_error is not null then
      raise EXCEPTION ''-20000: %'', v_error;
  end if;

  select object_id_one, object_id_two, rel_type
  into v_object_id_one, v_object_id_two, v_rel_type
  from acs_rels
  where rel_id = new.rel_id;

  -- Insert a row for me in group_element_index
  insert into group_element_index
   (group_id, element_id, rel_id, container_id,
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, new.rel_id, v_object_id_one,
    v_rel_type, ''composition_rel'');

  -- Add to the denormalized party_approved_member_map

  perform party_approved_member__add(v_object_id_one, member_id, rel_id, rel_type)
  from group_approved_member_map m
  where group_id = v_object_id_two
  and not exists (select 1
		  from group_element_map
		  where group_id = v_object_id_one
		  and element_id = m.member_id
		  and rel_id = m.rel_id);

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
  for map in  select distinct group_id
	      from group_component_map
	      where component_id = v_object_id_one 
  LOOP

    -- Add a row for me

    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    values
     (map.group_id, v_object_id_two, new.rel_id, v_object_id_one,
      v_rel_type, ''composition_rel'');

    -- Add to party_approved_member_map

    perform party_approved_member__add(map.group_id, member_id, rel_id, rel_type)
    from group_approved_member_map m
    where group_id = v_object_id_two
    and not exists (select 1
		    from group_element_map
		    where group_id = map.group_id
		    and element_id = m.member_id
		    and rel_id = m.rel_id);

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

  return new;

end;' language 'plpgsql';  

create trigger composition_rels_in_tr after insert on composition_rels
for each row execute procedure composition_rels_in_tr ();

--
-- TO DO: See if this can be optimized now that the member and component
-- mapping tables have been combined
--
drop trigger composition_rels_del_tr on composition_rels;
drop function composition_rels_del_tr();

create or replace function composition_rels_del_tr () returns opaque as '
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  n_rows          integer;
  v_error         text;
  map             record;
begin
  -- First check if removing this relation would violate any relational constraints
  v_error := rel_constraint__violation_if_removed(old.rel_id);
  if v_error is not null then
      raise EXCEPTION ''-20000: %'', v_error;
  end if;

  select object_id_one, object_id_two into v_object_id_one, v_object_id_two
  from acs_rels
  where rel_id = old.rel_id;

  for map in  select *
	      from group_component_map
	      where rel_id = old.rel_id 
  LOOP

    delete from group_element_index
    where rel_id = old.rel_id;

    select count(*) into n_rows
    from group_component_map
    where group_id = map.group_id
    and component_id = map.component_id;

    if n_rows = 0 then

      perform party_approved_member__remove(map.group_id, member_id, rel_id, rel_type)
      from group_approved_member_map
      where group_id = map.group_id
      and container_id = map.component_id;

      delete from group_element_index
      where group_id = map.group_id
      and container_id = map.component_id
      and ancestor_rel_type = ''membership_rel'';
    end if;

  end loop;


  for map in  select *
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
              and group_contains_p(group_id, component_id, rel_id) = ''f'' 
  LOOP

    delete from group_element_index
    where group_id = map.group_id
    and element_id = map.component_id
    and rel_id = map.rel_id;

    select count(*) into n_rows
    from group_component_map
    where group_id = map.group_id
    and component_id = map.component_id;

    if n_rows = 0 then
    end if;

      perform party_approved_member__remove(map.group_id, member_id, rel_id, rel_type)
      from group_approved_member_map
      where group_id = map.group_id
      and container_id = map.component_id;

      delete from group_element_index
      where group_id = map.group_id
      and container_id = map.component_id
      and ancestor_rel_type = ''membership_rel'';

  end loop;

  return old;

end;' language 'plpgsql';

create trigger composition_rels_del_tr before delete on composition_rels
for each row execute procedure composition_rels_del_tr ();

