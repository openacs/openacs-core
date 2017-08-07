<?xml version="1.0"?>
<queryset>

  <fullquery name="template::paginator::init.count_query">
    <querytext>
      select count(*) from ($original_query) t
    </querytext>
  </fullquery>

</queryset>

