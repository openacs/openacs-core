<?xml version="1.0"?>
<queryset>

<fullquery name="cr_delete_scheduled_files.fetch_paths">      
      <querytext>
      select distinct crftd.path, crftd.storage_area_key
	  from cr_files_to_delete crftd
	  where not exists (select 1 from cr_revisions r where r.content = crftd.path)
      </querytext>
</fullquery>

 
<fullquery name="cr_delete_scheduled_files.delete_files">      
      <querytext>
      delete from cr_files_to_delete
      </querytext>
</fullquery>

</queryset>
