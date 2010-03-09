<?xml version="1.0"?>
<queryset>

  <fullquery name="extension_unmap">
    <querytext>

      delete from cr_extension_mime_type_map
      where extension = :extension and mime_type = :mime_type
      
    </querytext>
  </fullquery>
  
</queryset>
