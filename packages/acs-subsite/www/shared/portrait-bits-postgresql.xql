<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="output_portrait">
        <querytext>

        select r.lob, i.storage_type
        from cr_revisions r, cr_items i
        where r.item_id = i.item_id 
          and r.revision_id = :revision_id

        </querytext>
</fullquery>

</queryset>
