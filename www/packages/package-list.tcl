ad_page_contract {

    Show all packages available. Hackish right now, will have to fix it.

    @author Roberto Mello 
    @cvs-id $Id$

} {
    {install_path [apm_workspace_install_dir]}
}

ad_return_top_of_page "[ad_header "Package List"]"

### Selection Phase
set spec_files [apm_scan_packages $install_path]

# Nothing in the install dir, maybe they just copied the files in under packages.
if { [empty_string_p $spec_files] } {
    set actual_install_path "[acs_root_dir]/packages"
    set spec_files [apm_scan_packages $actual_install_path]
    # We don't need to copy any files, because they are already there.
    ad_set_client_property apm copy_files_p 0 
} else {
    ad_set_client_property apm copy_files_p 1 
    set actual_install_path $install_path
}

if { [empty_string_p $spec_files] } {
    # No spec files to work with.
    ns_write "
    <h2>No Packages in the Packages directory</h2>
    "
} else {   
    
    ns_write "
    <h2>Packages Available on this OpenACS installation</h2>
    <p>
    
    <table cellpadding=5 cellspacing=5>
	    <tr bgcolor='#f8f8f8'>
	    	<th width='20%'>Package</th>
		<th width='60%'>Description</th>
		<th width='10%'>Provides</th>
		<th width='10%'>Requires</th>
	    </tr>"


    # Client properties do not deplete the limited URL variable space.
    # But they are limited to the maximum length of a varchar ...

    ad_set_client_property -clob t apm spec_files $spec_files
    ad_set_client_property apm install_path $actual_install_path

    set errors [list]
    set i 0
    foreach spec_file $spec_files {
	### Parse the package.
	if { [catch { array set package [apm_read_package_info_file $spec_file] } errmsg] } {
	    lappend errors "<li>Unable to parse $spec_file.  The following error was generated:
	    <blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote><p>"
	} else {
		ns_log notice [join [array names package]]
		if { $i % 2 > 0 } { 
			ns_write "
		<tr bgcolor='white'>"
		} else {
			ns_write "
		<tr bgcolor='#ececec'>"
		}	
		ns_write "
			<td>$package(package-name)</td>"
		if { [empty_string_p $package(description)] } {
			ns_write "
			<td>$package(summary)</td>"
		} else {
			ns_write "
			<td>$package(description)</td>"
		}
		ns_write "
			<td>[join $package(provides) ',']</td>
			<td>[join $package(requires) ',']</td>
		</tr>"
		incr i
	}
    }
	
    ns_write "
    	</table>
	<p>"

    if {![empty_string_p $errors]} {
	ns_write "The following errors were generated
	<ul>
	    $errors
	</ul>
	"
    }
}    

ns_write "
[ad_footer]
"
