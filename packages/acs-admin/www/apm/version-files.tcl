ad_page_contract { 
    List all the files in a particular version of a package.

    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:integer}
}

apm_version_info $version_id

set form ""
set apm_header_args [list "Files"]

doc_body_append "[eval [concat [list apm_header -form $form [list "version-view?version_id=$version_id" "$pretty_name $version_name"]] $apm_header_args]]"

doc_body_append "

<blockquote>
<table cellspacing=0 cellpadding=0>
"
doc_body_flush

set last_components [list]
set counter 0

doc_body_append "<tr><th align=left>Path</th><th width=40></th><th align=left>File type</th><th width=40></th>
                 <th align=left>Database support</th><th width=40></th></tr>\n"

foreach path [apm_get_package_files -package_key $package_key] {
    set file_id ""
    set db_type [apm_guess_db_type $package_key $path]
    set db_pretty_name $db_type
    set file_type [apm_guess_file_type $package_key $path]
    if { [empty_string_p $file_type] } {
        set file_type "?"
    }
    set file_pretty_name $file_type

    incr counter

    # Set i to the index of the last component which hasn't changed since the last component
    # we wrote out.
    set components [split $path "/"]
    for { set i 0 } { $i < [llength $components] - 1 && $i < [llength $last_components] - 1 } { incr i } {
	if { [string compare [lindex $components $i] [lindex $last_components $i]] } {
	    break
	}
    }

    # For every changed component (at least the file name), write a row in the table.
    while { $i < [llength $components] } {
	doc_body_append "<tr><td>"
	for { set j 0 } { $j < $i } { incr j } {
	    doc_body_append "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
	}
	if { $installed_p == "f" || [file exists "[acs_package_root_dir $package_key]/$path"] || $i < [llength $components] - 1} { 
	    # Either we're not looking at an installed package, or the file still exists,
	    # so don't use <strike> when writing the name.
	    doc_body_append [lindex $components $i]
	} else {
	    # This is an installed package, and a file has been removed from the filesystem.
	    # Use <strike> to indicate that the file has been deleted.
	    doc_body_append "<strike>[lindex $components $i]</strike>"
	    if { $i == [llength $components] - 1 } {
		lappend stricken_files $file_id
	    }
	}
	if { $i < [llength $components] - 1 } {
	    doc_body_append "/</td>"
	} else {
	    doc_body_append "</td>"
	    doc_body_append "<td width=40>&nbsp;</td><td>$file_pretty_name</td><td width=40>&nbsp</td><td>$db_pretty_name</td>
                             <td width=40>&nbsp;</td>"

		if { $installed_p == "t" } {
		    if { $file_type == "tcl_procs" || ($file_type == "query_file" && [db_compatible_rdbms_p $db_type]) } {
			if { [nsv_exists apm_reload_watch "packages/$package_key/$path"] } {
			    # This procs file is already being watched.
			    doc_body_append "<td>&nbsp;watch&nbsp;</td>"
			} else {
			    if {![ad_parameter -package_id [ad_acs_kernel_id] \
				    PerformanceModeP request-processor 1]} {
				# Provide a link to watch the procs file.
				doc_body_append "<td>&nbsp;<a href=\"file-watch?version_id=$version_id&paths=$path\">watch</a>&nbsp;</td>"
			    } else {
				doc_body_append "<td></td>"
			    }
			}
		    } else {
			doc_body_append "<td></td>"
		    }

                }
	}
	doc_body_append "</tr>\n"
	incr i
    }
    set last_components $components
} 

if { [string equal $counter 0] } {
    doc_body_append "<tr><td>This package does not contain any registered files.</td></tr>\n"
}

doc_body_append "</table>
</blockquote>
"

if { $installed_p == "t" } {
    doc_body_append "<ul>
    <li><a href=\"package-watch?package_key=$package_key\">watch all files</a></li>"

    if { [empty_string_p $distribution_uri] } {
        doc_body_append "
    <p>
    <!--li><a href=\"version-tag?version_id=$version_id\">Create a CVS tag for this version in each file</a-->"

    }

    if {$tagged_p == "t"} {
        doc_body_append "
        <li><a href=\"archive/[file tail $version_uri]?version_id=$version_id\">Download a tarball from the package archive</a>"
    }

    doc_body_append "</ul>"

} elseif { [info exists tagged_p] } {
    if { $tagged_p == "t" } {
        doc_body_append "<ul>
        <li><a href=\"archive/[file tail $version_uri]?version_id=$version_id\">Download a tarball from the package archive</a>
        </ul>
        "
    }
}

doc_body_append [ad_footer]
