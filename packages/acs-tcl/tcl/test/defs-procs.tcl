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
    } \
    user_links_api {
        Test the various procs that generate a community member URL.
    } {
        set user_id [db_string get_user {
            select max(user_id) from users
        }]

        set admin_url [parameter::get -package_id $::acs::kernel_id -parameter CommunityMemberAdminURL]

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

        aa_section "Admin link with default label (user name)"
        set link [acs_community_member_admin_link -user_id $user_id]
        aa_true "Link '$link' contains '$url'" \
            {[string first [ns_quotehtml $url] $link] >= 0}
        aa_true "Link '$link' contains the user name" \
            {[string first [person::name -person_id $user_id] $link] >= 0}

        set member_url [parameter::get -package_id $::acs::kernel_id -parameter CommunityMemberURL]
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

        aa_section "Member link with default label (user name)"
        set link [acs_community_member_link -user_id $user_id]
        aa_true "Link '$link' contains '$url'" \
            {[string first [ns_quotehtml $url] $link] >= 0}
        aa_true "Link '$link' contains the user name" \
            {[string first [person::name -person_id $user_id] $link] >= 0}

    }
