<?xml version="1.0"?>
<queryset>

   <fullquery name="lang::util::charset_for_locale.charset_for_locale">      
      <querytext>
      
        select mime_charset
        from   ad_locales 
        where  locale = :locale
    
      </querytext>
   </fullquery>

   <fullquery name="lang::util::default_locale_from_lang_not_cached.default_locale_from_lang">
      <querytext>
        select locale
        from   ad_locales
        where  language = '[db_quote $language]'
        and    enabled_p = 't'
        and    (default_p = 't' or
                (select count(*)
                from ad_locales
                where language = '[db_quote $language]') = 1
                    )
      </querytext>
   </fullquery>

   <fullquery name="lang::util::get_label.select">
      <querytext>
        select label 
          from ad_locales
         where lower(locale) = lower(:locale)
      </querytext>
   </fullquery>

   <fullquery name="lang::util::get_locale_options_not_cached.select_locales">
      <querytext>
       select label, locale
        from   ad_locales
	order by label
      </querytext>
   </fullquery>

  <fullquery name="lang::util::iso6392_from_language.get_iso2_code_from_iso1">      
    <querytext>
      
      select iso_639_2
      from   language_639_2_codes
      where  iso_639_1 = :language
    
    </querytext>
  </fullquery>
 
  <fullquery name="lang::util::iso6392_from_language.get_iso2_code_from_iso2">      
    <querytext>
      
      select iso_639_2
      from   language_639_2_codes
      where  iso_639_2 = :language
    
    </querytext>
  </fullquery>
 
  <fullquery name="lang::util::language_label.get_label_from_iso1">      
    <querytext>
      
      select label
      from   language_639_2_codes
      where  iso_639_1 = :language
    
    </querytext>
  </fullquery>
 
  <fullquery name="lang::util::language_label.get_label_from_iso2">      
    <querytext>
      
      select label
      from   language_639_2_codes
      where  iso_639_2 = :language
    
    </querytext>
  </fullquery>
 
</queryset>
