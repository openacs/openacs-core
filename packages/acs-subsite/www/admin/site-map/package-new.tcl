# packages/acs-core-ui/www/admin/site-nodes/package-new.tcl

ad_page_contract {

    @author rhs@mit.edu
    @creation-date 2000-09-13
    @cvs-id $Id$

} {
    new_package_id:integer,notnull
    node_id:integer,notnull
    {instance_name ""}
    package_key:notnull
    {expand:integer,multiple ""}
    root_id:integer,optional
}

if { [string equal $package_key "/new"] } {
    ad_returnredirect "/acs-admin/apm/packages-install"
    ad_script_abort
}

set context_id [db_string context_id {
    select parent.object_id as context_id
    from   site_nodes parent, site_nodes child
    where  child.node_id = :node_id
    and    parent.node_id = child.parent_id
}]

# If the parent node didn't have anything mounted, use the current package_id as context_id
if { [empty_string_p $context_id] } {
    set context_id [ad_conn package_id]
}

if { [empty_string_p $instance_name] } {
        set instance_name [db_string instance_default_name "select pretty_name from apm_package_types where package_key = :package_key"]
}

db_transaction {
    set package_id [site_node_create_package_instance -package_id $new_package_id $node_id $instance_name $context_id $package_key]
} on_error {
    if {![db_string package_new_doubleclick_ck {} -default 0]} {
	ad_return_complaint "Error Creating Package" "The following error was generated
		when attempting to create the package
	<blockquote><pre>
		[ad_quotehtml $errmsg]
	</pre></blockquote>"
    }
}

ad_returnredirect ".?[export_url_vars expand:multiple root_id]"
