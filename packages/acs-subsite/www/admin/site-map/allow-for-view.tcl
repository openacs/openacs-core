ad_page_contract {
   Ask for confirmation for view on public site_map
    @author Viaro Networks (vivian@viaro.net)
    @cvs-id $id:

} {
    checkbox:integer,multiple,optional
    return_url 
} 

set user_id [ad_maybe_redirect_for_registration]

if { ![info exist checkbox] } {
    set checkbox ""
}

# Get the main site node_id from object_id
set main_node [site_node::get_node_id_from_object_id -object_id [subsite::main_site_id]]
set check_list [list]


# Here we make shure that when a child node is checked all his parents 
# in the tree are also checked as well

foreach check_node $checkbox {
    if { [string equal $main_node $check_node] } {

	# The main site node is always checked
	lappend check_list $check_node

    } elseif {[string equal [site_node::get_parent_id -node_id $check_node] $main_node] } {

	# This node doesn't have a parent node, only the  main site node
	lappend check_list $check_node

    } else {
	# The node has an inmediate parent, we put it on the list and all his parents until the
	# node_id equals the main_site node_id and is already in the list
	lappend check_list $check_node
	while { [site_node::get_parent_id -node_id $check_node] != $main_node && \
		[lsearch -exact $check_list [site_node::get_parent_id -node_id $check_node]] == -1 } {
		set check_node [site_node::get_parent_id -node_id $check_node]
		lappend check_list $check_node
	    }
    }
}


db_transaction {
    db_dml delete_nodes { *SQL* }
    foreach checkbox $check_list {
	db_dml insert_nodes { *SQL* }
    }
}

ad_returnredirect $return_url