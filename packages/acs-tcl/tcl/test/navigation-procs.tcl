ad_library {

    Tests that deal with the context bar creation.

    @author Juan Pablo Amaya jpamaya@unicauca.edu.co
    @creation-date 11 August 2006
}

namespace eval navigation::test {}

ad_proc navigation::test::context_bar_multirow_filter {} {
    Procedure for the context_bar_multirow test filter
} {
    aa_run_with_teardown -rollback -test_code {
        set testnode_1 [list "/navigation_test_node1/" "navigation_test_node1"]
        set testnode_2 [list "[lindex $testnode_1 0]navigation_test_node2/" "navigation_test_node2"]

        # Create hierarchy from the random created nodes
        set root_node [site_node::get_from_url -url "/"]
        set root_node_id [dict get $root_node node_id]

        # Create and mount new node. We also need a subsite underneath
        # or the context bar won't display them.
        set node_name [lindex $testnode_1 1]
        set package_id [site_node::instantiate_and_mount \
                            -parent_node_id $root_node_id \
                            -node_name $node_name \
                            -package_name $node_name \
                            -package_key "acs-subsite"]
        set idr_1 [dict get [site_node::get_from_object_id -object_id $package_id] node_id]
        set node_name [lindex $testnode_2 1]
        set package_id [site_node::instantiate_and_mount \
                            -parent_node_id $idr_1 \
                            -node_name $node_name \
                            -package_name $node_name \
                            -package_key "acs-subsite"]
        set idr_2 [dict get [site_node::get_from_object_id -object_id $package_id] node_id]

        set node_id $idr_2
        set context "last"

        set page [ad_parse_template -params \
                      [list \
                           [list from_node $root_node_id] \
                           [list node_id $node_id] \
                           [list context $context]] \
                      "/packages/acs-tcl/tcl/test/multirow-test"]

    } -teardown_code {
        site_node::delete -node_id $idr_2
        site_node::delete -node_id $idr_1
    }
    ns_return 200 text/html $page

    return filter_return
}


aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_context_bar_html
    } ad_context_bar_html {

    Test if returns an HTML fragment from a list.

} {

    set ref_list [list [list "/doc/doc0.html" "href0"] [list "/doc/doc1.html" "href1"] [list "/doc/doc2.html" "href2"]]
    set c {}
    set ref_list_print [foreach element $ref_list { append c [lindex $element 0] "  " [lindex $element 1]\n}]
    set separator "-"
    aa_log "List with three references:\n\n$c\nseparator= \" - \" "

    aa_equals "" [ad_context_bar_html -separator $separator $ref_list] \
        "<a href=\"[lindex $ref_list 0 0]\">[lindex $ref_list 0 1]</a> - <a href=\"[lindex $ref_list 1 0]\">[lindex $ref_list 1 1]</a> - [lindex $ref_list 2 0] [lindex $ref_list 2 1]"
}

