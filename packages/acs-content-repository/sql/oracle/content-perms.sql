--------------------------------------------------------------
--
-- Set up the basic permissions used by the CMS, and invent some
-- api in dealing with them
--
--------------------------------------------------------------

declare 
  v_perms varchar2(1) := 'f';
begin
  
  begin
    select 't' into v_perms from dual 
    where exists (select 1 from acs_privileges 
                  where privilege = 'cm_root');
  exception when no_data_found then
    v_perms := 'f';
  end;

  if v_perms <> 't' then

    -- Dummy root privilege
    acs_privilege.create_privilege('cm_root', 'Root', 'Root');
    -- He can do everything
    acs_privilege.create_privilege('cm_admin', 'Administrator', 'Administrators');
    acs_privilege.create_privilege('cm_write', 'Write', 'Write');    
    acs_privilege.create_privilege('cm_new', 'Create New Item', 'Create New Item');    
    acs_privilege.create_privilege('cm_examine', 'Admin-level Read', 'Admin-level Read');    
    acs_privilege.create_privilege('cm_read', 'User-level Read', 'User-level Read');    
    acs_privilege.create_privilege('cm_item_workflow', 'Modify Workflow', 'Modify Workflow');    
    acs_privilege.create_privilege('cm_perm_admin', 'Modify Any Permissions', 'Modify Any Permissions');    
    acs_privilege.create_privilege('cm_perm', 'Donate Permissions', 'Donate Permissions');    

    acs_privilege.add_child('cm_root', 'cm_admin');           -- Do anything to an object
    acs_privilege.add_child('cm_admin', 'cm_write');          -- Do anything to an object
    acs_privilege.add_child('cm_write', 'cm_new');            -- Create subitems
    acs_privilege.add_child('cm_new', 'cm_examine');          -- View in admin mode 
    acs_privilege.add_child('cm_examine', 'cm_read');         -- View in user mode
    acs_privilege.add_child('cm_write', 'cm_item_workflow');  -- Change item workflow

    acs_privilege.add_child('cm_admin', 'cm_perm_admin');     -- Modify any permissions
    acs_privilege.add_child('cm_perm_admin', 'cm_perm');      -- Modify any permissions on an item

    -- Proper inheritance
    acs_privilege.add_child('admin', 'cm_root');

  end if;
  
end;
/
show errors

