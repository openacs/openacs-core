ad_page_contract {

    Installs/enables packages, according to the information prompted for
    in <code>packages-select</code>.

} {
    { install:multiple "" }
    { enable:multiple "" }
    { return_text "
<form action=/>
<input type=hidden name=done_p value=1>
<center>
<input type=submit value=\"Finish ->\">
</center>

[install_footer]
"}

}

ns_write "[install_header 200 "Installing Packages"]

<ul>
"

foreach version_id $install {
    db_1row version_select {
	select pretty_name, version_name, package_key
	from apm_package_version_info i
	where version_id = :version_id
    }
    ns_write "<p><li>Installing $pretty_name $version_name...\n"

    set ul_p 0

    foreach file [apm_get_package_files -package_key $package_key -file_type data_model_create] {
	if { [string match *-drop.sql [file tail $file]] } {
	    continue
	}
	if { !$ul_p } {
	    ns_write "<ul>\n"
	    set ul_p 1
	}
	ns_write "<li>Loading data model file $file...
<blockquote><pre>
"
	cd "[acs_package_root_dir $package_key]"
        db_source_sql_file -ns_write "[acs_root_dir]/packages/$package_key/$file"

        ns_write "</pre></blockquote>\n"
    }

    foreach file [apm_get_package_files -package_key $package_key -file_type java_code] {
	if { !$ul_p } {
	    ns_write "<ul>\n"
	    set ul_p 1
	}
	ns_write "<li>Loading java code file $file...
<blockquote><pre>
"
        ns_write [db_source_sqlj_file  "[acs_root_dir]/packages/$package_key/$file"]

        ns_write "</pre></blockquote>\n"
    }

    if { [lsearch $enable $version_id] >= 0 } {
	if { !$ul_p } {
	    ns_write "<ul>\n"
	    set ul_p 1
	}
	ns_write "<li>Enabling package.\n"
	apm_enable_version $version_id
    }

    if { $ul_p } {
	ns_write "</ul>\n"
    }
}

#### TEMPORARY ######
# Because dependencies don't work yet, source the acs-core-ui file here.
ns_write "<li>Loading data model for ACS-Core-UI...
<blockquote><pre>
"
cd "[acs_package_root_dir acs-core-ui]"
db_source_sql_file -ns_write "[acs_root_dir]/packages/acs-core-ui/sql/acs-core-ui-create.sql"
ns_write "</pre></blockquote>\n"

# Redirect to index.tcl?done_p=1. We do this so the user can just hit <i>Reload</i>
# on their browser to get to the real site, once they restart the server.

ns_write "</ul>

Done installing packages.
"
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
