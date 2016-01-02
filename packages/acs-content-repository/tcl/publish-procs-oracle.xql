<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>


<fullquery name="publish::handle::text.get_revision_id">      
      <querytext>

                begin
                content_revision.to_temporary_clob(:revision_id);
                end;
        
      </querytext>
</fullquery>

<fullquery name="publish::handle::text.get_previous_content">      
      <querytext>

                       select 
                         content
                       from 
                         cr_content_text
                       where 
                         revision_id = :revision_id

      </querytext>
</fullquery>

<fullquery name="publish::write_multiple_blobs.wmb_get_blob_file">      
      <querytext>
      
      select [ad_decode $storage_type file "'[cr_fs_path]' || filename" content] from cr_revisions where revision_id = $revision_id
    
      </querytext>
</fullquery>


<fullquery name="publish::write_content.get_previous_content">      
      <querytext>
      
                       select 
                         content
                       from 
                         cr_content_text
                       where 
                         revision_id = :revision_id
  
      </querytext>
</fullquery>
 
</queryset>
