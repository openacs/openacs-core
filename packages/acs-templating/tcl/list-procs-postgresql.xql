<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="template::list::prepare.pagination_query">
    <querytext>
       $list_properties(page_query_substed) offset [expr {$first_row - 1}]
       limit [expr {$last_row - $first_row + 1}]
    </querytext>
  </fullquery>

</queryset>
