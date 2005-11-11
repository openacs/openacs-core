<?xml version="1.0"?>
<queryset>

<fullquery name="get_file_title">
    <querytext>
	select 
		title 
	from 
		cr_revisions 
	where 
		revision_id = :file
    </querytext>
</fullquery>

</queryset>