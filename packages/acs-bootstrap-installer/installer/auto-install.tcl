ad_page_contract {

    This page can be used to perform a complete non-interactive installation.
    All packages are installed.
    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$
} {
    {system_name "System Name"}
    {publisher_name "Publisher Name"}
    {system_owner "System Owner"}
    {admin_owner "Admin Owner"}
    {host_administrator "Host Administrator"}
    {outgoing_sender "Outgoing Sender"}
    {email "system"}
    {first_names "system"}
    {last_name "manager"}
    {password "changeme"}
    {password_question "Who am I?"}
    {password_answer "system manager"}
}

# this is hard-coded into installer because the actual definition is
# is an -init file which isn't sourced by the installer.
proc ad_acs_kernel_id {} {
    if {[db_table_exists apm_packages]} {
	return [db_string acs_kernel_id_get {
	    select package_id from apm_packages
	    where package_key = 'acs-kernel'
	} -default 0]
    } else {
	    return 0
    }
}

if { [ad_verify_install] } {
    ns_write [install_header 200 "Installation Complete."]
    ns_write "The Installation is complete.<p>[install_footer]"
    ad_script_abort
}

cd "[acs_root_dir]/packages/acs-kernel/sql/[db_type]"
ns_write [install_header 200 "Automatic Installation"]

if { ![install_good_data_model_p] } {
    ns_write "<ul>
  <li>Installing Core Data Model.<p><pre><blockquote>
"
    db_source_sql_file -callback apm_ns_write_callback acs-kernel-create.sql
    ns_write "</pre></blockquote><p>"

    # DRB: Now initialize the APM's table of known database types.  This is
    # butt-ugly.  We could have apm-create.sql do this but that would mean
    # adding a new database type would require editing two places (the very
    # obvious list in bootstrap.tcl and the less-obvious list in apm-create.sql).
    # On the other hand, this is ugly because now this code knows about the
    # apm datamodel as well as the existence of the special acs-kernel module.

    # JM: Now even uglier, because I just cut and pasted this from
    # install-data-model.tcl into auto-install.tcl, too.

    set apm_db_types_exists [db_string db_types_exists "
	select case when count(*) = 0 then 0 else 1 end from apm_package_db_types"]

    if { !$apm_db_types_exists } {
	ns_log Notice "Populating apm_package_db_types"
	foreach known_db_type [db_known_database_types] {
	    set db_type [lindex $known_db_type 0]
	    set db_pretty_name [lindex $known_db_type 2]
	    db_dml insert_apm_db_type {
		insert into apm_package_db_types
		    (db_type_key, pretty_db_name)
		values
		    (:db_type, :db_pretty_name)
	    }
	}
    }
    apm_version_enable -callback apm_ns_write_callback [apm_package_install "[acs_root_dir]/packages/acs-kernel/acs-kernel.info"]
}

ns_write "  <p><li>Installing packages.<p>
"
# Attempt to install all packages.
set dependency_results [apm_dependency_check -initial_install [apm_scan_packages -new [file join [acs_root_dir] packages]]]
set dependencies_satisfied_p [lindex $dependency_results 0]
set pkg_list [lindex $dependency_results 1]
apm_packages_full_install -callback apm_ns_write_callback $pkg_list
ns_write "<p>Done."

# Complete the initial install.
ns_write "  <p><li> Completing Install sequence.<p><pre><blockquote>"
cd [file join [acs_root_dir] packages acs-kernel sql [db_type]]
db_source_sql_file -callback apm_ns_write_callback acs-install.sql
ns_write "</blockquote></pre><p>Done."

# Generate tokens.
ns_write "  <p><li><font color=red>NOT</font> Generating secret tokens\
          for secure login sessions..."
populate_secret_tokens_db
ns_write "  <p>Done.<p>"

# Create the site-wide administrator.
if { ![ad_acs_administrator_exists_p] } {
    ns_write "  <p><li>Creating site-wide administrator $email with password $password."
    db_transaction {
	set user_id [ad_user_new $email $first_names $last_name $password $password_question $password_answer]
	db_exec_plsql grant_admin {
	    begin
		acs_permission.grant_permission (
		    object_id => acs.magic_object_id('security_context_root'),
		    grantee_id => :user_id,
		    privilege => 'admin'
		);
	    end;
	}
    }
}

# Instantiate and mount all uninstantiated packages.
ns_write "  <p><li> Mounting packages.<p><pre><blockquote>"

db_foreach all_unmounted_package_key {
    select t.package_key 
    from apm_package_types t, apm_packages p
    where t.package_key = p.package_key(+) 
    and p.package_id is null
} {
    site_node::instantiate_and_mount -package_key $package_key
}

ns_write "</blockquote></pre>.
<li> Check acs-kernel id: [ad_acs_kernel_id].<br>"

ns_write "  <p><li>Setting Parameters."

foreach { var param } {
    system_name SystemName
    publisher_name PublisherName
    system_owner SystemOwner
    admin_owner AdminOwner
    host_administrator HostAdministrator
	outgoing_sender OutgoingSender
} {
    ad_parameter -set [set $var] -package_id [ad_acs_kernel_id] $param
}

# set the Main Site RestrictToSSL parameter

set main_site_id [db_string main_site_id_select { 
    select package_id from apm_packages
    where instance_name = 'Main Site' 
}]

ad_parameter -set "acs-admin/*" -package_id $main_site_id RestrictToSSL

# We are finished installing

db_release_unused_handles
ns_write "</ul><p><strong>Installation Complete.  Please restart your server.[install_footer]"
exit
