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
    apm_version_enable -callback apm_ns_write_callback [apm_package_install "[acs_root_dir]/packages/acs-kernel/acs-kernel.info"]
}

ns_write "  <p><li><font color=red>NOT</font> Generating secret tokens\
          for secure login sessions..."
populate_secret_tokens_db
ns_write "  <p>Done.<p>"



if { ![ad_acs_administrator_exists_p] } {
    ns_write "  <p><li>Creating site-wide administrator $email with password $password."
    db_transaction {
	set user_id [ad_user_new $email $first_names $last_name $password $password_question $password_answer]
	db_dml grant_admin {
	    begin
	    acs_permission.grant_permission (
					     object_id => acs.magic_object_id('security_context_root'),
					     grantee_id => :user_id,
					     privilege => 'admin'
					     );
	    end;
	}
    } on_error {
	global errorInfo    
	install_return 200 "Unable to Create Administrator" "
    
Unable to create the site-wide administrator:
   
<blockquote><pre>[ad_quotehtml $errorInfo]</pre></blockquote>    
"
        ad_script_abort
    }
}

ns_write "  <p><li>Installing packages.<p>
"
# Attempt to install all packages.
set dependency_results [apm_dependency_check -initial_install [apm_scan_packages -new [acs_root_dir]/packages]]
set dependencies_satisfied_p [lindex $dependency_results 0]
set pkg_list [lindex $dependency_results 1]
apm_packages_full_install -callback apm_ns_write_callback $pkg_list

# Complete the initial install.
ns_write "  <p><li> Completing Install sequence.<p><pre><blockquote>"
db_source_sql_file -callback apm_ns_write_callback acs-install.sql
ns_write "</blockquote></pre>."

ns_write "  <p><li> Mounting packages.<p><pre><blockquote>"

# Instantiate and mount all uninstantiated packages.

db_foreach all_unmounted_package_key {
    select t.package_key 
    from apm_package_types t, apm_packages p
    where t.package_key = p.package_key(+) 
    and p.package_id is null
} {
    apm_package_instantiate_and_mount -callback apm_ns_write_callback $package_key
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
} {
    ad_parameter -set [set $var] -package_id [ad_acs_kernel_id] $param
}

db_release_unused_handles
ns_write "</ul><p><strong>Installation Complete.  Please restart your server.[install_footer]"
exit
