<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="cr_delete_scheduled_files.fetch_paths">      
      <querytext>

select distinct crftd.path, crftd.storage_area_key
          from cr_files_to_delete crftd
           where not exists (select 1 
                             from cr_revisions r 
                            where r.filename = crftd.path) 
      </querytext>
</fullquery>

</queryset>
