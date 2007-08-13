ad_page_contract {
    Displays packages that contain messages.

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Lars Pind (lars@collaboraid.biz)

    @creation-date 26 October 2001
    @cvs-id $Id$
} {
    locale
} -properties {
    locale_label
    page_title
    context
    current_locale
    default_locale
    packages:multirow
    search_form
}

# We rename to avoid conflict in queries
set current_locale $locale
set default_locale en_US

set locale_label [lang::util::get_label $current_locale]
set default_locale_label [lang::util::get_label $default_locale]

set page_title $locale_label
set context [list $page_title]

set locale_enabled_p [expr [lsearch [lang::system::get_locales] $current_locale] != -1]
set site_wide_admin_p [acs_user::site_wide_admin_p]

set import_all_url [export_vars -base import-messages { { locale $current_locale } {return_url {[ad_return_url]}} }]
set export_all_url [export_vars -base export-messages { { locale $current_locale } {return_url {[ad_return_url]}} }]

set keeplocal_p [parameter::get -parameter KeepLocalTranslations -default ""]
##qst::Debug "keeplocal_p=$keeplocal_p" ==1==
set import_all_url [export_vars -base "import-messages" { keeplocal_p {locale $current_locale} {return_url {[ad_return_url]}} }]

if {[string length $keeplocal_p]} {
    # we have the parameter, turn to opposite for the special url
    if {[string is true $keeplocal_p]} {
        set keeplocal_p 0
        set import_all_normal_text "Keep local changes"
        set import_all_special_text "Discard local changes"
    } else {
        set keeplocal_p 1
        set import_all_normal_text "Discard local changes"
        set import_all_special_text "Keep local changes"
    }
    set import_all_special_url [export_vars -base "import-messages" { keeplocal_p {locale $current_locale} {return_url {[ad_return_url]}} }]
} else {
    set import_all_special_url {}
}


#####
#
# Package/message list
#
#####

db_multirow -extend { 
    num_messages_pretty
    num_translated_pretty
    num_untranslated
    num_untranslated_pretty
    batch_edit_url
    view_messages_url
    view_translated_url
    view_untranslated_url
} packages select_packages {
    select q.*,
           (select count(*) 
            from   lang_messages lm 
            where  lm.package_key = q.package_key
            and    lm.locale = :current_locale) as num_translated
    from   (select lmk.package_key,
                   count(message_key) as num_messages
            from   lang_message_keys lmk
            group  by package_key) q
    order  by package_key
} {
    set num_untranslated [expr {$num_messages - $num_translated}]

    set num_messages_pretty [lc_numeric $num_messages]
    set num_translated_pretty [lc_numeric $num_translated]
    set num_untranslated_pretty [lc_numeric $num_untranslated]

    set batch_edit_url "batch-editor?[export_vars { locale package_key }]"
    set view_messages_url "message-list?[export_vars { locale package_key }]"
    set view_translated_url "message-list?[export_vars { locale package_key { show "translated" } }]"
    set view_untranslated_url "message-list?[export_vars { locale package_key { show "untranslated" } }]"
}






#####
#
# Search form
#
#####

set search_locales [list \
                        [list "Current locale - [lang::util::get_label $current_locale]" $current_locale] \
                        [list "Master locale - [lang::util::get_label $default_locale]" $default_locale]]

ad_form -name search -action message-search -form {
    {locale:text(hidden) {value $locale}}
}

if { $default_locale ne $current_locale } {
    ad_form -extend -name search -form {
        {search_locale:text(select)
            {options $search_locales}
            {label "Search locale"}
        }
    }
} else {
    ad_form -extend -name search -form {
        {search_locale:text(hidden)
            {value $current_locale}
        }
    }
}

ad_form -extend -name search -form {
    {q:text 
        {label "Search for"}
    }
}

