<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="output_portrait">
        <querytext>

        select r.content
        from cr_revisions r
        where r.revision_id = $revision_id

        </querytext>
</fullquery>

</queryset>
