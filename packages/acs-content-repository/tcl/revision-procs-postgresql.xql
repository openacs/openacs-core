<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="cr_revision_upload.get_revision_id">      
      <querytext>

        select content_revision__new(:title, 
                                     null,
                                     now(),
                                     'text/plain',
                                     ' ',
                                     :item_id
                                     )

      </querytext>
</fullquery>

<fullquery name="cr_revision_upload.dml_revision_from_file">      
      <querytext>

                         update 
                            cr_revisions 
                          set
                            content = '[cr_create_content_file $item_id $revision_id $path]'
                          where
                            revision_id = :revision_id

      </querytext>
</fullquery>

</queryset>
