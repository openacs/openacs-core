ad_library {

    Tests for procs in tcl/defs-procs.tcl

}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        acs_community_member_admin_url
        acs_community_member_admin_link
        acs_community_member_page
        acs_community_member_url
        acs_community_member_link
        subsite::get_element
        ad_admin_home
        ad_pvt_home
        ad_pvt_home_name
        ad_pvt_home_link
        ad_publisher_name
        ad_site_home_link
        ad_system_name
    } \
    user_links_api {
        Test the various procs that generate a community member URL.
    } {
        set user_id [db_string get_user {
            select max(user_id) from users
        }]

        set admin_url [parameter::get -package_id [ad_acs_kernel_id] -parameter CommunityMemberAdminURL]

        aa_section "Admin URL"
        set url [acs_community_member_admin_url -user_id $user_id]
        aa_true "URL contains admin URL from parameters" \
            {[string first [ad_urlencode_url $admin_url] $url] >= 0}
        aa_true "URL contains the user_id" \
            {[string first $user_id $url] >= 0}

        aa_section "Admin link with custom label"
        set link [acs_community_member_admin_link -user_id $user_id -label "One label"]
        aa_true "Link '$link' contains '$url'" \
            {[string first [ns_quotehtml $url] $link] >= 0}
        aa_true "Link '$link' contains 'One label'" \
            {[string first "One label" $link] >= 0}

        aa_section "Admin link with default label (username)"
        set link [acs_community_member_admin_link -user_id $user_id]
        aa_true "Link '$link' contains '$url'" \
            {[string first [ns_quotehtml $url] $link] >= 0}
        aa_true "Link '$link' contains the username" \
            {[string first [person::name -person_id $user_id] $link] >= 0}

        set member_url [parameter::get -package_id [ad_acs_kernel_id] -parameter CommunityMemberURL]
        set subsite_url [subsite::get_element -element url -notrailing]

        aa_section "Member URL"
        aa_equals "The community member page is as expected" \
            [acs_community_member_page] ${subsite_url}${member_url}
        set url [acs_community_member_url -user_id $user_id]
        aa_true "URL contains member URL from parameters" \
            {[string first [ad_urlencode_url $member_url] $url] >= 0}
        aa_true "URL contains the user_id" \
            {[string first $user_id $url] >= 0}

        aa_section "Member link with custom label"
        set link [acs_community_member_link -user_id $user_id -label "One label"]
        aa_true "Link '$link' contains '$url'" \
            {[string first [ns_quotehtml $url] $link] >= 0}
        aa_true "Link '$link' contains 'One label'" \
            {[string first "One label" $link] >= 0}

        aa_section "Member link with default label (username)"
        set link [acs_community_member_link -user_id $user_id]
        aa_true "Link '$link' contains '$url'" \
            {[string first [ns_quotehtml $url] $link] >= 0}
        aa_true "Link '$link' contains the username" \
            {[string first [person::name -person_id $user_id] $link] >= 0}

        aa_section "Admin home URL"
        aa_equals "The admin home URL is as expected" \
            [ad_admin_home] [subsite::get_element -element url]admin

        aa_section "Private workspace"
        set pvt_home_url [ad_pvt_home]
        aa_equals "The private workspace URL is as expected" \
            $pvt_home_url \
            [subsite::get_element -element url -notrailing][parameter::get -package_id [ad_acs_kernel_id] -parameter HomeURL]

        set pvt_home_name [ad_pvt_home_name]
        aa_equals "The private home name is expected" \
            $pvt_home_name \
            [lang::util::localize [parameter::get -package_id [ad_acs_kernel_id] -parameter HomeName]]

        set pvt_home_link [ad_pvt_home_link]
        aa_true "Private home link is expected" {
            [string first $pvt_home_url $pvt_home_link] >= 0 &&
            [string first $pvt_home_name $pvt_home_link] >= 0 &&
            [ad_looks_like_html_p $pvt_home_link]
        }

        aa_section "Publisher name"
        aa_equals "Publisher name is expected" \
            [ad_publisher_name] \
            [parameter::get -package_id [ad_acs_kernel_id] -parameter PublisherName]

        aa_section "Site home link"
        set old_user_id [ad_conn user_id]
        try {
            ad_conn -set user_id 0
            set site_home_link [ad_site_home_link]

            aa_true "Subsite name is in the link (user 0)" {
                [subsite::get_element -element name] eq "" ||
                [string first [subsite::get_element -element name] $site_home_link] >= 0
            }
            aa_true "Subsite URL is in the link (user 0)" {
                [string first [subsite::get_element -element url] $site_home_link] >= 0
            }
            aa_true "Link is HTML (user 0)" [ad_looks_like_html_p $site_home_link]

            ad_conn -set user_id 1
            set site_home_link [ad_site_home_link]

            aa_true "Subsite name is in the link (user 1)" {
                [subsite::get_element -element name] eq "" ||
                [string first [subsite::get_element -element name] $site_home_link] >= 0
            }
            aa_true "Home URL is in the link (user 1)" {
                [string first $pvt_home_url $site_home_link] >= 0
            }
            aa_true "Link is HTML (user 1)" [ad_looks_like_html_p $site_home_link]
        } finally {
            ad_conn -set user_id $old_user_id
        }

        aa_section "System name"
        aa_equals "ad_system_name returns expected" \
            [ad_system_name] \
            [parameter::get -package_id [ad_acs_kernel_id] -parameter SystemName]
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_parameter_from_configuration_file
    } \
    ad_parameter_from_configuration_file {
        Test ad_parameter_from_configuration_file proc
    } {
        foreach section [ns_configsections] {
            set section_name [ns_set name $section]
            if {[regexp ^ns/server/[ns_info server]/acs(.*)\$ $section_name _ package_key]} {
                set found_p 1
                set package_key [string trimleft $package_key /]
                foreach key [ns_set keys $section] {
                    set expected [ns_set get $section $key]
                    set result [ad_parameter_from_configuration_file $key $package_key]
                    aa_equals "Value is expected" \
                        $result $expected
                }
            }
        }

        if {![info exists found_p]} {
            aa_log "No parameter exposed to the API was found in the server conf."
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        template::adp_include
        ad_include_contract
        ad_page_contract
        ad_page_contract_filter
        ad_page_contract_filter_proc_integer
    } \
    page_contracts {
        Test ad_include_contract and ad_page_contract indirectly.
    } {
        set page {
            ad_include_contract {
                Test Contract
            } {
                integer:integer,notnull
            }
        }
        set test_data {
            {
                integer abc
            }
            true

            {
                integer ""
            }
            true

            {
                integer 1
            }
            false
        }

        foreach {vars outcome} $test_data {
            set wfd [ad_opentmpfile tmpfile .tcl]
            puts -nonewline $wfd $page
            close $wfd

            set path /packages/acs-automated-testing/www/[file rootname [file tail $tmpfile]]
            set callable_tmpfile [acs_root_dir]${path}.tcl
            file rename -- $tmpfile $callable_tmpfile

            aa_$outcome "Template failure is $outcome?" [catch {
                #
                # The template is inflated in a background job so to
                # not tamper with the actual request in case of error.
                #
                aa_silence_log_entries -severities warning {
                    set result [ad_job template::adp_include $path $vars]
                }
            }]
            file delete -- $callable_tmpfile
        }
    }
