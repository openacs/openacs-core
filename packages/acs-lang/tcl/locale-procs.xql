<?xml version="1.0"?>
<queryset>

<fullquery name="ad_locale_charset_for_locale.charset_for_locale">      
      <querytext>
      
	select mime_charset
	  from ad_locales 
	 where locale = :locale
    
      </querytext>
</fullquery>

 
<fullquery name="ad_locale_locale_from_lang.default_locale">      
      <querytext>
      
	select locale 
	  from ad_locales 
	 where language = :language
               and default_p = 't'
    
      </querytext>
</fullquery>

 
<fullquery name="ad_locale_locale_from_lang.default_locale">      
      <querytext>
      
	select locale 
	  from ad_locales 
	 where language = :language
               and default_p = 't'
    
      </querytext>
</fullquery>

 
</queryset>
