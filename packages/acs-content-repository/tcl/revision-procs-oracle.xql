<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="cr_revision_upload.get_revision_id">      
      <querytext>

        begin
                :1 := content_revision.new(title     => :title, 
                                           item_id   => :item_id, 
                                           v_content => null);
        end;

      </querytext>
</fullquery>

<fullquery name="cr_revision_upload.dml_revision_from_file">      
      <querytext>

                         update 
                            cr_revisions 
                          set
                            content = empty_blob()
                          where
                            revision_id = :revision_id
                          returning content into :1

      </querytext>
</fullquery>

</queryset>
