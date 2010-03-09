<?xml version="1.0"?>
<queryset>

  <fullquery name="get_mime_type_map">
    <querytext>

      select mime.mime_type, mime.label, map.extension
      from cr_mime_types mime left join cr_extension_mime_type_map map
        on (mime.mime_type = map.mime_type)
      [template::list::orderby_clause -orderby -name mime_types]
      
    </querytext>
  </fullquery>
  
  <fullquery name="get_mime_types">
    <querytext>

      select mime_type, label, file_extension as extension
      from cr_mime_types
      [template::list::orderby_clause -orderby -name mime_types]
      
    </querytext>
  </fullquery>
  
</queryset>
