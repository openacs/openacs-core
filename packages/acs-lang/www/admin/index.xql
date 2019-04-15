<?xml version="1.0"?>
<queryset>

  <fullquery name="count_locales">
    <querytext>

        select
            locales_summary.*,
            (select count(*) from ad_locales al where al.language = locales_summary.language) as num_locales_for_language
        from (
            select
                al.locale as locale,
                al.label as locale_label,
                language,
                default_p,
                enabled_p,
                case when num_messages is null          then 0 else num_messages end,
                case when num_translated is null        then 0 else num_translated end,
                case when num_untranslated is null      then 0 else num_untranslated end,
                case when num_deleted is null           then 0 else num_deleted end
            from (
                select locale,
                    count(*)                                                                    as num_messages,
                    count(message_is_not_null + messages_not_deleted)                           as num_translated,
                    count(message_is_null + default_message_not_deleted + message_not_deleted)  as num_untranslated,
                    count(any_message_deleted)                                                  as num_deleted
                from (
                    select
                        lm2.locale,
                        case when lm2.message is null                           then 1 end message_is_null,
                        case when lm2.message is not null                       then 1 end message_is_not_null,
                        case when lm1.deleted_p = 't' or lm2.deleted_p = 't'    then 1 end any_message_deleted,
                        case when lm1.deleted_p = 'f' and lm2.deleted_p = 'f'   then 1 end messages_not_deleted,
                        case when lm1.deleted_p = 'f'                           then 1 end default_message_not_deleted,
                        case when lm2.deleted_p = 'f' or lm2.deleted_p is null  then 1 end message_not_deleted
                    from
                        lang_messages lm1 left outer join
                        lang_messages lm2 on (
                            lm2.message_key = lm1.message_key
                            and lm2.package_key = lm1.package_key
                        )
                    where
                        lm1.locale = :default_locale
                ) locale_messages
                group by locale
            ) locale_summary right outer join
              ad_locales al on
                 al.locale = locale_summary.locale
            group by
                al.locale,
                num_messages,
                num_translated,
                num_untranslated,
                num_deleted
            order by
                locale_label
        ) locales_summary

    </querytext>
  </fullquery>

</queryset>
