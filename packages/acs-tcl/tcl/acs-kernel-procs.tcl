ad_library {

  @author rhs@mit.edu
  @creation-date 2000-09-09
  @cvs-id $Id$
}

ad_proc -public ad_acs_administrator_exists_p {} {
    
    @return 1 if a user with admin privileges exists, 0 otherwise.

} {
    return [db_string admin_exists_p {} -default 0]
}


ad_proc -public ad_acs_admin_node {} {

    @return The node id of the ACS administration service if it is mounted, 0 otherwise.

} {
    # Obtain the id of the ACS Administration node.

    # DRB: this used to say "and rownum = 1" but I've changed it to an SQL92 form
    # that's ummm...portable!

    return [db_string acs_admin_node_p {
	select case when count(object_id) = 0 then 0 else 1 end
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
	proc util_memoize {script {max_age ""}} {eval $script}
	return 0
    }
    set kernel_install_p [apm_package_installed_p acs-kernel] 
    set admin_exists_p [ad_acs_administrator_exists_p]

    ns_log Debug "Verifying Installation: Kernel Installed? $kernel_install_p \
 	    An Administrator? $admin_exists_p"

    if { $kernel_install_p && $admin_exists_p} {
	return 1 
    } else {
	proc util_memoize {script {max_age ""}} {eval $script}
	return 0
    }
}
