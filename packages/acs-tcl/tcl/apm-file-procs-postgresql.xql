<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

 
<fullquery name="apm_generate_tarball.apm_tarball_insert">      
      <querytext>
      FIX ME LOB 
        update apm_package_versions
           set distribution_tarball = empty_blob(),
               distribution_uri = null,
               distribution_date = sysdate
         where version_id = :version_id
     returning distribution_tarball into :1
    
      </querytext>
</fullquery>

 
<fullquery name="apm_file_add.apm_file_add">      
      <querytext>

	select apm_package_version__add_file(
		:file_id,
		:version_id,
		:path,
		:file_type,
                :db_type
		)
    
      </querytext>
</fullquery>

 
<fullquery name="apm_file_remove.apm_file_remove">      
      <querytext>

	select apm_package_version__remove_file(
				:path,
				:version_id
				)
    
      </querytext>
</fullquery>

 
</queryset>
