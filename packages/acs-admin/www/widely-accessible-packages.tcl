ad_page_contract {
    List widely accessible packages.

    For now this page handles just publicly accessible pages, but
    might be changed to list also pages which are accessible for all
    site members.

    @author Gustaf Neumann
    @creation-date 2024-08-02
} {
    {numSiteNodesEntries:integer,notnull}
    {numPublicReadableSiteNodes:integer,notnull 0}
    {sitenodeModel:word,notnull large}
    {package_key:token ""}
    {count:integer ""}
}

set current_location  [ns_conn location]

if {$package_key eq ""} {
    set mode overview

    if {$sitenodeModel ne "huge"} {
        #
        # The number is below the "huge" threshold determined by the
        # calling page. The query for determining the permissions
        # should be sufficiently fast.
        #
        set doc(title) "Publicly Accessible Packages"
        set context [list [list posture-overview "Posture Overview"] $doc(title)]

        #
        # Counting # of instances per package_key which are publicly readable
        # (openacs: 8ms, learn: 22s)
        #
        set publicPerPackageKey [xo::dc list count_public_packages_per_package_key {
            select count || ' ' || package_key from (
                select count(orig_object_id), ap.package_key
                from acs_permission.permission_p_recursive_array(array(
                    select s.object_id from apm_packages ap, site_nodes s where s.object_id = ap.package_id
                ), -1, 'read') a, apm_packages ap
                where ap.package_id = orig_object_id
                group by 2 order by 1 desc, 2 asc
            ) as tuples
        }]

        template::multirow create per_package_key \
            count package_key link url package_id status permission_info diagnosis

        foreach tuple $publicPerPackageKey {
            lassign $tuple count package_key

            if {$count == 1} {
                #
                # There is a single package of this type -> list URL and Permission link
                #
                set package_id_and_url [xo::dc list_of_lists -prepare text get_public_packages_package_key {
                    select orig_object_id, site_node__url(s.node_id) from acs_permission.permission_p_recursive_array(array(
                        select s.object_id from apm_packages ap, site_nodes s where s.object_id = ap.package_id and package_key = :package_key
                    ), -1, 'read') a, apm_packages ap, site_nodes s
                    where s.object_id = orig_object_id and ap.package_id = orig_object_id}]
                lassign [lindex $package_id_and_url 0] package_id url
                set link ""
                set posture [::acs_admin::posture_status \
                                 -current_location $current_location \
                                 -url $url]
            } else {
                #
                # Count > 1, provide links per package key
                #
                set package_id 0
                set url ""
                set link [export_vars -base ./widely-accessible-packages {
                    package_key count numPublicReadableSiteNodes numSiteNodesEntries sitenodeModel
                }]
                set posture {status "" diagnosis "" parties "" direct_permissions ""}
            }
            dict with posture {
                set permission_info [expr {$status == 404 ? "" : "$direct_permissions [llength $parties] parties"} ]
                template::multirow append per_package_key \
                    $count $package_key $link $url $package_id $status $permission_info $diagnosis
            }
        }
    } else {
        #
        # The number is above the "huge" threshold determined by the
        # calling page. The query for determining the permissions are
        # probably too slow (e.g. >30sec) so we determine first the
        # installed and mounted packages.
        #
        set doc(title) "Installed Packages"
        set context [list [list posture-overview "Posture Overview"] $doc(title)]

        #
        # Counting # of instances per package_key which are publicly readable
        # (openacs: 8ms, learn: 22s)
        #
        set publicPerPackageKey [xo::dc list_of_lists count_public_packages_per_package_key {
            select count, package_key from (
                select count(s.object_id), ap.package_key from apm_packages ap, site_nodes s
                where s.object_id = ap.package_id group by 2 order by 1 desc, 2 asc
            ) as tuples
        }]
        #ns_log notice "HUGE publicPerPackageKey $publicPerPackageKey"
        template::multirow create per_package_key \
            count package_key link url package_id status permission_info diagnosis

        foreach tuple $publicPerPackageKey {
            lassign $tuple count package_key

            if {$count == 1} {
                #
                # There is a single package of this type -> list URL and Permission link
                #
                set package_id_and_url [xo::dc list_of_lists -prepare text get_public_packages_package_key {
                    select orig_object_id, site_node__url(s.node_id) from acs_permission.permission_p_recursive_array(array(
                        select s.object_id from apm_packages ap, site_nodes s where s.object_id = ap.package_id and package_key = :package_key
                    ), -1, 'read') a, apm_packages ap, site_nodes s
                    where s.object_id = orig_object_id and ap.package_id = orig_object_id}]
                lassign [lindex $package_id_and_url 0] package_id url
                if {$url eq ""} continue
                set link ""
                set posture [::acs_admin::posture_status \
                                 -current_location $current_location \
                                 -url $url]
            } else {
                #
                # Count > 1, provide links per package key
                #
                set package_id 0
                set url ""
                set link [export_vars -base ./widely-accessible-packages {
                    package_key count numPublicReadableSiteNodes numSiteNodesEntries sitenodeModel
                }]
                set posture {status "" diagnosis "" parties "" direct_permissions ""}
            }
            dict with posture {
                set permission_info [expr {$status == 404 ? "" : "$direct_permissions [llength $parties] parties"} ]
                template::multirow append per_package_key \
                    $count $package_key $link $url $package_id $status $permission_info $diagnosis
            }
        }
    }
} else {
    set mode per_package_key
    set doc(title) "Publicly Accessible Packages of type $package_key"
    set context [list [list posture-overview "Posture Overview"] $doc(title)]

    set overviewLink [export_vars -base ./widely-accessible-packages {
        numPublicReadableSiteNodes numSiteNodesEntries sitenodeModel
    }]


    set package_ids_and_urls [xo::dc list_of_lists -prepare text get_public_packages_package_key {
        select orig_object_id, site_node__url(s.node_id) from acs_permission.permission_p_recursive_array(array(
            select s.object_id from apm_packages ap, site_nodes s where s.object_id = ap.package_id and package_key = :package_key
        ), -1, 'read') a, apm_packages ap, site_nodes s
        where s.object_id = orig_object_id and ap.package_id = orig_object_id}]

    template::multirow create urls url package_id
    foreach tuple $package_ids_and_urls {
        lassign $tuple package_id url
        template::multirow append urls $url $package_id
    }
}

if {0} {
    #
    # Get all public publicly readable instances with package_key and URL
    # (openacs: 10ms, learn probably minutes)
    #
    set publicPackages [xo::dc list_of_lists get_public_packages {
        select ap.package_key, site_node__url(s.node_id), package_id
        from acs_permission.permission_p_recursive_array(array(
           select s.object_id from apm_packages ap, site_nodes s where s.object_id = ap.package_id
        ), -1, 'read') a, apm_packages ap, site_nodes s
        where s.object_id = orig_object_id and ap.package_id = orig_object_id
        order by 1
    }]

    template::multirow create public_urls package_key package_id url

    foreach tuple $publicPackages {
        lassign $tuple package_key url package_id
        template::multirow append public_urls $package_key $package_id $url
    }
}
