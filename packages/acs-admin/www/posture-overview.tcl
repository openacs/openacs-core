ad_page_contract {
    Security and Privacy Posture Overview

    @author Gustaf Neumann
    @creation-date 2024-07-20
} {
    {current_location ""}
}

set doc(title) "Security and Privacy Posture Overview"
set context [list $doc(title)]

set ns_info_config [ns_info config]
set system_locale [lang::system::locale]
set installed_locales [lang::system::get_locales]

set packages [apm_enabled_packages]
set number_of_packages [llength $packages]
set version_numbers_on_result_pages [ns_config ns/server/[ns_info server] noticedetail]

if {$current_location eq ""} {
    set current_location [ns_conn location]
}
set behind_reverse_proxy_p [ad_conn behind_proxy_p]
set behind_secure_reverse_proxy_p [ad_conn behind_secure_proxy_p]

set secure_connection_p [expr {$behind_secure_reverse_proxy_p || (!$behind_reverse_proxy_p && [ns_conn proto] eq "https")}]
set reverse_proxy_setup [ad_decode $behind_reverse_proxy_p-$behind_secure_reverse_proxy_p \
                             0-0 "This server is not configured to be running behind a reverse proxy server" \
                             1-0 "This server is configured to be running behind a reverse proxy server" \
                             1-1 "This server is running behind a reverse proxy server over HTTPs" \
                            ]


set custom_error_pages_set [ns_configsection ns/server/[ns_info server]/redirects]
set custom_error_pages [expr {$custom_error_pages_set ne ""
                              ? [ns_set array $custom_error_pages_set]
                              : "It is recommended to define custom error pages for the most common HTTP errors"}]

if {[ns_info version] < 5.0} {
    set custom_server_reply_pages [string cat "You running a NaviServer < 5.0. " \
                                    "With new versions, one can define custom pages for all server replies " \
                                    "by configuring the parameter 'noticeadp' in the server configuration file."]
} else {
    set custom_server_reply_adp [ns_config ns/server/[ns_info server] noticeadp]
    if {$custom_server_reply_adp eq ""} {
        set custom_server_reply_pages "'ns/server/[ns_info server] noticeadp' is not configured"
    } else {
        if {![string match "/*" $custom_server_reply_adp]} {
            set custom_server_reply_adp [ns_info home]/conf/$custom_server_reply_adp
        }
        set custom_server_reply_pages "Using ADP file <i>$custom_server_reply_adp</i>"
    }
    # https://naviserver.sourceforge.io/5.0/manual/files/admin-config.html
}


set numSiteNodesEntries [::acs::dc list countSiteNodes {select count(*) from site_nodes}]
set dbPostgresql_p [string equal [::acs::dc cget -backend] postgresql]
set sitenodeBoundaries {
    500000 huge
    5000 large
    0 small
}
if {$dbPostgresql_p} {
    foreach {sitenodeBoundary model} [lsort -stride 2 -decreasing $sitenodeBoundaries] {
        if  {$numSiteNodesEntries > $sitenodeBoundary} {
            set sitenodeModel $model
            break
        }
    }

    if {$sitenodeModel eq "small"} {
        set numPublicReadableSiteNodes [xo::dc list countPublicSiteNodes {
            select count(orig_object_id) from acs_permission.permission_p_recursive_array(array(
                   select s.object_id from apm_packages ap, site_nodes s where s.object_id = ap.package_id
            ), -1, 'read');
        }]
    }
    set checkPublicURL [export_vars -base widely-accessible-packages {
        numSiteNodesEntries numPublicReadableSiteNodes sitenodeModel
    }]
}

#
# Collect information about certain security relevant package parameters parameters
#
set parameter_info {}
if {$secure_connection_p} {
    lappend parameter_info \
        SecureSessionCookie $::acs::kernel_id
}
lappend parameter_info \
    CSPEnabledP             $::acs::kernel_id \
    ShowMembersListTo       [ad_conn subsite_id] \
    UseHtmlAreaForRichtextP [apm_package_id_from_key acs-templating] \
    RichTextEditor          [apm_package_id_from_key acs-templating]

template::multirow create parameter_check \
    parameter_name description package value link diagnosis

