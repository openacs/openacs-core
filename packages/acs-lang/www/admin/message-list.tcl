ad_page_contract {
    Displays messages for translation

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Lars Pind (lars@collaboraid.biz)

    @creation-date 26 October 2001
    @cvs-id $Id$
} {
    locale
    package_key
    {show "all"}
} -validate {
    show_valid -requires { show } {
        if { [lsearch { all deleted translated untranslated } $show] == -1 } {
            ad_complain "Show must be one of 'all', 'deleted', 'translated', or 'untranslated'."
        }
    }
}

# 'show' can be "all", "translated", "untranslated"

# We rename to avoid conflict in queries
set current_locale $locale
set default_locale en_US

set locale_label [lang::util::get_label $current_locale]
set default_locale_label [lang::util::get_label $default_locale]

set page_title $package_key
set context [list [list [export_vars -base package-list { locale }] $locale_label] $page_title]

set site_wide_admin_p [acs_user::site_wide_admin_p]

set export_messages_url [export_vars -base "export-messages" { package_key locale { return_url {[ad_return_url]} } }]
set import_messages_url [export_vars -base "import-messages" { package_key locale { return_url {[ad_return_url]} } }]

# We let you create new messages keys if you're in the default locale
set create_p [string equal $current_locale $default_locale]

set new_message_url "localized-message-new?[export_vars { locale package_key }]"



#####
#
# Counting messages
#
#####

db_1row counts {
    select (select count(*) 
            from lang_messages 
            where package_key = :package_key 
            and locale = :locale
            and deleted_p = 'f') as num_translated,
           (select count(*) 
            from lang_messages 
            where package_key = :package_key 
            and locale = :default_locale 
            and deleted_p = 'f') as num_messages,
            (select count(*) 
             from lang_messages 
             where package_key = :package_key 
             and locale = :default_locale 
             and deleted_p = 't') as num_deleted
    from dual
}
set num_untranslated [expr {$num_messages - $num_translated}]
set num_messages_pretty [lc_numeric [expr {$num_messages + $num_deleted}]]
set num_translated_pretty [lc_numeric $num_translated]
set num_untranslated_pretty [lc_numeric $num_untranslated]
set num_deleted_pretty [lc_numeric $num_deleted]


#####
#
# Handle filtering
#
#####

# LARS: The reason I implemented this overly complex way of doing it is that I was just about to 
# merge this page with messages-search ...

set where_clauses [list]

switch -exact $show {
    all {
        lappend where_clauses {lm1.deleted_p = 'f'}
    }
    translated {
        lappend where_clauses {lm2.message is not null}
        lappend where_clauses {(lm2.deleted_p = 'f' or lm2.deleted_p is null)}
        lappend where_clauses {lm1.deleted_p = 'f'}
    }
    untranslated {
        lappend where_clauses {(lm2.deleted_p = 'f' or lm2.deleted_p is null)}
        lappend where_clauses {lm1.deleted_p = 'f'}
        lappend where_clauses {lm2.message is null}
    }
    deleted {
        lappend where_clauses {lm1.deleted_p = 't'}
    }
}

if { [llength $where_clauses] == 0 } {
    set where_clause {}
} else {
    set where_clause "and [join $where_clauses "\n and "]"
}

db_multirow -extend { 
    edit_url
    delete_url
    message_key_pretty
} messages select_messages {} {
    set edit_url "edit-localized-message?[export_vars { locale package_key message_key show {return_url {[ad_return_url]}} }]"
    set delete_url "message-delete?[export_vars { locale package_key message_key show {return_url {[ad_return_url]}} }]"
    set message_key_pretty "$package_key.$message_key"
}

# TODO: PG
# TODO: Create message


set batch_edit_url "batch-editor?[export_vars { locale package_key show }]"


#####
#
# Slider for 'show' options
#
#####

multirow create show_opts value label count

multirow append show_opts "all" "All" $num_messages_pretty
multirow append show_opts "translated" "Translated" $num_translated_pretty
multirow append show_opts "untranslated" "Untranslated" $num_untranslated_pretty
multirow append show_opts "deleted" "Deleted" $num_deleted_pretty

multirow extend show_opts url selected_p 

multirow foreach show_opts {
    set selected_p [string equal $show $value]
    if {$value eq "all"} {
        set url "[ad_conn url]?[export_vars { locale package_key }]"
    } else { 
        set url "[ad_conn url]?[export_vars { locale package_key {show $value} }]"
    }
}


# Locale switch
set languages [lang::system::get_locale_options]

ad_form -name locale_form -action [ad_conn url] -export { tree_id category_id } -form {
    {locale:text(select) {label "Language"} {value $locale} {options $languages}}
}

set form_vars [export_ns_set_vars form {locale form:mode form:id __confirmed_p __refreshing_p formbutton:ok} [ad_conn form]]
