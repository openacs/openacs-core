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

                         FIXME: need to handle this blob
                         update 
                            cr_revisions 
                          set
                            content = empty_lob()
                          where
                            revision_id = :revision_id
                          returning content into :1

      </querytext>
</fullquery>

</queryset>
