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

<fullquery name="cr_after_install.get_template_id">
      <querytext>

		select live_revision as revision_id
		from cr_items
		where name = 'default_template'
		and parent_id = -200

      </querytext>
</fullquery>

<fullquery name="cr_after_install.update_default_template">
      <querytext>

		update cr_revisions
		set content = empty_blob()
		where revision_id = :revision_id
		returning content into :1

      </querytext>
</fullquery>

<fullquery name="cr_after_upgrade.get_template_id">
      <querytext>

		select live_revision as revision_id
		from cr_items
		where name = 'default_template'
		and parent_id = -200

      </querytext>
</fullquery>

<fullquery name="cr_after_upgrade.update_default_template">
      <querytext>

		update cr_revisions
		set content = empty_blob()
		where revision_id = :revision_id
		returning content into :1

      </querytext>
</fullquery>

</queryset>
