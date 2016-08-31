ad_library {

  @author rhs@mit.edu
  @creation-date 2000-09-09
  @cvs-id $Id$
}

ad_proc -public ad_acs_administrator_exists_p {} {
    
    @return 1 if a user with admin privileges exists, 0 otherwise.

} {
    ad_acs_require_basic_schemata
    
    return [db_string admin_exists_p {
        select 1 as admin_exists_p
        from dual
        where exists (
	   select 1
	   from acs_permissions p,
	        party_approved_member_map m,
	        users u,
	        acs_magic_objects amo
	   where amo.name = 'security_context_root'
	     and p.object_id = amo.object_id
	     and p.grantee_id = m.party_id
	     and u.user_id = m.member_id
	     and acs_permission.permission_p(amo.object_id, u.user_id, 'admin')
         )
    } -default 0]
}

ad_proc -private ad_acs_require_basic_schemata {} {

    This is a transitional code to ensure that the SQL schemata
    required for botostrapping (i.e. before the upgrade script) are
    already installed.

} {
    set schema_name "acs_permission"
    if {![db_string has_schema {}]} {
        set kernelSqlDir "$::acs::rootdir/packages/acs-kernel/sql/[db_driverkey {}]/upgrade"
        set files "upgrade-5.9.1d10-5.9.1d11.sql"
        foreach file $files {
            set fn $kernelSqlDir/$file
            if {[file readable $fn]} {
                ns_log notice "bootstrap: upgrading sql file $fn"
                db_source_sql_file -callback apm_dummy_callback $fn
            }
        }
    }
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
    # Define util_memoize with proc here to avoid error messages about multiple 
    # defines.
    if { ![db_table_exists apm_packages] || ![db_table_exists site_nodes] } {
        ns_log warning "ad_verify_install: apm_packages [db_table_exists apm_packages] site_nodes [db_table_exists site_nodes]"
	proc util_memoize {script {max_age ""}} {{*}$script}
	return 0
    }
    set kernel_install_p [apm_package_installed_p acs-kernel] 
    set admin_exists_p [ad_acs_administrator_exists_p]
    
    if { $kernel_install_p && $admin_exists_p} {
	return 1 
    } else {
        ns_log warning "ad_verify_install: kernel_install_p $kernel_install_p admin_exists_p $admin_exists_p"
	proc util_memoize {script {max_age ""}} {{*}$script}
	return 0
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
