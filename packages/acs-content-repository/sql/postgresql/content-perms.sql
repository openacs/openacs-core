--------------------------------------------------------------
--
-- Set up the basic permissions used by the CMS, and invent some
-- api in dealing with them
--
--------------------------------------------------------------

create function inline_0 ()
returns integer as '
declare 
        found_p         boolean;
begin

  select count(*) > 0 into found_p from dual 
   where exists (select 1 from acs_privileges 
                  where privilege = ''cm_root'');

  if NOT found_p then

    -- Dummy root privilege
    PERFORM acs_privilege__create_privilege(''cm_root'', ''Root'', ''Root'');
    -- He can do everything
    PERFORM acs_privilege__create_privilege(''cm_admin'', ''Administrator'', ''Administrators'');
    PERFORM acs_privilege__create_privilege(''cm_write'', ''Write'', ''Write'');    
    PERFORM acs_privilege__create_privilege(''cm_new'', ''Create New Item'', ''Create New Item'');    
    PERFORM acs_privilege__create_privilege(''cm_examine'', ''Admin-level Read'', ''Admin-level Read'');    
    PERFORM acs_privilege__create_privilege(''cm_read'', ''User-level Read'', ''User-level Read'');    
    PERFORM acs_privilege__create_privilege(''cm_item_workflow'', ''Modify Workflow'', ''Modify Workflow'');    
    PERFORM acs_privilege__create_privilege(''cm_perm_admin'', ''Modify Any Permissions'', ''Modify Any Permissions'');    
    PERFORM acs_privilege__create_privilege(''cm_perm'', ''Donate Permissions'', ''Donate Permissions'');    

    PERFORM acs_privilege__add_child(''cm_root'', ''cm_admin'');           -- Do anything to an object
    PERFORM acs_privilege__add_child(''cm_admin'', ''cm_write'');          -- Do anything to an object
    PERFORM acs_privilege__add_child(''cm_write'', ''cm_new'');            -- Create subitems
    PERFORM acs_privilege__add_child(''cm_new'', ''cm_examine'');          -- View in admin mode 
    PERFORM acs_privilege__add_child(''cm_examine'', ''cm_read'');         -- View in user mode
    PERFORM acs_privilege__add_child(''cm_write'', ''cm_item_workflow'');  -- Change item workflow

    PERFORM acs_privilege__add_child(''cm_admin'', ''cm_perm_admin'');     -- Modify any permissions
    PERFORM acs_privilege__add_child(''cm_perm_admin'', ''cm_perm'');      -- Modify any permissions on an item

    -- Proper inheritance
    PERFORM acs_privilege__add_child(''admin'', ''cm_root'');

  end if;
  
  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


-- create or replace package body content_permission
-- procedure inherit_permissions
create function content_permission__inherit_permissions (integer,integer,integer)
returns integer as '
declare
  inherit_permissions__parent_object_id       alias for $1;  
  inherit_permissions__child_object_id        alias for $2;  
  inherit_permissions__child_creator_id       alias for $3;  -- default null  
  v_dummy                                     integer;       
begin

    -- Determine if the child is a direct descendant of the
    -- parent
    select 1 into v_dummy from acs_objects 
    where object_id = inherit_permissions__child_object_id 
    and context_id = inherit_permissions__parent_object_id;

    if NOT FOUND then
      raise EXCEPTION ''-20000: Child object is not actually a child of the parent object in inherit_permissions'';
    end if;

    -- Copy everything one level down
    insert into acs_permissions
      select 
        inherit_permissions__child_object_id as object_id, 
        grantee_id, 
        privilege
      from 
        acs_permissions
      where 
        object_id = inherit_permissions__parent_object_id;

    if inherit_permissions__child_creator_id is not null then
      -- Grant cm_write and cm_perm to the child creator
      if content_permission__permission_p (
	   inherit_permissions__child_object_id, 
           inherit_permissions__child_creator_id, 
           ''cm_perm''
	 ) != ''t'' then
        -- Turn off inheritance and grant permission
        update acs_objects set security_inherit_p = ''f''
          where object_id = inherit_permissions__child_object_id;
	PERFORM acs_permission__grant_permission (
	   inherit_permissions__child_object_id, 
           inherit_permissions__child_creator_id, 
           ''cm_perm''
	);
      end if;

      if content_permission__permission_p (
	   inherit_permissions__child_object_id, 
           inherit_permissions__child_creator_id, 
           ''cm_write''
	 ) != ''t'' then
	PERFORM acs_permission__grant_permission (
	   inherit_permissions__child_object_id, 
           inherit_permissions__child_creator_id, 
           ''cm_write''
	);
      end if;
    end if;
   
    return 0; 