foreach {parameter_name package_id} $parameter_info  {
    set value [parameter::get -package_id $package_id -parameter $parameter_name]
    set package_key [apm_package_key_from_id $package_id]
    set description [::acs::dc list get {
        select description from apm_parameters
        where package_key = :package_key
        and parameter_name = :parameter_name
    }]
    switch $parameter_name {
        SecureSessionCookie {
            set diagnosis [ad_decode $value 0 "Allow sessions over HTTP and HTTPS" 1 "Allow sessions only over HTTPS"]
        }
        CSPEnabledP {
            set intro "Context Security Policies (CSP) are"
            set diagnosis [ad_decode $value 0 "$intro not enabled" 1 "$intro enabled"]
        }
        ShowMembersListTo {
            set intro "Show member list to"
            set diagnosis [ad_decode $value \
                               0 "$intro everyone" \
                               1 "$intro members" \
                               2 "$intro administrators only" \
                               3 "$intro members, unless on subsite" \
                              ]
        }
        UseHtmlAreaForRichtextP {
            set diagnosis [ad_decode $value 0 "Rich text editors deactivated" 1 "Richtext editors activated"]
        }
        RichTextEditor {
            set diagnosis "Use this rich text editor when rich text editors are enabled"
        }
        default {
            set diagnosis ""
        }
    }
    template::multirow append parameter_check \
        $parameter_name \
        [lindex $description 0] \
        $package_key \
        $value \
        [string cat \
             /shared/parameters?package_id=$package_id \
             &return_url=/acs-admin/system-overview\
             &scroll_to=$parameter_name] \
        $diagnosis
}


set host_header [security::validated_host_header]
set public_ip_addr_p "?"
if {$host_header ne ""} {
    set host [dict get [ns_parsehostport $host_header] host]
    set current_ip_addr [ns_addrbyhost $host]
    if {[::acs::icanuse "ns_ip"]} {
        set public_ip_addr_p [ns_ip public $current_ip_addr]
    }
}
set public_ip_addr_p_label [ad_decode $public_ip_addr_p 0 no 1 yes $public_ip_addr_p]

#
# If we have a public IP address and we are on a TLS connection, can
# offer a check vs. ssllabs.
#
if {$public_ip_addr_p == 1 && $secure_connection_p} {
    #
    # Do not force a public listing of the results
    #
    set ssllabs_url https://www.ssllabs.com/ssltest/analyze.html?viaform=on&d=https://$host_header&hideResults=on
}

template::multirow create link_check \
    type url status package_id permission_info diagnosis

foreach {type url} [subst {
    internal /acs-service-contract/
    internal /api-doc/
    internal /doc/
    internal /ds/
    internal /request-monitor/
    internal /shared/
    internal /shared/parameters
    internal /test/
    internal /xotcl/
    internal /xotcl/version-numbers
    personal /members/
    personal /shared/community-member?user_id=[ad_conn user_id]
    personal /shared/portrait?user_id=[ad_conn user_id]
    personal /shared/whos-online
}] {

    set posture [::acs_admin::posture_status \
                     -current_location $current_location \
                     -url $url]
    dict with posture {
        template::multirow append link_check \
            $type \
            $url \
            $status \
            $package_id \
            [expr {$status == 404 ? "" : "$direct_permissions [llength $parties] parties"} ] \
            $diagnosis
    }

}

template::multirow create machine_readable url status diagnosis detailURL detailLabel

foreach url {
    /robots.txt
    /security.txt
} {
    try {
        ns_http run -timeout 300ms $current_location$url
    } on ok {result} {
        set status [dict get $result status]
        set diagnosis ""
        set detailURL ""
        set detailLabel ""
        switch $status {
            200 {set diagnosis "publicly accessible"}
            404 {
                set diagnosis "not provided"
                switch $url {
                    /robots.txt   {
                        set detailLabel "RFC 9309"
                        set detailURL https://datatracker.ietf.org/doc/html/rfc9309
                    }
                    /security.txt {
                        set detailLabel "RFC 9116"
                        set detailURL https://www.rfc-editor.org/rfc/rfc9116
                    }
                }
            }
        }
        #append diagnosis " $node_id $package_id ($parties) // [llength $parties] // $direct_permissions"
        #append report "status $status $diagnose\n<br>"
    } on error {errorMsg} {
        set diagnosis $errorMsg
        set status 0
    }

    template::multirow append machine_readable $url $status $diagnosis $detailURL $detailLabel
}