aa_register_case -cats {
    api
    smoke
} -procs {
    ad_context_bar
    site_node::get
    site_node::mount
    site_node::new
} ad_context_bar {

    Test if returns a well formed context_bar in HTML format from a site node.

} {

    aa_run_with_teardown -rollback -test_code {

        set main_node [site_node::get -url /]
        set this_package_id [ad_conn package_id]
        set this_package_name [db_string get_name {
            select instance_name from apm_packages
            where package_id = :this_package_id
        }]

        # Setup nodes from the context bar, create two random nodes to include
        set separator "-"
        set random1 [ad_generate_random_string]
        set testnode_1 [list "/$random1/" $this_package_name]

        set random2 [ad_generate_random_string]
        set testnode_2 [list "[lindex $testnode_1 0]$random2/" $this_package_name]

        set leave_node "ref_final"
        set root_node [list "/" [dict get $main_node instance_name]]
        if { [string match "admin/*" [ad_conn extra_url]] } {
            set admin_node [list "[ad_conn package_url]admin/" [_ acs-tcl.Administration]]
        } else {
            set admin_node ""
        }

        # Create hierarchy from the random created nodes
        set idp [dict get $main_node node_id]
        set idr_1 [site_node::new -name $random1 -parent_id $idp]
        set idr_2 [site_node::new -name $random2 -parent_id $idr_1]
        site_node::mount -node_id $idr_1 -object_id $this_package_id
        site_node::mount -node_id $idr_2 -object_id $this_package_id
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
        set bar_components [list $root_node $testnode_1]
        if {$admin_node ne ""} {
            lappend bar_components $admin_node
        }
        #aa_log "bar_components $bar_components"
        set context_barp ""
        foreach value $bar_components {
            append context_barp \
                [subst {<a href="[ns_quotehtml [lindex $value 0]]">[ns_quotehtml [lindex $value 1]]</a> $separator }]
        }
        append context_barp "$leave_node"
        set context_bar [ad_context_bar -node_id $idr_1 -separator $separator $leave_node]

        # Test
        set msg [ns_quotehtml "ad_context_bar 1: '$context_bar'\nad_context_bar 2: '$context_barp'"]
        aa_log "<pre>$msg</pre>"
        aa_equals "Context_bar = $context_barp"  $context_bar $context_barp

        #-----------------------------------------------------------------------
        # Case 2: node_id = testnode_2 (testnode2 is a testnode_1 children)
        #-----------------------------------------------------------------------
        aa_log "Case 2: node_id = testnode_2 (testnode2 is a testnode_1 children)"
        set bar_components [list $root_node $testnode_1 $testnode_2]
        if {$admin_node ne ""} {
            lappend bar_components $admin_node
        }
        set context_barp ""
        foreach value $bar_components {
            append context_barp \
                [subst {<a href="[ns_quotehtml [lindex $value 0]]">[ns_quotehtml [lindex $value 1]]</a> $separator }]
        }
        append context_barp "$leave_node"
        set context_bar [ad_context_bar -node_id $idr_2 -separator $separator $leave_node]

        set msg [ns_quotehtml "ad_context_bar 1: '$context_bar'\nad_context_bar 2: '$context_barp'"]
        aa_log "<pre>$msg</pre>"

        aa_equals "Context_bar = $context_barp"  $context_bar $context_barp

        #----------------------------------------------------------------------------
        # Case 3: from_node = testnode_1 and node_id = testnode_2
        #----------------------------------------------------------------------------
        aa_log "Case 3: from_node = testnode_1 and node_id = testnode_2"
        set bar_components [list $testnode_1 $testnode_2]
        if {$admin_node ne ""} {
            lappend bar_components $admin_node
        }
        set context_barp ""
        foreach value $bar_components {
            append context_barp \
                [subst {<a href="[lindex $value 0]">[lindex $value 1]</a> $separator }]
        }
        append context_barp "$leave_node"
        set context_bar [ad_context_bar -from_node $idr_1 -node_id $idr_2 -separator $separator $leave_node]
        aa_equals "Context_bar = $context_barp"  $context_bar $context_barp
    }
}

aa_register_case \
    -cats {api smoke web} \
    -procs {
        ad_context_bar_multirow
    } \
    ad_context_bar_multirow {

    Test if returns a well formed context_bar in HTML format from a site node in a multirow.

} {
    # Setup nodes from the context bar, create two nodes to include
    set separator ""
    set testnode_1 [list "/navigation_test_node1/" "navigation_test_node1"]
    set testnode_2 [list "[lindex $testnode_1 0]navigation_test_node2/" "navigation_test_node2"]
    set main_node [site_node::get -url /]
    set root_node [list "/" [lang::util::localize [dict get $main_node instance_name] [lang::system::site_wide_locale]]]
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
    ns_register_proc GET /test.testf {
        navigation::test::context_bar_multirow_filter
    }
    set d [acs::test::http /test.testf]
    acs::test::reply_has_status_code $d 200
    ns_unregister_op GET /test.testf

    set response_body [dict get $d body]
    ns_log notice "CONTEXT  BARP $context_barp"
    ns_log notice "RESPONSE BODY $response_body"
    aa_equals "Context bar" [ns_quotehtml $response_body] [ns_quotehtml $context_barp]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
