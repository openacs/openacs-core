<?xml version="1.0"?>
<queryset>

<fullquery name="cr_delete_scheduled_files.delete_files">      
      <querytext>
      delete from cr_files_to_delete
      </querytext>
</fullquery>

<fullquery name="cr_scan_mime_types.insert_mime_type">
      <querytext>
	    insert into cr_mime_types
	    (mime_type, file_extension)
	    select
	    :mime_type, :extension
	    from dual
	    where not exists (select 1 from cr_mime_types where mime_type = :mime_type)
      </querytext>
</fullquery>

</queryset>
