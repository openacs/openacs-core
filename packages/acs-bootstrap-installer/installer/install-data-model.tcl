ad_page_contract {

    Installs the OpenACS kernel data model, using the <code>sql/acs-kernel-create</code>
    script.

    @author Jon Salz (jsalz@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$

} {
}


ns_write "[install_header 200 "Installing Kernel Data Model"]
"

if {[install_good_data_model_p] } {
    ns_write "Data model installed.
<p>
[install_next_button \"packages-install\"]
[install_footer]
"
return
}

ns_write "
Installing the OpenACS kernel data model...
<blockquote><pre>
"
cd [file join [acs_root_dir] packages acs-kernel sql [db_type]]
db_source_sql_file -callback apm_ns_write_callback "acs-kernel-create.sql"

# DRB: Now initialize the APM's table of known database types.  This is
# butt-ugly.  We could have apm-create.sql do this but that would mean
# adding a new database type would require editing two places (the very
# obvious list in bootstrap.tcl and the less-obvious list in apm-create.sql).
# On the other hand, this is ugly because now this code knows about the
# apm datamodel as well as the existence of the special acs-kernel module.

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

ns_write "</pre></blockquote>

Done installing the OpenACS kernel data model.<p>

"

# Some APM procedures use util_memoize, so initialize the cache 
# before starting APM install
apm_source "[acs_package_root_dir acs-tcl]/tcl/20-memoize-init.tcl"

apm_version_enable -callback apm_ns_write_callback [apm_package_install -callback apm_ns_write_callback "[file join [acs_root_dir] packages acs-kernel acs-kernel.info]"]

ns_write "<p>Loading package .info files.<p>"

# Preload all the .info files so the next page is snappy.
apm_dependency_check -initial_install [apm_scan_packages -new [file join [acs_root_dir] packages]]

ns_write "Done loading package .info files<p>
[install_next_button "packages-install"]

[install_footer]
"
