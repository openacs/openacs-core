ad_page_contract {
    A page displaying recent editing of translations.
    
    @author Peter Marklund
} {
    {locale "de_DE"}
    {number_of_edits 400}
    {email_exclude ""}
}

set list_of_locales [db_list_of_lists locale_loop { select label, locale from enabled_locales order by label }]

set admin_email peter@collaboraid.biz

ad_form \
    -name locale \
    -method GET \
    -form {
        {locale:text(select)
            {label "Locale"}
            {options $list_of_locales}
        }
        {number_of_edits:text,optional
            {label "Number of edits"}
            {value $number_of_edits}
        }
        {email_exclude:text,optional
            {label "Email pattern to exclude"}
            {value $email_exclude}
        }
    }    

set email_clause [ad_decode $email_exclude "" "" "and cu.email not like '%$email_exclude%'"]

db_multirow -extend { key_url } history german_edit_history "
    select q.* from (select lma.overwrite_date, 
                            lma.old_message,
                            lma.message_key,
                            lma.package_key,
                            lma.locale,
                            cu.first_names || cu.last_name as user_name
                     from lang_messages_audit lma,
                          cc_users cu
                     where cu.user_id = lma.overwrite_user
                       and lma.locale = :locale
                       $email_clause
                     order by lma.overwrite_date desc) q 
    where rownum < :number_of_edits
" {
    set key_url [export_vars -base /acs-lang/admin/edit-localized-message {package_key message_key locale}]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
