ad_page_contract {

    Displays the localized message from the database for translation (displays
    an individual message)

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Christian Hvid
    @creation-date 30 October 2001
    @cvs-id $Id$

} {
    locale
    package_key
    message_key
    show:optional
    {usage_p "f"}
    {return_url {}}
}

# We rename to avoid conflict in queries
set current_locale $locale
set default_locale en_US

set locale_label [ad_locale_get_label $current_locale]
set default_locale_label [ad_locale_get_label $default_locale]

set page_title "Edit $package_key.$message_key"
set context [list [list "package-list?[export_vars { locale }]" $locale_label] \
                 [list "message-list?[export_vars { locale package_key show }]" $package_key] \
                 "$package_key.$message_key"]


# We let you create/delete messages keys if you're in the default locale
set create_p [string equal $current_locale $default_locale]

set description_edit_url "edit-description?[export_vars { locale package_key message_key show }]"

set usage_hide_url "[ad_conn url]?[export_vars { locale package_key message_key show return_url }]"
set usage_show_url "[ad_conn url]?[export_vars { locale package_key message_key show {usage_p 1} return_url }]"

set delete_url "message-delete?[export_vars { locale package_key message_key show {return_url {[ad_return_url]}} }]"


ad_form -name message -form {
    {locale:text(hidden),optional {value $current_locale}}
    {package_key:text(hidden),optional {value $package_key}}
    {message_key:text(hidden),optional {value $message_key}}
    {show:text(hidden),optional}
    {return_url:text(hidden),optional {value $return_url}}

    {message_key_pretty:text(inform)
        {label "Message Key"}
        {value "$package_key.$message_key"}
    }
    {description:text(inform)
        {label "Description"}
        {after_html {}}
    }
} 

if { ![string equal $default_locale $current_locale] } {
    ad_form -extend -name message -form {
        {original_message:text(inform)
            {label "$default_locale_label Message"}
        }
    }
}
    
ad_form -extend -name message -form {
    {message:text(textarea)
        {label "$locale_label Message"} 
        {html { rows 6 cols 40 }}
    }
    {comment:text(textarea),optional
        {label "Comment"}
        {html { rows 6 cols 40 }}
    }
    {submit:text(submit)
        {label "     Update     "}
    }
} -on_request {
    set original_message {}
    set description {}

    db_0or1row select_original_message {
        select lm.message as original_message,
               lmk.description
        from   lang_messages lm,
               lang_message_keys lmk
        where  lm.message_key = lmk.message_key
        and    lm.package_key = lmk.package_key
        and    lm.package_key = :package_key
        and    lm.message_key = :message_key
        and    lm.locale = :default_locale
    }

    db_0or1row select_translated_message {
        select message as message
        from   lang_messages
        where  package_key = :package_key
        and    message_key = :message_key
        and    locale = :current_locale
    }
    
    set original_message [ad_quotehtml $original_message]
    if { [exists_and_not_null message] } {
        set message $message
    }

    if { [empty_string_p $description] } {
        set description [subst {(<a href="$description_edit_url">add description</a>)}]
    } else {
        set description "[ad_text_to_html -- $description] [subst { (<a href="$description_edit_url">edit</a>)}]"
    }
} -on_submit {

    # Register message via acs-lang
    lang::message::register -comment $comment $locale $package_key $message_key $message

    if { [empty_string_p $return_url] } {
        set return_url "[ad_conn url]?[export_vars { locale package_key message_key show }]"
    }
    ad_returnredirect $return_url
    ad_script_abort
}

