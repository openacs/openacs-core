ad_page_contract {
    Show message conflicts resulting from message catalog
    imports. Optionally filter by package and locale.

    @author Peter Marklund
} {
    locale:optional
    package_key:optional
}

foreach optional_var {locale package_key} {
    if { [info exists $optional_var] } {
        if { [empty_string_p [set $optional_var]] } {
            unset $optional_var
        }
    }
}

set page_title "I18N Message Conflicts"
set context [list $page_title]

list::create \
    -name messages \
    -multirow messages \
    -no_data "There are no conflicts" \
    -elements {
        package_key {
            label "Package"
        }
        message_key {
            label "Key"
        }
        locale {
            label "Locale"
        }
        message {
            label "Message"
            link_url_col edit_url
            display_eval {[string_truncate -len 50 -- $message]}
        }
        upgrade_status {
            label "Status"
        }
        accept {
            label ""
            display_template {
                Mark resolved
            }
            link_url_col accept_url
            link_html {title "Click to accept current state of message and consider conflict resolved."}
        }
    } -filters {
        locale {
            label "Locale"
            where_clause "locale = :locale"
            values {[db_list_of_lists locales {select distinct locale, locale from lang_messages where conflict_p = 't'}]}
        }
        package_key {
            label "Package"
            where_clause "package_key = :package_key"
            values {[db_list_of_lists packages {
                select pt.pretty_name, 
                       pt.package_key 
                from   apm_package_types pt 
                where  pt.package_key in (select m.package_key
                               from   lang_messages m
                               where    m.conflict_p = 't')
                order  by pretty_name
            }]}
        }

    }

db_multirow -unclobber -extend { edit_url accept_url } messages select_messages "
    select package_key,
           locale,
           message_key,
           message,
           deleted_p,
           upgrade_status
    from lang_messages
    where conflict_p = 't'
    [template::list::filter_where_clauses -and -name messages]
" {
    set edit_url [export_vars -base "edit-localized-message" { package_key locale message_key }]
    set accept_url [export_vars -base "message-conflict-resolve" { package_key locale message_key {return_url [ad_return_url]}}]
}
