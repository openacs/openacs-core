<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="apm_extract_tarball.distribution_tar_ball_select">      
      <querytext>
      select distribution_tarball from apm_package_versions where version_id = :version_id
      </querytext>
</fullquery>

 
<fullquery name="apm_generate_tarball.apm_tarball_insert">      
      <querytext>
      
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
      
	begin
	:1 := apm_package_version.add_file(
		file_id => :file_id,
		version_id => :version_id,
		path => :path,
		file_type => :file_type,
                db_type => :db_type
		);
	end;
    
      </querytext>
</fullquery>

 
<fullquery name="apm_file_remove.apm_file_remove">      
      <querytext>
      
	begin
	apm_package_version.remove_file(
				path => :path,
				version_id => :version_id
				);
	end;
    
      </querytext>
</fullquery>

 
</queryset>
