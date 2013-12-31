<?xml version="1.0"?>
<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="cr_delete_scheduled_files.fetch_paths">      
      <querytext>
   SELECT distinct crftd.path, crftd.storage_area_key
   FROM cr_files_to_delete crftd
   WHERE not exists (
   	SELECT 1 FROM cr_revisions r
        WHERE substring(r.content for 100) = substring(crftd.path for 100)
   )
      </querytext>
</fullquery>

</queryset>

