<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="output_portrait">
        <querytext>

        select lob
        from cr_revisions
        where revision_id = :revision_id

        </querytext>
</fullquery>

</queryset>
