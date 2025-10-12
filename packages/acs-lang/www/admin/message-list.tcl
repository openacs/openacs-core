ad_page_contract {
    Displays messages for translation

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Lars Pind (lars@collaboraid.biz)

    @creation-date 26 October 2001
    @cvs-id $Id$
} {
    locale:word
    package_key:token
    {show "all"}
} -validate {
    show_valid -requires { show } {
        if {$show ni { all deleted translated untranslated }} {
            ad_complain "Show must be one of 'all', 'deleted', 'translated', or 'untranslated'."
        }
    }
}

# SWA?
set site_wide_admin_p [acs_user::site_wide_admin_p]

# We rename to avoid conflict in queries
set current_locale $locale
set current_locale_label [lang::util::get_label $current_locale]
set default_locale en_US
set default_locale_label [lang::util::get_label $default_locale]
set default_locale_p [string equal $current_locale $default_locale]

# We let you create new messages keys if you're in the default locale
set create_p $default_locale_p

# Locale switch
set languages [lang::system::get_locale_options]
ad_form -name locale_form -action [ad_conn url] -export { tree_id category_id } -form {
    {locale:text(select) {label "Language"} {value $locale} {options $languages}}
}
set form_vars [export_vars -form -entire_form -exclude {locale form\\:mode form\\:id __confirmed_p __refreshing_p formbutton\\:ok}]

# Title and context
set page_title $package_key
set context [list [list [export_vars -base package-list { locale }] $current_locale_label] $page_title]

# Export/import/batch edit/new message URLs
set export_messages_url [export_vars -base export-messages { package_key locale { return_url {[ad_return_url]} } }]
set import_messages_url [export_vars -base import-messages { package_key locale { return_url {[ad_return_url]} } }]
set new_message_url     [export_vars -base localized-message-new { locale package_key }]
set batch_edit_url      [export_vars -base batch-editor { locale package_key show }]

# Number of messages (all, translated, untranslated and deleted) for the slider
if { $default_locale_p } {
    db_1row count_locale_default {}
    set multirow select_messages_default
} else {
    db_1row count_locale {}
    set multirow select_messages
}

# Slider for 'show' options
multirow create show_opts value label count
multirow append show_opts "all"             "All"           [lc_numeric $num_messages]
multirow append show_opts "translated"      "Translated"    [lc_numeric $num_translated]
multirow append show_opts "untranslated"    "Untranslated"  [lc_numeric $num_untranslated]
multirow append show_opts "deleted"         "Deleted"       [lc_numeric $num_deleted]
multirow extend show_opts url selected_p
multirow foreach show_opts {
    set selected_p [string equal $show $value]
    set url [export_vars -base [ad_conn url] { locale package_key {show $value} }]
}

# Handle filtering
set where_clause_default {}
set where_clause {}
switch -exact $show {
    translated {
        set where_clause_default {and lm.message is not null and lm.deleted_p = 'f'}
        set where_clause         {and lm2.message is not null and lm1.deleted_p = 'f' and lm2.deleted_p = 'f'}
    }
    untranslated {
        set where_clause_default {and lm.message is null and lm.deleted_p = 'f'}
        set where_clause         {and lm2.message is null and lm1.deleted_p = 'f' and (lm2.deleted_p = 'f' or lm2.deleted_p is null)}
    }
    deleted {
        set where_clause_default {and deleted_p = 't'}
        set where_clause         {and (lm1.deleted_p = 't' or lm2.deleted_p = 't')}
    }
}

set return_url [ad_return_url]

# Get the messages
db_multirow -extend {
    edit_url
    delete_url
    undelete_url
    message_key_pretty
} messages $multirow {} {
    set edit_url        [export_vars -base edit-localized-message { locale package_key message_key show return_url }]
    set message_key_pretty "$package_key.$message_key"
    if { $default_locale_p || $translated_message ne "" } {
        if { $translation_deleted_p } {
            set undelete_url [export_vars -base message-undelete { locale package_key message_key show return_url }]
        } else {
            set delete_url   [export_vars -base message-delete { locale package_key message_key show return_url }]
        }
    }
}

set actions [list]
if {$create_p} {
    lappend actions \
        "Create new message" $new_message_url "Create new message"
}
if { [template::multirow size messages] > 0 } {
    lappend actions \
        "Batch edit these messages" $batch_edit_url "Batch edit these messages"
    if { $site_wide_admin_p } {
        lappend actions \
            "Import messages for this package and locale from catalog files" \
            $import_messages_url \
            "Import messages for this package and locale from catalog files" \
            \
            "Export messages for this package and locale to catalog files" \
            $export_messages_url \
            "Export messages for this package and locale to catalog files"
    }
}

set elements {
    edit {
        label {}
        link_url_col edit_url
        link_html {title "Edit or comment on translation"}
        display_template {<adp:icon name="edit" title="Edit or comment on translation">}
    }
    message_key {
        label "Message Key"
        link_url_col edit_url
        link_html {title "Edit or comment on translation"}
        display_col message_key_pretty
    }
    default_message {
        label "$default_locale_label Message"
        display_template {
            <if @messages.deleted_p;literal@ true>
              <span style="color: red; font-style: italic;">DELETED</span> (@messages.default_message;literal@)
            </if>
            <else>
              @messages.default_message;literal@
            </else>
        }
    }
}

if { !$default_locale_p } {
    append elements {
        translated_message {
            label "$current_locale_label Message"
            display_template {
                <if @messages.translation_deleted_p;literal@ true>
                  <span style="color: red; font-style: italic;">DELETED</span> (@messages.translated_message;literal@)
                </if>
                <else>
                  <if @messages.translated_message@ not nil>@messages.translated_message;literal@</if>
                  <else><span style="color: gray; font-style: italic;">Not translated</span></else>
                </else>
            }
        }
    }
}

append elements {
    delete {
        label {}
        display_template {
            <if @messages.undelete_url@ not nil>
               <a href="@messages.undelete_url@" title="Undelete this message">
                 <img src="/shared/images/Undelete16.gif" alt="undelete" width="16" height="16">
               </a>
            </if>
            <if @messages.delete_url@ not nil>
              <a href="@messages.delete_url@" title="Delete this message">
                <adp:icon name="trash" title="Delete this message">
              </a>
            </if>
        }
    }
}

template::list::create \
    -name messages \
    -multirow messages \
    -actions $actions \
    -elements $elements \
    -no_data {No messages}


# TODO: Create message

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
