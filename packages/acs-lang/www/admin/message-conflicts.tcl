ad_page_contract {
    Show message conflicts resulting from message catalog
    imports. Optionally filter by package and locale.

    @author Peter Marklund
} {
    locale:optional
    package_key:optional
    upgrade_status:optional
}

foreach optional_var {locale package_key} {
    if { [info exists $optional_var] } {
        if { [set $optional_var] eq "" } {
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
    -sub_class narrow \
    -elements {
        edit {
            label ""
            display_template {
                <img src="/shared/images/Edit16.gif" alt="edit" width="16" height="16">
            }
            link_url_col edit_url
        }
        package_key {
            label "Package"
        }
        message_key {
            label "Key"
        }
        locale {
            label "Locale"
        }
        accept {
            label ""
            display_template "Accept new"
            link_url_col accept_url
        }
        message {
            label "New Message"
            display_col message_truncated
        }
        old_message {
            label "Old Message"
            display_col old_message_truncated
        }
        revert {
            label ""
            display_template "Revert to old"
            link_url_col revert_url
        }
        upgrade_status {
            label "Status"
        }
    } -filters {
        locale {
            label "Locale"
            where_clause "lm.locale = :locale"
            values {[db_list_of_lists locales {select distinct locale, locale from lang_messages where conflict_p = 't'}]}
        }
        package_key {
            label "Package"
            where_clause "lm.package_key = :package_key"
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
        upgrade_status {
            label "Status"
            where_clause "lm.upgrade_status = :upgrade_status"
            values {[db_list_of_lists upgrade_statuses {
                select distinct upgrade_status, upgrade_status
                from lang_messages
                where conflict_p = 't'
            }]}
        }
    }

db_multirow -unclobber -extend { edit_url accept_url revert_url message_truncated old_message_truncated } messages select_messages "
    select lm.package_key,
           lm.locale,
           lm.message_key,
           lm.message,
           lma.old_message,
           lm.deleted_p,
           lm.upgrade_status
    from lang_messages lm,
         lang_messages_audit lma
    where lm.conflict_p = 't'
      and lm.package_key = lma.package_key
      and lm.message_key = lma.message_key
      and lm.locale = lma.locale
      and lma.audit_id = (select max(audit_id)
                          from lang_messages_audit lma2
                          where lma2.package_key = lm.package_key
                            and lma2.message_key = lm.message_key
                            and lma2.locale = lm.locale
                          )
    [template::list::filter_where_clauses -and -name messages]
    order by lm.package_key, lm.message_key
" {
    set edit_url [export_vars -base "edit-localized-message" { package_key locale message_key }]

    set accept_url [export_vars -base "message-conflict-resolve" { package_key locale message_key {return_url [ad_return_url]}}]
    set revert_url [export_vars -base "message-conflict-revert" { package_key locale message_key {return_url [ad_return_url]}}]

    set message_truncated [string_truncate -len 150 -- $message]
    set old_message_truncated [string_truncate -len 150 -- $old_message]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
