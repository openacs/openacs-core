<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

   <fullquery name="lang::util::nls_language_from_language.nls_language_from_language">      
      <querytext>
      
        select nls_language
        from   ad_locales 
        where  lower(trim(language)) = lower(:language)
          and  enabled_p = 't'
          and  rownum = 1
    
      </querytext>
   </fullquery>
 
</queryset>

