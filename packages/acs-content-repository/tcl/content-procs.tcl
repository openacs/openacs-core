ad_library {

    Functions that the content-repository uses to interact with the 
    file system.

    @author Dan Wickstrom (dcwickstrom@earthlink.net)
    @creation-date Sat May  5 13:45 2001
    @cvs-id $Id$
} 

# The location for files
ad_proc -public cr_fs_path { { location CR_FILES } } {

    Root path of content repository files.

} {
    return [nsv_get CR_LOCATIONS $location]
}

ad_proc -private cr_create_content_file_path {item_id revision_id} {

    Creates a unique file in the content repository file system based off of 
    the item_id and revision_id of the content item.

} {

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

    if {[string index $path end] ne "/" } {
        append path "/"
    }

    return "${path}${revision_id}"
}

# lifted from new-file-storage (DanW - OpenACS)

ad_proc -public cr_create_content_file {
    -move:boolean
    item_id 
    revision_id 
    client_filename
} {
    Copies the file passed by client_filename to the content repository file
    storage area, and it returns the relative file path from the root of the
    content repository file storage area..

    if the -move flag is given the file is renamed instead
} {
    set content_file [cr_create_content_file_path $item_id $revision_id]

    if { $move_p } { 
        file rename -- $client_filename [cr_fs_path]$content_file
    } else { 
        file copy -force -- $client_filename [cr_fs_path]$content_file
    }

    return $content_file
}

ad_proc -public cr_create_content_file_from_string {item_id revision_id str} {

    Copies the string to the content repository file storage area, and it 
    returns the relative file path from the root of the content repository 
    file storage area.

} {

    set content_file [cr_create_content_file_path $item_id $revision_id]
    set ofp [open [cr_fs_path]$content_file w]
    puts -nonewline $ofp $str
    close $ofp

    return $content_file
}

ad_proc -public cr_file_size {relative_file_path} {

    Returns the size of a file stored in the content repository.  Takes the 
    relative file path of the content repository file as an arguement.

} {
    return [file size [cr_fs_path]$relative_file_path]
}
