<?xml version="1.0"?>
<queryset>

  <fullquery name="get_mime_type">
    <querytext>

      select label
      from cr_mime_types
      where mime_type = :mime_type
      
    </querytext>
  </fullquery>

  <fullquery name="get_extensions">
    <querytext>

      select mime_type,extension
      from cr_extension_mime_type_map
      where mime_type = :mime_type
      order by extension
      
    </querytext>
  </fullquery>
  
</queryset>
