<?xml version="1.0"?>
<queryset>

<fullquery name="acs.acs-tcl.tcl.apm-file-procs.apm_file_add.apm_file_add">
<querytext>
select apm_package_version__add_file(
	NULL,
	:version_id,
	:path,
	:file_type
)
</querytext>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
</fullquery>

<fullquery name="acs.acs-tcl.tcl.apm-file-procs.apm_file_remove.apm_file_remove">
<querytext>
selec apm_package_version__remove_file (
      :path,
      :version_id
)
</querytext>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
</fullquery>

</queryset>
