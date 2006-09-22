ad_library {

    Tests the ad_context_bar_multirow referenced in navigation-procs.tcl.

    @author Juan Pablo Amaya jpamaya@unicauca.edu.co
    @creation-date 21 September 2006
}

ns_log NOTICE $node_id
ad_context_bar_multirow -multirow test_rows -from_node $from_node -node_id $node_id $context