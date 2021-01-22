
# TODO: Handle the case when developer-support is not mounted
set ip_address [ns_info address]:[ns_config [ns_driversection] port]


set show_p [ds_show_p]

if { $show_p } {

    set ds_url [ds_support_url]
    set num_comments [llength [ds_get_comments]]

    multirow create ds_buttons label title toggle_url state

    # multirow append ds_buttons COM \
        "Display comments inline" \
        [export_vars -base "${ds_url}comments-toggle" { { return_url [ad_return_url]} }] \
        [ad_decode [ds_comments_p]  1 "on" "off"]

    multirow append ds_buttons USR \
        "Toggle user switching" \
        [export_vars -base "${ds_url}set" { {field user} {enabled_p {[expr {![ds_user_switching_enabled_p]}]}} {return_url [ad_return_url]} }] \
        [ad_decode [ds_user_switching_enabled_p] 1 "on" "off"] 

    multirow append ds_buttons DB \
        "Toggle DB data collection" \
        [export_vars -base "${ds_url}set" { {field db} {enabled_p {[expr {![ds_database_enabled_p]}]}} {return_url [ad_return_url]} }] \
        [ad_decode [ds_database_enabled_p] 1 "on" "off"]

    multirow append ds_buttons PRO \
        "Toggle template profiling" \
        [export_vars -base "${ds_url}set" { {field prof} {enabled_p {[expr {![ds_profiling_enabled_p]}]}} {return_url [ad_return_url]} }] \
        [ad_decode [ds_profiling_enabled_p] 1 "on" "off"]

    multirow append ds_buttons FRG \
        "Toggle caching page fragments" \
        [export_vars -base "${ds_url}set" { {field frag} {enabled_p {[expr {![ds_page_fragment_cache_enabled_p]}]}} {return_url [ad_return_url]} }] \
        [ad_decode [ds_page_fragment_cache_enabled_p] 1 "on" "off"]

    multirow append ds_buttons TRN \
        "Toggle translation mode" \
        [export_vars -base "/acs-lang/admin/translator-mode-toggle" { { return_url [ad_return_url]}}] \
        [ad_decode [lang::util::translator_mode_p] 1 "on" "off"]

    multirow append ds_buttons ADP \
        "Toggle ADP reveal" \
        \# \
        [ad_decode [ds_adp_reveal_enabled_p] 1 "on" "off"]

    template::add_body_script -script {
        document.getElementById('ACS_DS_ADP').addEventListener('click', function (event) {
            var el=document.getElementsByTagName('span');
            event.preventDefault();
            for(i=0;i<el.length;i++){if(el[i].className=='developer-support-adp-file-on'){void(el[i].className='developer-support-adp-file-off')}else{if(el[i].className=='developer-support-adp-file-off'){void(el[i].className='developer-support-adp-file-on')}}};void(el=document.getElementsByTagName('div'));for(i=0;i<el.length;i++){if(el[i].className=='developer-support-adp-box-on'){void(el[i].className='developer-support-adp-box-off')}else{if(el[i].className=='developer-support-adp-box-off'){void(el[i].className='developer-support-adp-box-on')}};if(el[i].className=='developer-support-adp-output-on'){void(el[i].className='developer-support-adp-output-off')}else{if(el[i].className=='developer-support-adp-output-off'){void(el[i].className='developer-support-adp-output-on')}};}
        });
    }

    multirow append ds_buttons FOT \
        "Toggle Footer display" \
        \# \
        off

    template::add_body_script -script {
        document.getElementById('ACS_DS_FOT').addEventListener('click', function (event) {
            var el=document.getElementsByTagName('div');
            event.preventDefault();
            for(i=0;i<el.length;i++){if(el[i].className=='developer-support-footer'){void(el[i].className='developer-support-footer-off')}else{if(el[i].className=='developer-support-footer-off'){void(el[i].className='developer-support-footer')}}};
        });
    }

    set oacs_shell_url "${ds_url}shell"
    set auto_test_url [site_node::get_package_url -package_key acs-automated-testing]
    set request_info_url [export_vars -base "${ds_url}request-info" { { request {[ad_conn request]} } }]
    set page_ms [lc_numeric [ds_get_page_serve_time_ms]]
    
    lassign [ds_get_db_command_info] db_num_cmds db_num_ms
    if {$db_num_ms ne ""} {
        set db_num_ms [lc_numeric [format %.1f $db_num_ms]]
    }

    set flush_url [export_vars -base "/acs-admin/cache/flush-cache" {
        { suffix util_memoize }
        { return_url [ad_return_url]}
    }]

    if { $page_ms eq "" } {
        set request_info_label "Request info"
    } else {
        if { $db_num_ms eq "" } {
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

#get url for xotcl-core and xotcl-request-monitor
foreach {package_name package_url} {xotcl-core xocore_url xotcl-request-monitor rm_url} {
    set package_id [apm_package_id_from_key $package_name]
    if {$package_id > 0} {
        set $package_url [apm_package_url_from_id $package_id]
    } else {
        set $package_url ""
    }
}

set this_side_node [site_node_id [ad_conn url]]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
