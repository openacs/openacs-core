ad_page_contract {
    Loads a package from a URL into the package manager.

    @param url The url of the package to load.
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 10 October 2000
    @cvs-id $Id$

} {
    {url ""}
    {file_path ""}
    {delete:boolean 0}
} -validate {
    
    url_xor_file_path {
	if {($url eq "" && $file_path eq "") ||
	($url ne "" && $file_path ne "") } {
	    ad_complain
	}
    }

} -errors {
    url_xor_file_path {You must specify either a URL to download or a file path, but not both.}
}

if {$delete} {
    file delete -force -- [apm_workspace_install_dir]
}

set title "Contents of Loaded Package"
set context [list [list "." "Package Manager"] [list "package-load" "Load a New Package"] $title]

ad_return_top_of_page [ad_parse_template \
                           -params [list context title] \
                           [template::streaming_template]]

if {$file_path eq ""} {
    #
    # delete potential leading "http://"
    #
    if {[string range $url 0 6] eq "http://"} {
	set url [string range $url 7 end]
    }
    ns_write "<ul>"
    set url_param "-url http://$url"
   
} else {
    ns_write "
    Accessing $file_path...
    <p>
    <ul>
    "
    set url_param ""
}
ns_log Debug "APM: Loading $file_path"

# If file_path ends in .apm, then load the single package.
if { [file extension $file_path] eq ".apm" || $url_param ne ""} {
    apm_load_apm_file {*}$url_param -callback apm_ns_write_callback $file_path
} else {
    # See if this is a directory.
    if { [file isdirectory $file_path] } {
	#Find all the .APM and load them.
	set apm_file_list [glob -nocomplain "$file_path/*.apm"] 
	if {$apm_file_list eq ""} {
	    ns_write [subst {
		The directory specified, <code>$file_path</code>, does not contain any APM files.  
		Please <a href="package-load">try again</a>
	    }]
	    return
	} else {
	    foreach apm_file $apm_file_list {
		ns_write "Loading $apm_file... <ul>"
		apm_load_apm_file -callback apm_ns_write_callback $apm_file
		ns_write "<li>Done.</ul><p>"
	    }
	}
    } else {
	# Not sure what to do... stop.
	ns_write "The specified file path is not an APM file or a directory.  Please try
	entering a new file path."
	return
    }
}

ns_write [subst {
</ul>
The package(s) are now extracted into your filesystem.  You can <a href="package-load">load 
another new package</a> from a URL or proceed to <a href="packages-install">install</a> the package(s).
}]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
