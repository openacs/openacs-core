ad_page_contract {
    Shows files not contained in any package.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
}

doc_body_append "[apm_header "Unattached Files"]

<ul>
<li>Obtaining a list of all files in packages...<li>
"
doc_body_flush

# Add an item to the all_paths array for every registered file.
foreach path [db_list apm_all_paths {
    select distinct path from apm_package_files
}
    set all_paths($path) 1
}

doc_body_append "
Scanning the filesystem...<li>
"
doc_body_flush

# Obtain a sorted list of every file in the filesystem.
set files [lsort [ad_find_all_files -check_file_func apm_include_file_p [acs_root_dir]]]

doc_body_append "Done.</ul>\n"

if { [llength $files] == 0 } {
    doc_body_append "All files are associated with packages. Woohoo!"
} else {
    doc_body_append "The following files are not associated with packages:\n<blockquote>\n"

    set last_components [list]

    foreach path $files {
	set path [ad_make_relative_path $path]
	if { [info exists all_paths($path)] } {
	    # The file has already been registered.
	    continue
	}
	set components [split $path "/"]

	# Set i to the index of the first component that has changed since the
	# last line we've written out.
	for { set i 0 } { $i < [llength $components] - 1 && $i < [llength $last_components] - 1 } { incr i } {
	    if { [string compare [lindex $components $i] [lindex $last_components $i]] } {
		break
	    }
	}

	# Write out every changed component in the path.
	while { $i < [llength $components] } {
	    for { set j 0 } { $j < $i } { incr j } {
		doc_body_append "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
	    }
	    doc_body_append [lindex $components $i]
	    if { $i < [llength $components] - 1 } {
		# It's not the last component (it's a directory) - append a trailing slash
		doc_body_append "/"
	    }
	    doc_body_append "<br>"
	    incr i
	}
	doc_body_flush
	set last_components $components
    }

    doc_body_append "</blockquote>\n"
}
db_release_unused_handles 
doc_body_append [ad_footer]

