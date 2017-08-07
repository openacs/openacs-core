ad_library {

    Utility routines needed by the bootstrapping process.

    @creation-date 4 Apr 2001
    @author Don Baccus (dhogaza@pacifier.com
    @cvs-id $Id$
}

ad_proc -public ad_find_all_files {
    {-include_dirs 0}
    {-include_bak_dirs 0}
    {-max_depth 10}
    {-check_file_func ""}
    path
} {

    Returns a list of full paths to all files under $path in the
    directory tree (descending the tree to a depth of up to
    $max_depth).  Clients should not depend on the order of files
    returned.

    Per default, the contents of .bak directories (as produced
    e.g. via "install from repository" are not included. To include
    these, add the flag "-include_bak_dirs 1" to the invocation.

} {
    # Use the examined_files array to track files that we've examined.
    array set examined_files [list]

    # A list of files that we will return (in the order in which we
    # examined them).
    set files [list]

    # A list of files that we still need to examine.
    set files_to_examine [list $path]

    # Perform a breadth-first search of the file tree. For each level,
    # examine files in $files_to_examine; if we encounter any directories,
    # add contained files to $new_files_to_examine (which will become
    # $files_to_examine in the next iteration).
    while { [incr max_depth -1] > 0 && [llength $files_to_examine] != 0 } {
	set new_files_to_examine [list]
	foreach file $files_to_examine {
	    # Only examine the file if we haven't already. (This is just a safeguard
	    # in case, e.g., Tcl decides to play funny games with symbolic links so
	    # we end up encountering the same file twice.)
	    if { ![info exists examined_files($file)] } {
		# Remember that we've examined the file.
		set examined_files($file) 1

		if { $check_file_func eq "" || [$check_file_func $file] } {
		    # If it's a file, add to our list. If it's a
		    # directory, add its contents to our list of files to
		    # examine next time.
		    if { [file isfile $file] } {
			lappend files $file
		    } elseif { [file isdirectory $file] } {
                        if { $include_bak_dirs && [string match "*.bak" $file] } {
                            continue
                        }
                        if { $include_dirs == 1 } {
                            lappend files $file
                        }
			lappend new_files_to_examine {*}[glob -nocomplain "$file/*"]
		    }
		}
	    }
	}
	set files_to_examine $new_files_to_examine
    }
    return $files
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