create or replace package body content_permission
is

  procedure inherit_permissions (
    parent_object_id  in acs_objects.object_id%TYPE,
    child_object_id   in acs_objects.object_id%TYPE,
    child_creator_id  in parties.party_id%TYPE default null
  )
  is
    v_dummy integer;
  begin

    -- Determine if the child is a direct descendant of the
    -- parent
    select 1 into v_dummy from acs_objects 
    where object_id = child_object_id 
    and context_id = parent_object_id;

    -- Copy everything one level down
    insert into acs_permissions (
      object_id, grantee_id, privilege
    ) (
      select 
        inherit_permissions.child_object_id as object_id, 
        grantee_id, 
        privilege
      from 
        acs_permissions
      where 
        object_id = parent_object_id
    );

    if child_creator_id is not null then
      -- Grant cm_write and cm_perm to the child creator
      if content_permission.permission_p (
	   child_object_id, child_creator_id, 'cm_perm'
	 ) <> 't' then
        -- Turn off inheritance and grant permission
        update acs_objects set security_inherit_p = 'f'
          where object_id = child_object_id;
	acs_permission.grant_permission (
	   child_object_id, child_creator_id, 'cm_perm'
	);
      end if;

      if content_permission.permission_p (
	   child_object_id, child_creator_id, 'cm_write'
	 ) <> 't' then
	acs_permission.grant_permission (
	   child_object_id, child_creator_id, 'cm_write'
	);
      end if;
    end if;

  exception when no_data_found then
    raise_application_error(-20000, 'Child object is not actually a child
of the parent object in inherit_permissions');
   
  end inherit_permissions;

  function has_grant_authority ( 
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2
  is
  begin
    -- Can donate permission only if you already have it and you have cm_perm,
    -- OR you have cm_perm_admin
    if content_permission.permission_p (object_id, holder_id, 'cm_perm_admin')= 't' 
       or (
         content_permission.permission_p (object_id, holder_id, 'cm_perm') = 't' and
         content_permission.permission_p (object_id, holder_id, privilege) = 't'
       ) 
    then
      return 't';
    else
      return 'f';
    end if;
  end has_grant_authority;

  function has_revoke_authority (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE
  ) return varchar2
  is
    cursor c_perm_cur is
      select 't' from 
        (select object_id from acs_objects 
           connect by prior context_id = object_id
           start with object_id = has_revoke_authority.object_id) t,
        (select privilege, child_privilege from acs_privilege_hierarchy
           connect by prior privilege = child_privilege
           start with child_privilege = 'cm_perm') h
      where
        content_permission.permission_p(
          t.object_id, has_revoke_authority.holder_id, h.child_privilege
        ) = 't'
      and
        content_permission.permission_p(
          t.object_id, has_revoke_authority.revokee_id, h.privilege
        ) = 'f';

    v_ret varchar2(1);   
  begin
    open c_perm_cur;
    fetch c_perm_cur into v_ret;
    if c_perm_cur%NOTFOUND then
      v_ret := 'f';
    end if;
    close c_perm_cur;
    return v_ret;
  end has_revoke_authority;


  procedure grant_permission_h (
    object_id         in acs_objects.object_id%TYPE,
    grantee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) 
  is
    cursor c_priv_cur is
      select descendant from acs_privilege_descendant_map
      where privilege = grant_permission_h.privilege
      and descendant <> grant_permission_h.privilege;
  
    v_privilege acs_privilege_descendant_map.privilege%TYPE;
  begin
  
    -- If the permission is already granted, do nothing
    if content_permission.permission_p (
         object_id, grantee_id, privilege
       ) = 't' then
      return;
    end if;
 
    -- Grant the parent, make sure there is no inheritance
    update acs_objects set security_inherit_p = 'f'
      where object_id = grant_permission_h.object_id;
    acs_permission.grant_permission(object_id, grantee_id, privilege);
    
    -- Revoke the children - they are no longer relevant
    open c_priv_cur;
    loop
      fetch c_priv_cur into v_privilege;
      exit when c_priv_cur%NOTFOUND;
      acs_permission.revoke_permission(object_id, grantee_id, v_privilege);
    end loop;
    close c_priv_cur;
  end grant_permission_h;  

  procedure grant_permission (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    recepient_id      in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f',
    object_type       in acs_objects.object_type%TYPE default 'content_item'
  )
  is
    cursor c_object_cur is
      select 
        o.object_id
      from
        (select object_id, object_type from acs_objects 
           connect by context_id = prior object_id
           start with object_id = grant_permission.object_id) o
      where
        has_grant_authority (
          o.object_id, holder_id, grant_permission.privilege
        ) = 't'
      and
        content_item.is_subclass (o.object_type, grant_permission.object_type) = 't';

    v_object_id acs_objects.object_id%TYPE;
         
  begin
  
    open c_object_cur;
    loop

      -- Determine if the grant is possible
      fetch c_object_cur into v_object_id;
      exit when c_object_cur%NOTFOUND;
   
      -- Grant the parent and revoke the children, since we don't need them
      -- anymore
      content_permission.grant_permission_h (
        v_object_id, recepient_id, privilege
      );
      
      exit when is_recursive = 'f';
    
    end loop;
    close c_object_cur;
         
  end grant_permission;

  procedure revoke_permission_h (
    object_id         in acs_objects.object_id%TYPE,
    revokee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) 
  is
    cursor c_perm_child_cur is
      select child_privilege from acs_privilege_hierarchy
      where privilege = revoke_permission_h.privilege;
     
    v_privilege acs_privileges.privilege%TYPE;
  begin
    
    -- Grant all child privileges of the parent privilege
    open c_perm_child_cur;
    loop
      fetch c_perm_child_cur into v_privilege;
      exit when c_perm_child_cur%NOTFOUND;
      acs_permission.grant_permission (
        revoke_permission_h.object_id,  
        revoke_permission_h.revokee_id,
        v_privilege  
      );
    end loop;
    close c_perm_child_cur;

    -- Revoke the parent privilege
    acs_permission.revoke_permission (
      revoke_permission_h.object_id,        
      revoke_permission_h.revokee_id,         
      revoke_permission_h.privilege
    );
  end revoke_permission_h;

  procedure revoke_permission (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f',
    object_type       in acs_objects.object_type%TYPE default 'content_item'
  )
  is
    cursor c_object_cur is
      select 
        o.object_id 
      from
        (select object_id, object_type from acs_objects 
           connect by context_id = prior object_id
           start with object_id = revoke_permission.object_id) o
    where 
      has_revoke_authority (o.object_id, holder_id, privilege, revokee_id) = 't'
    and
      content_item.is_subclass(o.object_type, revoke_permission.object_type) = 't';   

    v_object_id acs_objects.object_id%TYPE;

  begin

    open c_object_cur;
    loop
      fetch c_object_cur into v_object_id;
      exit when c_object_cur%NOTFOUND;
   
      content_permission.revoke_permission_h (
        v_object_id, revokee_id, privilege
      );
      
      exit when is_recursive = 'f';
    
    end loop;
    close c_object_cur;

  end revoke_permission;

  function permission_p (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2
  is
 
/*    cursor c_perm_cur is
      select 't' as truth from 
        acs_privilege_descendant_map pdm,
        acs_permissions p,
        (select 
          group_id as party_id from group_member_map 
          where member_id = permission_p.holder_id
         union select 
           permission_p.holder_id as party_id from dual
        ) gm
      where
        p.privilege = pdm.privilege
      and
        p.object_id = permission_p.object_id
      and
        p.grantee_id = gm.party_id
      and 
        p.privilege = pdm.privilege
      and 
        pdm.descendant = permission_p.privilege;
 
    v_perm varchar2(1);*/
    
  begin
      
/*    open c_perm_cur;
    fetch c_perm_cur into v_perm;
    if c_perm_cur%NOTFOUND then
      v_perm := 'f';
    end if;
    close c_perm_cur;
    return v_perm; */

    return acs_permission.permission_p (object_id, holder_id, privilege);
  
  end permission_p;

  -- Determine if the CMS admin exists
  function cm_admin_exists 
  return varchar2
  is
    v_exists varchar2(1);
  begin
    
    select 't' into v_exists from dual 
     where exists (
       select 1 from acs_permissions 
       where privilege in ('cm_admin', 'cm_root')
     );

    return v_exists;

  exception when no_data_found then
    return 'f';
  end cm_admin_exists;


end content_permission;
/
show errors

                                          
         
        
   
    

      









