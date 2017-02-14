ad_library {
    
    Tests that deal with the context bar creation.

    @author Juan Pablo Amaya jpamaya@unicauca.edu.co
    @creation-date 11 August 2006
}

namespace eval navigation::test {}

ad_proc navigation::test::context_bar_multirow_filter {} {
    Procuedure for the context_bar_multirow test filter
} {
    aa_run_with_teardown -test_code {
	set testnode_1 [list "/navigation_test_node1/" "navigation_test_node1"]
	set testnode_2 [list "[lindex $testnode_1 0]navigation_test_node2/" "navigation_test_node2"]
       
	# Create hierarchy from the random created nodes
	db_1row query {
	    select MIN(node_id) as first_node from site_nodes
	}
	set idp $first_node
	set idr_1 [site_node::new -name [lindex $testnode_1 1] -parent_id $idp]
	set idr_2 [site_node::new -name [lindex $testnode_2 1] -parent_id $idr_1]
	
	set from_node $first_node
	set node_id $idr_2
	set context "last"
	
	set page [ad_parse_template -params [list [list from_node $from_node] [list node_id $node_id] [list context $context]] "/packages/acs-tcl/tcl/test/multirow-test"]
	
	site_node::delete -node_id $idr_2
	site_node::delete -node_id $idr_1
	
    } -teardown_code {
        site_node::delete -node_id $idr_2
	site_node::delete -node_id $idr_1
	
    }
    ns_return 200 text/html $page
    
    return filter_return
}
    

aa_register_case -cats {
    api 
    smoke
} -procs {

    ad_context_bar_html

} ad_context_bar_html {

    Test if returns a html fragment from a list.

} {

    set ref_list [list [list "/doc/doc0.html" "href0"] [list "/doc/doc1.html" "href1"] [list "/doc/doc2.html" "href2"]]
    set c {}
    set ref_list_print [foreach element $ref_list { append c [lindex $element 0] "  " [lindex $element 1]\n}]
    set separator "-"
    aa_log "List with three references:\n\n$c\nseparator= \" - \" "

    aa_equals "" [ad_context_bar_html -separator $separator $ref_list] "<a href=\"[lindex $ref_list 0 0]\">[lindex $ref_list 0 1]</a> - <a href=\"[lindex $ref_list 1 0]\">[lindex $ref_list 1 1]</a> - [lindex $ref_list 2 0] [lindex $ref_list 2 1]"

}

