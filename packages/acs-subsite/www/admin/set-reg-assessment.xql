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
    and cf.package_id in (select object_id from site_nodes)	
    order by cr.title
    
      </querytext>
</fullquery>

 
</queryset>







