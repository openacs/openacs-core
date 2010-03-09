<?xml version="1.0"?>
<queryset>

  <fullquery name="get_mime_type">
    <querytext>

      select label
      from cr_mime_types
      where mime_type = :mime_type
      
    </querytext>
  </fullquery>

</queryset>
