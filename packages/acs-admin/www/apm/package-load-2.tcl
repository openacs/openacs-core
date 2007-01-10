ad_page_contract {
    Loads a package from a URL into the package manager.

    @param url The url of the package to load.
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 10 October 2000
    @cvs-id $Id$

} {
    {url ""}
    {file_path ""}
    {delete 0}
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
    file delete -force [apm_workspace_install_dir]
}

ad_return_top_of_page "[apm_header -form "package-load" [list "package-load" "Load a New Package"] "View Package Contents"]
"

if {$file_path eq ""} {

    if {[string range $url 0 6] eq "http://"} {
	set url [string range $url 7 end]
    }

    ns_write "
<ul>
    <li>Downloading <a href=\"http://$url\">http://$url</a>..."
    if { [catch {
	# Open a destination file.
	set file_path [ns_tmpnam].apm
	set fileChan [open $file_path w+ 0600]
	# Open the channel to the server.
	set httpChan [lindex [ns_httpopen GET "http://$url"] 0]
	ns_log Debug "APM: Copying data from $url"
	# Copy the data
	fcopy $httpChan $fileChan
	# Clean up.
	ns_log Debug "APM: Done copying data."
	close $httpChan
	close $fileChan
    } errmsg] } {
	ns_write "Unable to download. Please check your URL.</ul>.
	The following error was returned: <blockquote><pre>[ad_quotehtml $errmsg]
	</pre></blockquote>[ad_footer]"
	return
    }	
    
} else {
    ns_write "
    Accessing $file_path...
    <p>
    <ul>
    "
}
ns_log Debug "APM: Loading $file_path"
# If file_path ends in .apm, then load the single package.
if { ![string compare [string range $file_path [expr {[string length $file_path] -3}] end] "apm"] } {
    apm_load_apm_file -callback apm_ns_write_callback $file_path
} else {
    # See if this is a directory.
    if { [file isdirectory $file_path] } {
	#Find all the .APM and load them.
	set apm_file_list [glob -nocomplain "$file_path/*.apm"] 
	if {$apm_file_list eq ""} {
	    ns_write "The directory specified, <code>$file_path</code>, does not contain any APM files.  Please <a href=\"package-load\">try again</a>.[ad_footer]"
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
	entering a new file path.[ad_footer]"
	return
    }
}

ns_write "
</ul>
The package(s) are now extracted into your filesystem.  You can <a href=\"package-load\">load 
another new package</a> from a URL or proceed to <a href=\"packages-install\">install</a> the package(s).

[ad_footer]
"
