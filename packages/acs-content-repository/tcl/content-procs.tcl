# The location for files
proc cr_fs_path {} {
    return "[file dirname [string trimright [ns_info tcllib] "/"]]/content-repository-content-files"
}

# This will generate the filename and set up the directory to it, too.
# This needs to scale to lots of files, and the location doesn't have to 
# be meaningful.

# lifted from new-file-storage (DanW - OpenACS)

proc cr_create_content_file { item_id revision_id client_filename } {

    # Split out the version_id by groups of 2.
    set item_id_length [string length $item_id]
    set path "/"
    
    for {set i 0} {$i < $item_id_length} {incr i} {
	append path [string range $item_id $i $i]
	if {($i % 2) == 1} {
	    if {$i < $item_id_length} {
		# Check that the directory exists
		if {![file exists [cr_fs_path]$path]} {
		    ns_mkdir [cr_fs_path]$path
		}

		append path "/"
	    }
	}
    }

    # Check that the directory exists
    if {![file exists [cr_fs_path]$path]} {
	ns_mkdir [cr_fs_path]$path
    }

    if {![string equal [string index $path end] "/"]} {
        append path "/"
    }

    ns_log Notice "path = $path, revision_id = $revision_id"

    set content_file "${path}${revision_id}"
    set ifp [open $client_filename r]
    set ofp [open [cr_fs_path]$content_file w]

    ns_cpfp $ifp $ofp
    close $ifp
    close $ofp

    return $content_file
}
