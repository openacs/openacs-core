ad_page_contract {

    Delete a message

    @author Lars Pind (lars@collaboraid.biz)

    @creation-date 2003-08-15
    @cvs-id $Id$

} {
    locale
    package_key
    message_key
    show:optional
    confirm_p:optional
}


# We rename to avoid conflict in queries
set current_locale $locale
set default_locale en_US

set locale_label [ad_locale_get_label $current_locale]
set default_locale_label [ad_locale_get_label $default_locale]

set page_title "Delete Message"
set context [list [list "package-list?[export_vars { locale }]" $locale_label] \
                 [list "message-list?[export_vars { locale package_key show }]" $package_key] \
                 $page_title]


# We check that this request is coming for the system wide default
# locale. If not, we can't allow the creation of a new localized 
# message.

if { ![string equal $current_locale $default_locale] } {
    ad_return_error "Can only create messages in the default locale" "Can only create messages in the default locale"
    ad_script_abort
}


set form_export_vars [export_vars -form { locale package_key message_key show {confirm_p 1} }]


if { [exists_and_not_null confirm_p] && [template::util::is_true $confirm_p] } {

    db_transaction {

        db_dml delete_messages { delete from lang_messages where package_key = :package_key and message_key = :message_key }

        db_dml delete_audit { delete from lang_messages_audit where package_key = :package_key and message_key = :message_key  }

        db_dml delete_message_key { delete from lang_message_keys where package_key = :package_key and message_key = :message_key  }

    }

    ad_returnredirect "message-list?[export_vars { locale package_key show }]"
    ad_script_abort
}
