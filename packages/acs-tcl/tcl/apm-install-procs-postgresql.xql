<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="acs.acs-tcl.tcl.apm-install-procs.apm_dependency_provided_p.apm_dependency_check">
<querytext>
select apm_package_version__version_name_greater(service_version, :dependency_version) as version_p
	from apm_package_dependencies d, apm_package_types a, apm_package_versions v
	where d.dependency_type = 'provides'
	and d.version_id = v.version_id
	and d.service_uri = :dependency_uri
	and v.installed_p = 't'
	and a.package_key = v.package_key
</querytext>
</fullquery>

<fullquery name="acs.acs-tcl.tcl.apm-install-procs.apm_version_enable.apm_package_version_enable">
<querytext>
SELECT apm_package_version__enable(:version_id);
</querytext>
</fullquery>

<fullquery name="acs.acs-tcl.tcl.apm-install-procs.apm_package_register.application_register">
<querytext>
SELECT apm__register_application (
       :package_key,
       :pretty_name,
       :pretty_plural,
       :package_uri,
       :singleton_p,
       :spec_file_path,
       :spec_file_mtime);
</querytext>
</fullquery>

<fullquery name="acs.acs-tcl.tcl.apm-install-procs.apm_package_register.service_register">
<querytext>
SELECT apm__register_service (
       :package_key,
       :pretty_name,
       :pretty_plural,
       :package_uri,
       :singleton_p,
       :spec_file_path,
       :spec_file_mtime);
</querytext>
</fullquery>

<fullquery name="acs.acs-tcl.tcl.apm-install-procs.apm_package_install.version_exists_p">
<querytext>
select version_id 
from apm_package_versions 
where package_key = :package_key
and version_id = apm_package__highest_version(:package_key)
</querytext>
</fullquery>

<fullquery name="acs.acs-tcl.tcl.apm-install-procs.apm_package_install_version.version_insert">
<querytext>
select apm_package_version__new(
       :version_id,
       :package_key,
       :version_name,
       :version_uri,
       :summary,
       :description_format,
       :description,
       :release_date,
       :vendor,
       :vendor_uri,
       't',
       't');
</querytext>
</fullquery>

<fullquery name="acs.acs-tcl.tcl.apm-install-procs.apm_package_install.package_instantiate_mount">
<querytext>
select apm_package__new(
	  NULL,
          :package_name,
	  :package_key,
	  'apm_package',
	  now(),
	  NULL,
	  NULL,
	  acs__magic_object_id('default_context')
)
</querytext>
</fullquery>


</queryset>
