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
    unregister_p:optional
    {subm_delete {}}
    {subm_unreg {}}
    {return_url {}}
}


# We rename to avoid conflict in queries
set current_locale $locale
set default_locale en_US

set locale_label [lang::util::get_label $current_locale]
set default_locale_label [lang::util::get_label $default_locale]

set page_title "Delete Message"
set context [list [list "package-list?[export_vars { locale }]" $locale_label] \
                 [list "message-list?[export_vars { locale package_key show }]" $package_key] \
                 $page_title]

# We let you unregister the messages key if you're in the default locale
set unregister_p [string equal $current_locale $default_locale]
set form_export_vars [export_vars -form { locale package_key message_key show {confirm_p 1} unregister_p return_url}]

if { [exists_and_not_null confirm_p] && [template::util::is_true $confirm_p] } {
    # check if we delete or unregister
    
    if {[string length $subm_delete]} {
	lang::message::delete \
	    -package_key $package_key \
	    -message_key $message_key \
	    -locale $locale
    }

    if {[string length $subm_unreg]} {
	lang::message::unregister \
	     $package_key \
	     $message_key 
    }
    
    if {[string length $return_url]} {
        ad_returnredirect $return_url
    } else {
        ad_returnredirect "message-list?[export_vars { locale package_key show }]"
    }
    ad_script_abort
}
