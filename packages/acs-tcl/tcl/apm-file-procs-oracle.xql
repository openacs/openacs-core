<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="apm_generate_tarball.create_item">      
      <querytext>

begin
 :1 := content_item.new(name => 'tarball-for-package-version-${version_id}',
                        creation_ip => :creation_ip
                        );
end;

      </querytext>
</fullquery>

<fullquery name="apm_generate_tarball.create_revision">      
      <querytext>

        begin
          :1 := content_revision.new(title => '${package_key}-tarball',
                                   description => 'gzipped tarfile',
                                   text => 'not_important',
                                   mime_type => 'application/x-compressed',
                                   item_id => :item_id,
                                   creation_user => :user_id,
                                   creation_ip => :creation_ip
                );

          update cr_items
          set live_revision = :1
          where item_id = :item_id;
        end;

      </querytext>
</fullquery>

<fullquery name="apm_generate_tarball.update_tarball">      
      <querytext>

                update cr_revisions
                set content = empty_blob()
                where revision_id = :revision_id
                returning content into :1

      </querytext>
</fullquery>


<fullquery name="apm_extract_tarball.distribution_tar_ball_select">      
      <querytext>

   select content 
     from cr_revisions 
    where revision_id = (select content_item.get_latest_revision(item_id)
                           from apm_package_versions 
                          where version_id = :version_id)

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
