<?xml version="1.0"?>
<queryset>

<fullquery name="get_all_assessments">
      <querytext>
      
    select cr.title,ci.item_id as assessment_id
    from cr_folders cf, cr_items ci, cr_revisions cr, as_assessments a
    where cr.revision_id = ci.latest_revision
    and a.assessment_id = cr.revision_id
    and a.anonymous_p = 't'
    and ci.parent_id = cf.folder_id
    and cf.package_id in (select object_id from site_nodes) and -1 in (select grantee_id from acs_permissions where 
    object_id=ci.item_id and  privilege='read')	
    order by cr.title
    
      </querytext>
</fullquery>

<fullquery name="package_id">
      <querytext>
      
      select package_id from cr_folders where folder_id=(select context_id from acs_objects where object_id=:assessment_id)
    
      </querytext>
</fullquery>

<fullquery name="get_instance_id">
      <querytext>
      select package_id from apm_packages where package_key='assessment' and package_id in (select object_id from site_nodes)
      </querytext>
</fullquery>
 
</queryset>












