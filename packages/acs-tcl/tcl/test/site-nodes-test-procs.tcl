# /packages/acs-tcl/tcl/test/site-nodes-test-procs.tcl
ad_library {
     Test site node procs
     @author Vinod Kurup [vinod@kurup.com]
     @creation-date Mon Oct 20 16:16:04 2003
     @cvs-id $Id$
}

aa_register_case \
    -cats { api } \
    -procs {
        site_node::delete
        site_node::get_node_id
        site_node::get_url
        site_node::init_cache
        site_node::instantiate_and_mount s
        ite_node::rename
        site_node::unmount
    } \
    site_node_update_cache {
    Test site_node::update_cache
} {
    aa_run_with_teardown -rollback -test_code {

	aa_log "# 1) mount /doc1 /doc2 /doc1/doc3"
	set doc1_name [ad_generate_random_string]
	set doc2_name [ad_generate_random_string]
	set doc3_name [ad_generate_random_string]
	set node1_pkg_id [site_node::instantiate_and_mount \
			      -node_name $doc1_name \
			      -package_key acs-core-docs]
	set node1_node_id [site_node::get_node_id -url "/$doc1_name"]
	set node2_pkg_id [site_node::instantiate_and_mount \
			      -node_name $doc2_name \
			      -package_key acs-core-docs]
	set node2_node_id [site_node::get_node_id -url "/$doc2_name"]
	set node3_pkg_id [site_node::instantiate_and_mount \
			      -parent_node_id $node1_node_id \
			      -node_name $doc3_name \
			      -package_key acs-core-docs]
	set node3_node_id [site_node::get_node_id -url "/$doc1_name/$doc3_name"]
        set root_node_id [site_node::get_node_id -url /]
	aa_equals "Verify url /doc1 for node1" [site_node::get_url -node_id $node1_node_id] "/$doc1_name/"
	aa_equals "Verify url /doc1/doc3 for node3" [site_node::get_url -node_id $node3_node_id] "/$doc1_name/$doc3_name/"
	aa_equals "Verify url /doc2 for node2" [site_node::get_url -node_id $node2_node_id] "/$doc2_name/"

	aa_log "# 2) rename /doc1 => doc4: Test /doc4 /doc4/doc3 /doc2"
	set doc4_name [ad_generate_random_string]
	site_node::rename -node_id $node1_node_id -name $doc4_name
	aa_equals "Check new url /doc4" [site_node::get_node_id -url "/$doc4_name"] $node1_node_id
	aa_equals "Check new url /doc4/doc3" [site_node::get_node_id -url "/$doc4_name/$doc3_name"] $node3_node_id
	aa_equals "Check old url /doc2" [site_node::get_node_id -url "/$doc2_name"] $node2_node_id
	aa_equals "Make sure old url /doc1 now matches /" [site_node::get_node_id -url "/$doc1_name/"] $root_node_id
	aa_equals "Make sure old url /doc1/doc3 now matches /" [site_node::get_node_id -url "/$doc1_name/$doc3_name/"] $root_node_id
	aa_equals "Verify url /doc4 for node1" [site_node::get_url -node_id $node1_node_id] "/$doc4_name/"
	aa_equals "Verify url /doc4/doc3 for node3" [site_node::get_url -node_id $node3_node_id] "/$doc4_name/$doc3_name/"
	aa_equals "Verify url /doc2 for node2" [site_node::get_url -node_id $node2_node_id] "/$doc2_name/"

	aa_log "# 3) init_cache: Test /doc5 /doc5/doc3 /doc2"
	set doc5_name [ad_generate_random_string]
	db_dml rename_node1 {
	    update site_nodes
	    set name = :doc5_name
	    where node_id = :node1_node_id
	}
        ns_cache_transaction_rollback
	site_node::init_cache
        ns_cache_transaction_begin

	aa_equals "Check url /doc5" [site_node::get_node_id -url "/$doc5_name"] $node1_node_id
	aa_equals "Check url /doc5/doc3" [site_node::get_node_id -url "/$doc5_name/$doc3_name"] $node3_node_id
	aa_equals "Check url /doc2" [site_node::get_node_id -url "/$doc2_name"] $node2_node_id
	aa_equals "Make sure old url /doc1 now matches" [site_node::get_node_id -url "/$doc1_name/"] $root_node_id
	aa_equals "Make sure old url /doc1/doc3 now matches" [site_node::get_node_id -url "/$doc1_name/$doc3_name/"] $root_node_id
	aa_equals "Make sure old url /doc4 now matches" [site_node::get_node_id -url "/$doc4_name/"] $root_node_id
	aa_equals "Make sure old url /doc4/doc3 now matches" [site_node::get_node_id -url "/$doc4_name/$doc3_name/"] $root_node_id
	aa_equals "Verify url /doc5 for node1" [site_node::get_url -node_id $node1_node_id] "/$doc5_name/"
	aa_equals "Verify url /doc5/doc3 for node3" [site_node::get_url -node_id $node3_node_id] "/$doc5_name/$doc3_name/"
	aa_equals "Verify url /doc2 for node2" [site_node::get_url -node_id $node2_node_id] "/$doc2_name/"

	aa_log "# 4) delete doc3: Test /doc5 /doc2, nonexisting /doc5/doc3"
	site_node::unmount -node_id $node3_node_id
	site_node::delete -node_id $node3_node_id
	aa_equals "Check url /doc5" [site_node::get_node_id -url "/$doc5_name"] $node1_node_id
	aa_equals "Check url /doc2" [site_node::get_node_id -url "/$doc2_name"] $node2_node_id
	aa_equals "Make sure old url /doc5/doc3 now matches /doc5" [site_node::get_node_id -url "/$doc5_name/$doc3_name/"] $node1_node_id
	aa_equals "Verify url /doc5 for node1" [site_node::get_url -node_id $node1_node_id] "/$doc5_name/"
	aa_equals "Verify url /doc2 for node2" [site_node::get_url -node_id $node2_node_id] "/$doc2_name/"
    }
}

aa_register_case \
    -cats { api } \
    -procs {
        site_node::closest_ancestor_package
        site_node::get_node_id
        site_node::instantiate_and_mount
        site_node::new
        subsite::main_site_id
    } \
    site_node_closest_ancestor_package {
    Test site_node::closest_ancestor_package
} {
    aa_run_with_teardown -rollback -test_code {
        # 1) set up the site-map
        #        /{acs-core-docs}/{empty-folder}
        #        node-names generated randomly
        set doc_name [ad_generate_random_string]
        set folder_name [ad_generate_random_string]
        #
        #        get root package_id and node_id
        #
        set root_pkg_id [subsite::main_site_id]
        set root_node_id [site_node::get_node_id -url /]
        #
        #        create the acs-core-docs instance
        #
        set doc_pkg_id [site_node::instantiate_and_mount \
                            -node_name $doc_name \
                            -package_key acs-core-docs]
        set doc_node_id [site_node::get_node_id -url "/$doc_name"]
        #
        #        create a folder underneate acs-core-docs
        #
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
        aa_equals "Doc's parent based on node_id <$doc_node_id> is correct" $package_id $root_pkg_id
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

        # 5) test -self parameter
        #        find ancestors of doc, including doc in the search
        set package_id [site_node::closest_ancestor_package \
                            -node_id $doc_node_id \
                            -package_key acs-core-docs \
                            -include_self]
        aa_equals "Doc found itself" $package_id $doc_pkg_id

    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
