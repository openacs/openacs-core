<?xml version="1.0"?>
<queryset>

  <fullquery name="lang::catalog::load_all.all_enabled_packages">
    <querytext>
      select package_key
      from   apm_package_types
      where  exists (select 1 
                     from   apm_package_versions
                     where  installed_p = 't'
                     and    enabled_p = 't')
    </querytext>
  </fullquery>

  <fullquery name="lang::catalog::translate.get_untranslated_messages">
    <querytext>
      select key,
             message 
      from   lang_messages lm1 
      where  locale = :default_locale
      and    not exists (select 1 
                         from   lang_messages lm2 
                         where  locale != :default_locale
                         and    lm1.key = lm2.key)
    </querytext>
  </fullquery>

</queryset>
