# /packages/acs-tcl/tcl/test/site-nodes-test-procs.tcl
ad_library {
     Test site node procs
     @author Vinod Kurup [vinod@kurup.com]
     @creation-date Mon Oct 20 16:16:04 2003
     @cvs-id $Id$
}

aa_register_case -cats {
    script
} site_node_closest_ancestor_package {
    Test site_node::closest_ancestor_package
} {
    aa_run_with_teardown -rollback -test_code {
        # 1) set up the site-map
        #        /{acs-core-docs}/{empty-folder} 
        #        node-names generated randomly
        set doc_name [ad_generate_random_string]
        set folder_name [ad_generate_random_string]
        #        get root package_id and node_id
        set root_pkg_id [subsite::main_site_id]
        set root_node_id [site_node::get_node_id -url /]
        #        create the acs-core-docs instance
        set doc_pkg_id [site_node::instantiate_and_mount \
                            -node_name $doc_name \
                            -package_key acs-core-docs]
        set doc_node_id [site_node::get_node_id -url "/$doc_name"]
        #        create a folder underneate acs-core-docs
        set folder_node_id [site_node::new \
                                -parent_id $doc_node_id \
                                -name $folder_name]

        # 2) test -url parameter
        #        test doc's parent
        set package_id [site_node::closest_ancestor_package -url /$doc_name]
        aa_equals "Doc's parent is correct" $package_id $root_pkg_id
        #        test folder's parent 
        set package_id [site_node::closest_ancestor_package \
                            -url /$doc_name/$folder_name]
        aa_equals "Folder's parent is correct" $package_id $doc_pkg_id

        # 3) test -node_id parameter
        #        test doc's parent
        set package_id [site_node::closest_ancestor_package \
                            -node_id $doc_node_id]
        aa_equals "Doc's parent is correct" $package_id $root_pkg_id
        #        test folder's parent 
        set package_id [site_node::closest_ancestor_package \
                            -node_id $folder_node_id]
        aa_equals "Folder's parent is correct" $package_id $doc_pkg_id
        #        find ancestors of the main-site (should fail)
        set package_id [site_node::closest_ancestor_package \
                            -node_id $root_node_id]
        aa_equals "Root has no ancestors" $package_id ""

        # 4) test -package_key parameter
        #        find ancestors of doc which are subsites
        set package_id [site_node::closest_ancestor_package \
                            -node_id $doc_node_id \
                            -package_key acs-subsite]
        aa_equals "Doc ancestor is a subsite" $package_id $root_pkg_id
        #        find ancestors of doc which are photo-albums (should fail)
        set package_id [site_node::closest_ancestor_package \
                            -node_id $doc_node_id \
                            -package_key photo-album]
        aa_equals "Doc has no photo-album ancestors" $package_id ""
        #        find ancestors of folder which are subsites (2 levels up)
        set package_id [site_node::closest_ancestor_package \
                            -node_id $folder_node_id \
                            -package_key acs-subsite]
        aa_equals "Folder's closest subsite ancestor is root" \
            $package_id $root_pkg_id
    }
}
