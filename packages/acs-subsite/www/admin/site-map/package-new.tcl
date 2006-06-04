# packages/acs-core-ui/www/admin/site-nodes/package-new.tcl

ad_page_contract {
    Create a new package and mount it in the site map. If new_node_p is false then
    the package will be mounted at node_id. If new_node_p is true then a new node with
    name node_name will be created under root_id and the package will be mounted there.

    @author rhs@mit.edu
    @creation-date 2000-09-13
    @cvs-id $Id$

} {
    {new_package_id:integer ""}
    node_id:integer,notnull
    {new_node_p f}
    {node_name:trim ""}
    {instance_name ""}
    package_key:notnull
    {expand:integer,multiple ""}
    root_id:integer,optional
}

if { [string equal $package_key "/new"] } {
    ad_returnredirect "/acs-admin/apm/packages-install"
    ad_script_abort
}

if { [empty_string_p $instance_name] } {
        set instance_name [db_string instance_default_name "select pretty_name from apm_package_types where package_key = :package_key"]
}

db_transaction {

    # Set the context_id to the object_id of the parent node
    # If the parent node didn't have anything mounted, use the current package_id as context_id
    set context_id [ad_conn package_id]
    array set node [site_node::get -node_id $node_id]

    if { ![empty_string_p $node(object_id)] } {
            set context_id $node(object_id)
    }

    if { $new_node_p } {
        # Create a new node under node_id and mount the package there
        set package_id [site_node::instantiate_and_mount -package_id $new_package_id \
                                                         -package_key $package_key \
                                                         -parent_node_id $node_id \
                                                         -package_name $instance_name \
                                                         -context_id $context_id \
                                                         -node_name $node_name]
    } else {
        # Mount the new package at node_id
        set package_id [site_node::instantiate_and_mount -package_id $new_package_id \
                                                         -package_key $package_key \
                                                         -node_id $node_id \
                                                         -package_name $instance_name \
			                                 -context_id $context_id ]
    }

} on_error {
    if {![db_string package_new_doubleclick_ck {} -default 0]} {
	ad_return_complaint 1 "Error Creating Package: The following error was generated
		when attempting to create the package
	<blockquote><pre>
		[ad_quotehtml $errmsg]
	</pre></blockquote>"
    }
}

ad_returnredirect ".?[export_url_vars expand:multiple root_id]"
