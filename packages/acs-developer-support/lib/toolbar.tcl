
# TODO: Handle the case when developer-support is not mounted

# TODO: Move the "Toggle translator mode" to developer-support (might as well lump them all together)



set show_p [ds_show_p]

if { $show_p } {
    set ds_url [ds_support_url]

    set comments_p [ds_comments_p]
    set comments_toggle_url [export_vars -base "${ds_url}comments-toggle" { { return_url [ad_return_url] } }]
    set comments_on [ad_decode $comments_p 1 "on" "off"]

    set user_switching_p [ds_user_switching_enabled_p]
    set user_switching_toggle_url [export_vars -base "${ds_url}set-user-switching-enabled" { { enabled_p {[expr !$user_switching_p]} } { return_url [ad_return_url] } }]
    set user_switching_on [ad_decode $user_switching_p 1 "on" "off"]

    set db_p [ds_database_enabled_p]
    set db_toggle_url [export_vars -base "${ds_url}set-database-enabled" { { enabled_p {[expr !$db_p]} } { return_url [ad_return_url] } }]
    set db_on [ad_decode $db_p 1 "on" "off"]

    set translator_p [lang::util::translator_mode_p]
    set translator_toggle_url [export_vars -base "/acs-lang/admin/translator-mode-toggle" { { return_url [ad_return_url] } }]
    set translator_on [ad_decode $translator_p 1 "on" "off"]

    set oacs_shell_url "${ds_url}shell"

    set request_info_url [export_vars -base "${ds_url}request-info" { { request {[ad_conn request]} } }]

    set page_ms [lc_numeric [ds_get_page_serve_time_ms]]

    set db_info [ds_get_db_command_info]

    set db_num_cmds [lindex $db_info 0]
    set db_num_ms [lc_numeric [lindex $db_info 1]]

    if { [empty_string_p $page_ms] } {
        set request_info_label "Request info"
    } else {
        if { [empty_string_p $db_num_ms] } {
            set request_info_label "$page_ms ms"
        } else {
            set request_info_label "${page_ms} ms/${db_num_cmds} db/${db_num_ms} ms"
        }
    }
}

