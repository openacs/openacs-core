<?xml version="1.0"?>
<queryset>

   <fullquery name="lang::util::charset_for_locale.charset_for_locale">      
      <querytext>
      
        select mime_charset
        from   ad_locales 
        where  locale = :locale
    
      </querytext>
   </fullquery>

   <fullquery name="lang::util::default_locale_from_lang.default_locale_from_lang">
      <querytext>
      
        select locale 
        from   ad_locales 
        where  language = :language
        and    default_p = 't'
    
      </querytext>
   </fullquery>

</queryset>