template::multirow create hdr_check \
    field value
foreach url $current_location {
    set result [ns_http run $url]
    set hdrs [dict get $result headers]
    #set location [ns_set iget [dict get $result headers] location]
    ns_log notice "HDRS [ns_set array $hdrs]"
    foreach field {
        Content-Security-Policy
        Referrer-Policy
        Strict-Transport-Security
        X-Forwarded-For
        X-Content-Type-Options
        X-Frame-Options
        X-XSS-Protection
        X-SSL-Request
    } {
        template::multirow append hdr_check $field [ns_set iget $hdrs $field]
    }
}

template::multirow create library_check \
    library swa_link version_color \
    configured_version vulnerability vulnerabilityCheckURL \
    installed_locally available diagnosis

foreach proc_name [::util::resources::resource_info_procs] {
    set resource_info [::$proc_name]
    set libraryName [dict get $resource_info resourceName]

    if {[dict exists $resource_info configuredVersion]} {
        set configuredVersion [dict get $resource_info configuredVersion]
    } else {
        set configuredVersion ?
    }

    if {$configuredVersion ne "?"} {
        set is_installed [::util::resources::is_installed_locally \
                              -resource_info $resource_info]
    } else {
        set version_segment ?
        set is_installed ?
    }
    #
    # Get the package_key from the resourceDir form resource_info to provide
    # a link to the swa pages of the package.
    #
    set resourceDir [dict get $resource_info resourceDir]
    if {[regexp {/packages/([^/]+)/} $resourceDir . package_key]
        && [file exists [acs_package_root_dir $package_key]/www/sitewide-admin/]
    } {
        set swa_link /acs-admin/package/$package_key/
    } else {
        set swa_link ""
    }

    set reported 0
    set version_color "body"
    set availableVersion ""

    if {[dict exists $resource_info versionCheckAPI] && [dict exists $resource_info configuredVersion]} {
        set availableVersion [::util::resources::cdnjs_get_newest_version -resource_info $resource_info]
        if {$availableVersion ne "unknown"} {
            ns_log notice ... configured version $configuredVersion available version $availableVersion
            set new_version_available [expr {$configuredVersion == $availableVersion
                                             ? 0
                                             : [apm_version_names_compare $configuredVersion $availableVersion] < 0}]
            if {$new_version_available} {
                ns_log notice "NEW VERSION for $libraryName"
                switch $libraryName {
                    "CKEditor 4" {set diagnosis "Versions after 4.22.1 require a license"}
                    default      {set diagnosis "Newer version upstream available"}
                }
                set version_color warning
            } else {
                set diagnosis "Up-to-date"
                set version_color success
            }
            set reported 1
        } else {
            set availableVersion ""
            set diagnosis "Could not determine upstream version number"
            set reported 1
        }
    }
    if {!$reported} {
        set version_color "body"
        set diagnosis "Could not determine upstream version number (no version check API available)"
    }

    set vulnerability ""
    set vulnerabilityCheckVersionURL ""
    if {[dict exists $resource_info vulnerabilityCheck]} {
        set vulnerabilityCheck [dict get $resource_info vulnerabilityCheck]
        dict with vulnerabilityCheck {
            set result [::util::resources::check_vulnerability \
                            -service $service \
                            -library $library \
                            -version $configuredVersion]
            if {[dict get $result hasVulnerability] ne "?"} {
                set vulnerabilityCheckResult [dict get $result hasVulnerability]
                if {$vulnerabilityCheckResult ne "?"} {
                    set vulnerability $vulnerabilityCheckResult
                    set vulnerabilityCheckVersionURL [dict get $result versionURL]
                }
            }
        }
    }

    template::multirow append library_check \
        $libraryName $swa_link $version_color $configuredVersion \
        $vulnerability $vulnerabilityCheckVersionURL \
        $is_installed \
        $availableVersion \
        $diagnosis
}


if {0} {
    Report any mounted instance of file-storage that is publicly accessible.
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
