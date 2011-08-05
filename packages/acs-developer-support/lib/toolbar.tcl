
# TODO: Handle the case when developer-support is not mounted

set ip_address [ns_config ns/server/[ns_info server]/module/nssock address]

set show_p [ds_show_p]

if { $show_p } {
    set ds_url [ds_support_url]

    set base_url [ad_url]
    set num_comments [llength [ds_get_comments]]

    multirow create ds_buttons label title toggle_url state

    # multirow append ds_buttons COM \
        "Display comments inline" \
        [export_vars -base "${ds_url}comments-toggle" { { return_url [ad_return_url] } }] \
        [ad_decode [ds_comments_p]  1 "on" "off"]

    multirow append ds_buttons USR \
        "Toggle user switching" \
        [export_vars -base "${ds_url}set" { {field user} {enabled_p {[expr ![ds_user_switching_enabled_p]]}} {return_url [ad_return_url]} }] \
        [ad_decode [ds_user_switching_enabled_p] 1 "on" "off"] 

    multirow append ds_buttons DB \
        "Toggle DB data collection" \
        [export_vars -base "${ds_url}set" { {field db} {enabled_p {[expr ![ds_database_enabled_p]]}} {return_url [ad_return_url]} }] \
        [ad_decode [ds_database_enabled_p] 1 "on" "off"]

    multirow append ds_buttons PRO \
        "Toggle template profiling" \
        [export_vars -base "${ds_url}set" { {field prof} {enabled_p {[expr ![ds_profiling_enabled_p]]}} {return_url [ad_return_url]} }] \
        [ad_decode [ds_profiling_enabled_p] 1 "on" "off"]

    multirow append ds_buttons FRG \
        "Toggle caching page fragments" \
        [export_vars -base "${ds_url}set" { {field frag} {enabled_p {[expr ![ds_page_fragment_cache_enabled_p]]}} {return_url [ad_return_url]} }] \
        [ad_decode [ds_page_fragment_cache_enabled_p] 1 "on" "off"]

    multirow append ds_buttons TRN \
        "Toggle translation mode" \
        [export_vars -base "[ad_url]/acs-lang/admin/translator-mode-toggle" { { return_url [ad_return_url] } }] \
        [ad_decode [lang::util::translator_mode_p] 1 "on" "off"]

    multirow append ds_buttons ADP \
        "Toggle ADP reveal" \
        {javascript:void(d=document);void(el=d.getElementsByTagName('span'));for(i=0;i<el.length;i++){if(el[i].className=='developer-support-adp-file-on'){void(el[i].className='developer-support-adp-file-off')}else{if(el[i].className=='developer-support-adp-file-off'){void(el[i].className='developer-support-adp-file-on')}}};void(el=d.getElementsByTagName('div'));for(i=0;i<el.length;i++){if(el[i].className=='developer-support-adp-box-on'){void(el[i].className='developer-support-adp-box-off')}else{if(el[i].className=='developer-support-adp-box-off'){void(el[i].className='developer-support-adp-box-on')}};if(el[i].className=='developer-support-adp-output-on'){void(el[i].className='developer-support-adp-output-off')}else{if(el[i].className=='developer-support-adp-output-off'){void(el[i].className='developer-support-adp-output-on')}};}} \
        [ad_decode [ds_adp_reveal_enabled_p] 1 "on" "off"]

    multirow append ds_buttons FOT \
        "Toggle Footer display" \
        {javascript:void(d=document);void(el=d.getElementsByTagName('div'));for(i=0;i<el.length;i++){if(el[i].className=='developer-support-footer'){void(el[i].className='developer-support-footer-off')}else{if(el[i].className=='developer-support-footer-off'){void(el[i].className='developer-support-footer')}}};} \
        off


    set oacs_shell_url "${ds_url}shell"

    set auto_test_url [site_node::get_package_url -package_key acs-automated-testing]

    set request_info_url [export_vars -base "${ds_url}request-info" { { request {[ad_conn request]} } }]

    set page_ms [lc_numeric [ds_get_page_serve_time_ms]]

    set db_info [ds_get_db_command_info]

    set db_num_cmds [lindex $db_info 0]
    set db_num_ms [lc_numeric [lindex $db_info 1]]

    set flush_url [export_vars -base "[ad_url]/acs-admin/cache/flush-cache" { { suffix util_memoize } { return_url [ad_return_url] } }]

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


# Retrieve all CSS files loaded on this page
# Generate the <link > tag multirow
variable ::template::head::links

set css_list [list]
if {[array exists links]} {
    foreach name [array names links] {
        foreach {rel href type media title lang} $links($name) {
            if {$type eq "text/css"} {
                lappend css_list $href
            }
	}
    }
}

if {$css_list ne ""} {
    multirow append ds_buttons CSS \
        "Show CSS" \
        [export_vars -base "/ds/css-list" { css_list { return_url [ad_return_url] } }] \
	off
}

set rm_package_id [apm_package_id_from_key xotcl-request-monitor]
if {$rm_package_id > 0} {
    set rm_url "${base_url}[apm_package_url_from_id $rm_package_id]"
} else {
    set rm_url ""
}