aa_register_case -cats {
    api 
    smoke
} -procs {

ad_context_bar

} ad_context_bar {

    Test if returns a well formed context_bar in html format from a site node.

} {
    
    aa_run_with_teardown -rollback -test_code {

	# Setup nodes from the context bar, create two random nodes to include
	set separator "-"
	set random1 [ad_generate_random_string]
	set testnode_1 [list "/$random1/" "ACS Automated Testing"]

	set random2 [ad_generate_random_string]
	set testnode_2 [list "[lindex $testnode_1 0]$random2/" "ACS Automated Testing"]

	set leave_node "ref_final"
	set root_node [list "/" \#acs-kernel.Main_Site\#]
	if { [string match "admin/*" [ad_conn extra_url]] } {
	    set admin_node [list "[ad_conn package_url]admin/" "Administration"]
	} else {
	    set admin_node ""
	}
	
	# Create hierarchy from the random created nodes
        db_1row query {
           select MIN(node_id) as first_node from site_nodes
        }
        set idp $first_node
        set idr_1 [site_node::new -name $random1 -parent_id $idp]
        set idr_2 [site_node::new -name $random2 -parent_id $idr_1]
        site_node::mount -node_id $idr_1 -object_id [ad_conn package_id]
        site_node::mount -node_id $idr_2 -object_id [ad_conn package_id]
	aa_log "Created two test sites nodes: testnode_1 = [lindex $testnode_1 1],\n\
		testnode_2 = [lindex $testnode_2 1]n\
		testnode_2 is a child of testnode_1"

        array set node  [site_node::get -node_id $idp]
        array set node1 [site_node::get -node_id $idr_1]
        array set node2 [site_node::get -node_id $idr_2]
        set msg ""
        append msg \
            "node0  $idp  parent $node(parent_id)  url $node(url) object_id $node(object_id)"\
            "\nnode1 $idr_1 parent $node1(parent_id)  url $node1(url) object_id $node1(object_id)" \
            "\nnode2 $idr_2 parent $node2(parent_id) url $node2(url) object_id $node2(object_id)"
        aa_log $msg
        
	#-----------------------------------------------------------------------
	# Case 1: node_id = testnode_1
	#-----------------------------------------------------------------------
	aa_log "Case 1: node_id = testnode_1 <$testnode_1>"
	set bar_components [list $root_node $testnode_1 $admin_node]
        #aa_log "bar_components $bar_components"
        set context_barp ""
	foreach value $bar_components {
		append context_barp "<a href=\""
		append context_barp [lindex $value 0]
		append context_barp "\">"
		append context_barp [lindex $value 1]
		append context_barp "</a>"
		append context_barp " $separator "
	}
	append context_barp "$leave_node"
	set context_bar [ad_context_bar -node_id $idr_1 -separator $separator $leave_node]

	# Test
        aa_log "ad_context_bar 1: '$context_bar'\nad_context_bar 2: '$context_barp'"
	aa_true "Context_bar = $context_barp" [string equal $context_bar $context_barp]

	#-----------------------------------------------------------------------
        # Case 2: node_id = testnode_2 (testnode2 is a testnode_1 children)
	#-----------------------------------------------------------------------
	aa_log "Case 2: node_id = testnode_2 (testnode2 is a testnode_1 children)"
        set bar_components [list $root_node $testnode_1 $testnode_2 $admin_node]
        set context_barp ""
        foreach value $bar_components {
            append context_barp "<a href=\""
	    append context_barp [lindex $value 0]
            append context_barp "\">"
	    append context_barp [lindex $value 1]
            append context_barp "</a>"
            append context_barp " $separator "
        }
        append context_barp "$leave_node"
        set context_bar [ad_context_bar -node_id $idr_2 -separator $separator $leave_node]

        aa_true "Context_bar = $context_barp" [string equal $context_bar $context_barp]

	#----------------------------------------------------------------------------
        # Case 3: from_node = testnode_1 and node_id = testnode_2
	#----------------------------------------------------------------------------
	aa_log "Case 3: from_node = testnode_1 and node_id = testnode_2"
        set bar_components [list $testnode_1 $testnode_2 $admin_node]
        set context_barp ""
        foreach value $bar_components {
                append context_barp "<a href=\""
	    append context_barp [lindex $value 0]
                append context_barp "\">"
	    append context_barp [lindex $value 1]
                append context_barp "</a>"
                append context_barp " $separator "
        }
        append context_barp "$leave_node"
	set context_bar [ad_context_bar -from_node $idr_1 -node_id $idr_2 -separator $separator $leave_node]	
	aa_true "Context_bar = $context_barp" [string equal $context_bar $context_barp]
    }
}

aa_register_case -cats {
    api 
    smoke 
    web
} -libraries tclwebtest -procs {

    ad_context_bar_multirow
    
} ad_context_bar_multirow {

    Test if returns a well formed context_bar in html format from a site node in a multirow.

} {
    # Setup nodes from the context bar, create two nodes to include
    set separator ""
    set testnode_1 [list "/navigation_test_node1/" "navigation_test_node1"]
    set testnode_2 [list "[lindex $testnode_1 0]navigation_test_node2/" "navigation_test_node2"]
    set root_node [list "/" "Main Site"]
    set last_node [list "" "last"]

    set bar_components [list $root_node $testnode_1 $testnode_2 $last_node]
    set context_barp ""
    foreach value $bar_components {
        append context_barp "<a href=\""
        append context_barp [lindex $value 0]
        append context_barp "\">"
        append context_barp [lindex $value 1]
        append context_barp "</a>"
    }
    ad_register_filter postauth GET /test.testf navigation::test::context_bar_multirow_filter
    set server [twt::server_url]
    ::twt::do_request "$server/test.testf"
    aa_log "Filter page created: [tclwebtest::response url]\ shows the multirow"
    set response_body [::tclwebtest::response body]
    aa_equals "Context bar $context_barp" $response_body $context_barp
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
