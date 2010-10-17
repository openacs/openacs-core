<?xml version="1.0"?>

<queryset>

  <fullquery name="select_countries">
    <querytext>
      select default_name, iso
      from countries 
      order by default_name
    </querytext>
  </fullquery>

  <fullquery name="select_languages">
    <querytext>
      select label, coalesce(iso_639_1, iso_639_2) 
      from language_639_2_codes 
      order by label
    </querytext>
  </fullquery>

  <fullquery name="select_default">
    <querytext>
      select count(*) 
      from ad_locales 
      where language = :language and default_p = 't'
    </querytext>
  </fullquery>

  <fullquery name="insert_locale">
    <querytext>
      insert into ad_locales (
        locale, language, country, variant, label, nls_language,
        nls_territory, nls_charset, mime_charset, default_p, enabled_p
      ) values (
        :locale, :language, :country, NULL, :label, :nls_language,
        :nls_territory, :nls_charset, :mime_charset, :default_p, 'f'
      )
    </querytext>
  </fullquery>

</queryset>
