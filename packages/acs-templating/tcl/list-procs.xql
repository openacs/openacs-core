<?xml version="1.0"?>
<queryset>

  <fullquery name="template::list::prepare.count_query">
    <querytext>
      select count(*) from ($list_properties(page_query_substed)) t
    </querytext>
  </fullquery>

</queryset>
