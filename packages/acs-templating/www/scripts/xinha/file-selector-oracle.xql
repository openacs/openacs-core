<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_fs_contents">      
<querytext>
      
select object_id, name, live_revision, type, title,
	   to_char(last_modified, 'YYYY-MM-DD HH24:MI:SS') as last_modified_ansi,
	   content_size, url, sort_key, file_upload_name,
	   case
	     when :folder_path is null
	     then fs_objects.name
	     else :folder_path || '/' || name
	   end as file_url,
	   case
	     when last_modified >= (current_timestamp - cast('99999' as interval))
	     then 1
	     else 0
	   end as new_p
	from fs_objects
	where parent_id = :folder_id
	and acs_permission.permission_p(fs_objects.object_id, :user_id, 'read')
	$filter_clause
	$order_by_clause
	
</querytext>
</fullquery>

 
</queryset>
