<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="object_info">      
      <querytext>
    select acs_object.name(object_id) as object_name,
           acs_object.name(context_id) as parent_object_name,
           context_id
    from   acs_objects
    where  object_id = :object_id

      </querytext>
</fullquery>


<fullquery name="permissions">      
      <querytext>
    select ptab.grantee_id,
           acs_object.name(ptab.grantee_id) as grantee_name,
           o.object_type,
           [join $select_clauses ", "],
           sum([join $privs "_p + "]_p) as any_perm_p_
    from   (select grantee_id,
                   [join $from_all_clauses ", "]
            from   acs_permissions_all
            where  object_id = :object_id
            union all
            select grantee_id,
                   [join $from_direct_clauses ", "]
            from   acs_permissions
            where  object_id = :object_id
            union all
            select -1 as grantee_id,
                   [join $from_dummy_clauses ", "]
            from  dual
            union all
            select -2 as grantee_id,
                   [join $from_dummy_clauses ", "] 
            from  dual
            union all
            select component_id as grantee_id,
                   [join $from_dummy_clauses ", "] 
            from   group_component_map
            where  group_id = :application_group_id
            union all
            select segment_id as grantee_id,
                   [join $from_dummy_clauses ", "] 
            from   rel_segments rel_seg
            where  rel_seg.group_id = :application_group_id
            union all
            select segment_id as grantee_id,
                   [join $from_dummy_clauses ", "] 
            from   rel_segments rel_seg,
                   group_component_map gcm
            where  gcm.group_id = :application_group_id
            and    rel_seg.group_id = gcm.group_id
           ) ptab,
           acs_objects o
    where  o.object_id = ptab.grantee_id
    and    not exists (select 1
                       from acs_object_party_privilege_map m,
                         (select object_id as root
                          from acs_magic_objects
                          where name = 'security_context_root') amo
                       where m.object_id = amo.root
                         and m.party_id = ptab.grantee_id
                         and m.privilege = 'admin')
    group  by ptab.grantee_id, acs_object.name(ptab.grantee_id), o.object_type
    order  by object_type desc, grantee_name
      </querytext>
</fullquery>

 
</queryset>
