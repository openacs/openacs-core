ad_library {

  @author rhs@mit.edu
  @creation-date 2000-09-09
  @cvs-id $Id$
}

ad_proc -public ad_acs_administrator_exists_p {} {
    
    @return 1 if a user with admin privileges exists, 0 otherwise.

} {
    return [db_string admin_exists_p {
	select 1 as admin_exists_p
	from dual
	where exists (select 1
		      from acs_object_party_privilege_map m, users u
		      where m.object_id = 0
		      and m.party_id = u.user_id
		      and m.privilege = 'admin')
    } -default 0]
}


ad_proc -public ad_acs_admin_node {} {

    @return The node id of the ACS administration service if it is mounted, 0 otherwise.

} {
    # Obtain the id of the ACS Administration node.

    # DRB: this used to say "and rownum = 1" to limit the return to a single row,
    # but this is Oracle-specific.  It surprises me that the author thinks
    # that more than one site_node might have object_id equal to the package_id being
    # selected, but there's no harm in forcing the query to only return a single row
    # no matter what.  Using "min()" is portable, at least...

    return [db_string acs_admin_node_p {
	select min(node_id)
	from site_nodes
	where object_id = (select package_id 
	                   from apm_packages 
	                   where package_key = 'acs-admin')
    } -default 0]
}

ad_proc -public ad_verify_install {} {
  Returns 1 if the acs is properly installed, 0 otherwise.
} {
    if { ![db_table_exists apm_packages] || ![db_table_exists site_nodes] } {
	ad_proc util_memoize {script {max_age ""}} {no cache} {eval $script}
	return 0
    }
    set kernel_install_p [apm_package_installed_p acs-kernel] 
    set admin_node_p [ad_acs_admin_node] 
    set admin_exists_p [ad_acs_administrator_exists_p]

    ns_log Debug "Verifying Installation: Kernel Installed? $kernel_install_p \
	    ACS Administration Link Id: $admin_node_p  An Administrator? $admin_exists_p"

    if { $kernel_install_p && $admin_node_p && $admin_exists_p} {
	return 1 
    } else {
	ad_proc util_memoize {script {max_age ""}} {no cache} {eval $script}
	return 0
    }
}