end;' language 'plpgsql';


-- function has_grant_authority
create function content_permission__has_grant_authority (integer,integer,varchar)
returns boolean as '
declare
  object_id              alias for $1;  
  holder_id              alias for $2;  
  privilege              alias for $3;  
begin
    -- Can donate permission only if you already have it and you have cm_perm,
    -- OR you have cm_perm_admin
    if content_permission__permission_p (object_id, holder_id, ''cm_perm_admin'')= ''t'' 
       or (
         content_permission__permission_p (object_id, holder_id, ''cm_perm'') = ''t'' and
         content_permission__permission_p (object_id, holder_id, privilege) = ''t''
       ) 
    then
      return ''t'';
    else
      return ''f'';
    end if;
   
end;' language 'plpgsql';


-- function has_revoke_authority
create function content_permission__has_revoke_authority (integer,integer,varchar,integer)
returns boolean as '
declare
  has_revoke_authority__object_id              alias for $1;  
  has_revoke_authority__holder_id              alias for $2;  
  has_revoke_authority__privilege              alias for $3;  
  has_revoke_authority__revokee_id             alias for $4;  
begin

    -- DRB: Note that the privilege selection doesn't use the slick tree_ancestor_keys
    -- trick.  There are two reasons for this.  The first is that we might have a set of
    -- tree_sortkeys returned from the acs_privilege_hierarchy_index when child_privilege
    -- is ''cm_perm''.  The second is that this table is relatively small anyway and the
    -- old style's probably just as efficient as the first as an index scan is only preferred
    -- by the Postgres optimizer when it will significantly reduce the number of rows scanned.

    -- DanW: Removed hierarchy index query in favor of using descendant map. 

    return exists (select 1 from 
        (select o2.object_id 
           from (select tree_ancestor_keys(acs_object__get_tree_sortkey(has_revoke_authority__object_id)) as tree_sortkey) parents,
             acs_objects o2
          where o2.tree_sortkey = parents.tree_sortkey) t
        (select privilege, descendant as child_privilege 
           from acs_privilege_descendant_map 
          where descendant = 'cm_perm') h
      where
        content_permission__permission_p(
          t.object_id, has_revoke_authority__holder_id, h.child_privilege
        ) 
      and not
        content_permission__permission_p(
          t.object_id, has_revoke_authority__revokee_id, h.privilege
        ));    
   
end;' language 'plpgsql';


-- procedure grant_permission_h
create function content_permission__grant_permission_h (integer,integer,varchar)
returns integer as '
declare
  grant_permission_h__object_id              alias for $1;  
  grant_permission_h__grantee_id             alias for $2;  
  grant_permission_h__privilege              alias for $3;  
  v_privilege                                acs_privilege_descendant_map.privilege%TYPE;
  v_rec                                      record;
begin
  
    -- If the permission is already granted, do nothing
    if content_permission__permission_p (
         grant_permission_h__object_id, 
         grant_permission_h__grantee_id, 
         grant_permission_h__privilege
       ) = ''t'' then
      return null;
    end if;
 
    -- Grant the parent, make sure there is no inheritance
    update acs_objects set security_inherit_p = ''f''
      where object_id = grant_permission_h__object_id;

    PERFORM acs_permission__grant_permission(grant_permission_h__object_id, 
                                             grant_permission_h__grantee_id, 
                                             grant_permission_h__privilege);
    
    -- Revoke the children - they are no longer relevant
    
    for v_rec in select descendant from acs_privilege_descendant_map
      where privilege = grant_permission_h__privilege
      and descendant <> grant_permission_h__privilege;
    LOOP
        PERFORM acs_permission__revoke_permission(
                                                grant_permission_h__object_id, 
                                                grant_permission_h__grantee_id,
                                                v_rec.descendant
        );
    end LOOP;

    return 0; 
end;' language 'plpgsql';


-- procedure grant_permission
create function content_permission__grant_permission (integer,integer,varchar,integer,boolean,varchar)
returns integer as '
declare
  grant_permission__object_id      alias for $1;  
  grant_permission__holder_id      alias for $2;  
  grant_permission__privilege      alias for $3;  
  grant_permission__recepient_id   alias for $4;  
  grant_permission__is_recursive   alias for $5;  -- default ''f''  
  grant_permission__object_type    alias for $6;  -- default ''content_item''
  v_object_id                              acs_objects.object_id%TYPE;
