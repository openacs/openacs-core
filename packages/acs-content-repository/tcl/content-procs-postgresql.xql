<?xml version="1.0"?>
<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="cr_count_file_entries.count_entries">
      <querytext>
   SELECT count(*) FROM cr_revisions WHERE substring(content, 1, 100) = substring(:name, 1, 100);
      </querytext>
</fullquery>

</queryset>

