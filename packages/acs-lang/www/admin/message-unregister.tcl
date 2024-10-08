ad_page_contract {

    Undelete a message

    @author Héctor Romojaro <hector.romojaro@gmail.com>

    @creation-date 2019-04-24
    @cvs-id $Id $

} {
    locale:word
    package_key:token
    message_key
    show:optional
    {confirm_p:boolean,optional,notnull 0}
}


# We rename to avoid conflict in queries
set current_locale $locale
set default_locale en_US

set locale_label [lang::util::get_label $current_locale]
set default_locale_label [lang::util::get_label $default_locale]

set page_title "Delete Message Permanently (Unregister)"
set context [list [list [export_vars -base package-list { locale }] $locale_label] \
                 [list [export_vars -base message-list { locale package_key show }] $package_key] \
                 $page_title]

set form_export_vars [export_vars -form { locale package_key message_key show {confirm_p 1} }]


if { $confirm_p } {
    lang::message::unregister $package_key $message_key

    ad_returnredirect [export_vars -base message-list { locale package_key show }]
    ad_script_abort
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
