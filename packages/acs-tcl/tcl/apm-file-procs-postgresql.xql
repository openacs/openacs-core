<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="apm_file_add.apm_file_add">
<querytext>
select apm_package_version__add_file(
	NULL,
	:version_id,
	:path,
	:file_type,
        :db_type
)
</querytext>
</fullquery>

<fullquery name="apm_file_remove.apm_file_remove">
<querytext>
select apm_package_version__remove_file (
      :path,
      :version_id
)
</querytext>
</fullquery>

</queryset>