begin
--      select 
--       o.object_id
--      from
--        (select object_id, object_type from acs_objects 
--           connect by context_id = prior object_id
--           start with object_id = grant_permission__object_id) o
--      where
--        content_permission__has_grant_authority (
--          o.object_id, holder_id, grant_permission__privilege
--        ) = ''t''
--      and
--        content_item__is_subclass (o.object_type, grant_permission__object_type) = ''t''
  
    for v_rec in select 
        o.object_id
      from
        (select o1.object_id, o1.object_type 
         from acs_objects o1, acs_objects o2
         where o2.object_id = grant_permission__object_id
           and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)) o
      where content_permission__has_grant_authority (o.object_id, holder_id, grant_permission__privilege)
        and content_item__is_subclass (o.object_type, grant_permission__object_type)
    LOOP   
      -- Grant the parent and revoke the children, since we do not need them
      -- anymore
      PERFORM content_permission__grant_permission_h (
        v_rec.object_id, 
        grant_permission__recepient_id, 
        grant_permission__privilege
      );      
      exit when grant_permission__is_recursive = ''f'';    
    end loop;
         
    return 0; 
end;' language 'plpgsql';


-- procedure revoke_permission_h
create function content_permission__revoke_permission_h (integer,integer,varchar)
returns integer as '
declare
  revoke_permission_h__object_id              alias for $1;  
  revoke_permission_h__revokee_id             alias for $2;  
  revoke_permission_h__privilege              alias for $3;  
  v_rec                                       record;
begin
    
    -- Grant all child privileges of the parent privilege
    for v_rec in select child_privilege from acs_privilege_hierarchy
      where privilege = revoke_permission_h__privilege
    LOOP
      PERFORM acs_permission__grant_permission (
        revoke_permission_h__object_id,  
        revoke_permission_h__revokee_id,
        v_rec.child_privilege 
      );
    end loop;

    -- Revoke the parent privilege
    PERFORM acs_permission__revoke_permission (
      revoke_permission_h__object_id,        
      revoke_permission_h__revokee_id,         
      revoke_permission_h__privilege
    );

    return 0; 
end;' language 'plpgsql';


-- procedure revoke_permission
create function content_permission__revoke_permission (integer,integer,varchar,integer,boolean,varchar)
returns integer as '
declare
  revoke_permission__object_id    alias for $1;  
  revoke_permission__holder_id    alias for $2;  
  revoke_permission__privilege    alias for $3;  
  revoke_permission__revokee_id   alias for $4;  
  revoke_permission__is_recursive alias for $5;  -- default ''f''  
  revoke_permission__object_type  alias for $6;  -- default ''content_item''
  v_rec                                     record;
begin
--                     select object_id, object_type from acs_objects 
--                    connect by context_id = prior object_id
--                    start with object_id = revoke_permission__object_id

    for v_rec in select o.object_id 
                 from (select o1.object_id, o1.object_type 
                       from acs_objects o1, acs_objects o2
                       where o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
                         and o2.object_id = revoke_permission__object_id) o
                 where 
                   content_permission__has_revoke_authority (o.object_id, revoke_permission__holder_id, revoke_permission__privilege, revoke_permission__revokee_id) = ''t''
                 and
                   content_item__is_subclass(o.object_type, revoke_permission__object_type) = ''t''
    LOOP   
      PERFORM content_permission__revoke_permission_h (
        v_rec.object_id, 
        revoke_permission__revokee_id, 
        revoke_permission__privilege
      );
      
      exit when revoke_permission__is_recursive = ''f'';    
    end loop;

    return 0; 
end;' language 'plpgsql';


-- function permission_p
create function content_permission__permission_p (integer,integer,varchar)
returns boolean as '
declare
  object_id              alias for $1;  
  holder_id              alias for $2;  
  privilege              alias for $3;  
begin

    return acs_permission__permission_p (object_id, holder_id, privilege);
   
end;' language 'plpgsql';

  -- Determine if the CMS admin exists
create function cm_admin_exists () returns boolean as '
begin
    
    return count(*) > 0 from dual 
     where exists (
       select 1 from acs_permissions 
       where privilege in (''cm_admin'', ''cm_root'')
     );

end;' language 'plpgsql';

-- show errors

                                          
         
        
   
