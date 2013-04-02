--
-- procedure acs_permission__permission_p/3
--
CREATE OR REPLACE FUNCTION acs_permission__permission_p(
   permission_p__object_id integer,
   permission_p__party_id integer,
   permission_p__privilege varchar
) RETURNS boolean AS $$
DECLARE
    exists_p                          boolean;
BEGIN
    return exists (With RECURSIVE object_context(object_id, context_id) AS (

            select permission_p__object_id, permission_p__object_id 
            from acs_objects 
            where object_id = permission_p__object_id

            union all

            select ao.object_id,
            case when (ao.security_inherit_p = 'f' or ao.context_id is null) 
            then acs__magic_object_id('security_context_root') else ao.context_id end
            from object_context oc, acs_objects ao
            where ao.object_id = oc.context_id
            and ao.object_id != acs__magic_object_id('security_context_root')

        ), privilege_ancestors(privilege, child_privilege) AS (

            select permission_p__privilege, permission_p__privilege 
           
            union all

            select aph.privilege, aph.child_privilege
            from privilege_ancestors pa join acs_privilege_hierarchy aph
            on aph.child_privilege = pa.privilege

        ) select
          1
          from
          acs_permissions p
          join  party_approved_member_map pap on pap.party_id   =  p.grantee_id
          join  privilege_ancestors pa  on  pa.privilege  =  p.privilege
          join  object_context oc on  p.object_id =  oc.context_id      
          where pap.member_id = permission_p__party_id
        );
END;
$$ LANGUAGE plpgsql stable;


-- for tsearch

select define_function_args('acs_permission__permission_p_recursive_array','a_objects,a_party_id,a_privilege');

CREATE OR REPLACE FUNCTION  acs_permission__permission_p_recursive_array(
    permission_p__objects integer[],
    permission_p__party_id integer, 
    permission_p__privilege varchar
) RETURNS table (object_id integer, orig_object_id integer) as $$
BEGIN
    return query With RECURSIVE object_context(object_id, context_id, orig_object_id) AS (

            select unnest(permission_p__objects), unnest(permission_p__objects), unnest(permission_p__objects)

            union all

            select ao.object_id,
            case when (ao.security_inherit_p = 'f' or ao.context_id is null) 
            then acs__magic_object_id('security_context_root') else ao.context_id END, 
            oc.orig_object_id
            from object_context oc, acs_objects ao
            where ao.object_id = oc.context_id
            and ao.object_id != acs__magic_object_id('security_context_root')

        ), privilege_ancestors(privilege, child_privilege) AS (

           select permission_p__privilege, permission_p__privilege
           from acs_privilege_hierarchy 
           where privilege = permission_p__privilege

           union all

           select aph.privilege, aph.child_privilege
           from privilege_ancestors pa join acs_privilege_hierarchy aph
           on aph.child_privilege = pa.privilege

        ) select
          p.object_id, oc.orig_object_id
          from
          acs_permissions p
          join  party_approved_member_map pap on pap.party_id   =  p.grantee_id
          join  privilege_ancestors pa  on  pa.privilege  =  p.privilege
          join  object_context oc on  p.object_id =  oc.context_id
          where pap.member_id = permission_p__party_id
      ;
END; 
$$ LANGUAGE plpgsql stable;

CREATE OR REPLACE FUNCTION site_node__url(
   url__node_id integer
) RETURNS varchar AS $$
BEGIN
    return ( With RECURSIVE site_nodes_recursion(parent_id, path, directory_p, node_id) as (
    
        select parent_id, ARRAY[name || case when directory_p then '/' else ' ' end]::text[] as path, directory_p, node_id
        from site_nodes where node_id = url__node_id
    
        UNION ALL
    
        select sn.parent_id, sn.name::text || snr.path , sn.directory_p, snr.parent_id
        from site_nodes sn join site_nodes_recursion snr on sn.node_id = snr.parent_id 
        where snr.parent_id is not null    

    ) select array_to_string(path,'/') from site_nodes_recursion where parent_id is null
);
END; 
$$ LANGUAGE plpgsql; 
