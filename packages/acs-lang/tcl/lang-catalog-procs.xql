<?xml version="1.0"?>
<queryset>

  <fullquery name="lang::catalog::import_from_all_files.all_enabled_not_loaded_packages">
    <querytext>
      select package_key
      from   apm_package_types
      where  exists (select 1 
                     from   apm_package_versions
                     where  installed_p = 't'
                     and    enabled_p = 't')
       and not exists (select 1
                       from lang_message_keys
                       where package_key = apm_package_types.package_key)
    </querytext>
  </fullquery>

  <fullquery name="lang::catalog::export_package_to_files.get_locales_for_package">
    <querytext>
        select distinct locale
        from lang_messages
        where package_key = :package_key
    </querytext>
  </fullquery>

  <fullquery name="lang::catalog::export_package_to_files.get_messages">
    <querytext>
        select message_key, message
        from lang_messages
        where package_key = :package_key
        and locale = :locale
    </querytext>
  </fullquery>

  <fullquery name="lang::catalog::translate.get_untranslated_messages">
    <querytext>
      select message_key,
             package_key,
             message 
      from   lang_messages lm1 
      where  locale = :default_locale
      and    not exists (select message_key, package_key
                         from   lang_messages lm2 
                         where  locale != :default_locale
                         and    lm1.message_key = lm2.message_key
                         and    lm1.package_key = lm2.package_key)
    </querytext>
  </fullquery>

</queryset>
