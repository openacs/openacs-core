<?xml version="1.0"?>
<queryset>

<fullquery name="cr_delete_scheduled_files.fetch_paths">      
      <querytext>
 SELECT distinct crftd.path as storage_area_key
   FROM cr_files_to_delete crftd
  WHERE not exists (SELECT 1
                      FROM cr_revisions r
                     WHERE r.content = crftd.path)
      </querytext>
</fullquery>

<fullquery name="cr_delete_scheduled_files.delete_files">      
      <querytext>
      delete from cr_files_to_delete
      </querytext>
</fullquery>

</queryset>
