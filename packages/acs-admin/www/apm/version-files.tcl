ad_page_contract { 
    List all the files in a particular version of a package.

    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:integer}
}

apm_version_info $version_id

set return_url "[ad_conn url]?[ad_conn query]"

set page_title "Files"
set context [list [list "../developer" "Developer's Administration"] [list "/acs-admin/apm/" "Package Manager"] [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] $page_title]

append body "

<blockquote>
<table cellspacing=0 cellpadding=0>
"
doc_body_flush

set last_components [list]
set counter 0

append body "<tr><th align=left>Path</th><th width=40></th><th align=left>File type</th><th width=40></th>
                 <th align=left>Database support</th><th width=40></th></tr>\n"

foreach path [apm_get_package_files -package_key $package_key] {
    set file_id ""
    set db_type [apm_guess_db_type $package_key $path]
    set db_pretty_name $db_type
    set file_type [apm_guess_file_type $package_key $path]
    if { $file_type eq "" } {
        set file_type "?"
    }
    set file_pretty_name $file_type

    incr counter

    # Set i to the index of the last component which hasn't changed since the last component
    # we wrote out.
    set components [split $path "/"]
    for { set i 0 } { $i < [llength $components] - 1 && $i < [llength $last_components] - 1 } { incr i } {
	if {[lindex $components $i] ne [lindex $last_components $i]  } {
	    break
	}
    }

    # For every changed component (at least the file name), write a row in the table.
    while { $i < [llength $components] } {
	append body "<tr><td>"
	for { set j 0 } { $j < $i } { incr j } {
	    append body "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
	}
	if { $installed_p eq "f" || [file exists "[acs_package_root_dir $package_key]/$path"] || $i < [llength $components] - 1} { 
	    # Either we're not looking at an installed package, or the file still exists,
	    # so don't use <strike> when writing the name.
	    append body [lindex $components $i]
	} else {
	    # This is an installed package, and a file has been removed from the filesystem.
	    # Use <strike> to indicate that the file has been deleted.
	    append body "<strike>[lindex $components $i]</strike>"
	    if { $i == [llength $components] - 1 } {
		lappend stricken_files $file_id
	    }
	}
	if { $i < [llength $components] - 1 } {
	    append body "/</td>"
	} else {
	    append body "</td>"
	    append body "<td width=40>&nbsp;</td><td>$file_pretty_name</td><td width=40>&nbsp</td><td>$db_pretty_name</td>
                             <td width=40>&nbsp;</td>"

		if { $installed_p eq "t" } {
                    set server_rel_path "packages/$package_key/$path"
		    if { [apm_file_watchable_p $server_rel_path] } {
			if { [nsv_exists apm_reload_watch $server_rel_path] } {
			    # This procs file is already being watched.
			    append body "<td>&nbsp;being watched&nbsp;</td>"
			} else {
			    if {![parameter::get -package_id [ad_acs_kernel_id] \
                                      -parameter PerformanceModeP -default 1]} {
				# Provide a link to watch the procs file.
				append body "<td>&nbsp;<a href=\"file-watch?[export_vars -url {version_id {paths $path} return_url}]\">watch</a>&nbsp;</td>"
			    } else {
				append body "<td></td>"
			    }
			}
		    } else {
			append body "<td></td>"
		    }

                }
	}
	append body "</tr>\n"
	incr i
    }
    set last_components $components
} 

if {$counter eq "0"} {
    append body "<tr><td>This package does not contain any registered files.</td></tr>\n"
}

append body "</table>
</blockquote>
"

if { $installed_p eq "t" } {
    append body "<ul>
    <li><a href=\"package-watch?[export_vars -url {package_key return_url}]\">watch all files</a></li>
<li><a href=\"package-watch-cancel?[export_vars -url {package_key return_url}]\">cancel all watches</a></li>"

    if { $distribution_uri eq "" } {
        append body "
    <p>
    <!--li><a href=\"version-tag?version_id=$version_id\">Create a CVS tag for this version in each file</a-->"

    }

    if {$tagged_p eq "t"} {
        append body "
        <li><a href=\"archive/[file tail $version_uri]?version_id=$version_id\">Download a tarball from the package archive</a>"
    }

    append body "</ul>"

} elseif { [info exists tagged_p] } {
    if { $tagged_p eq "t" } {
        append body "<ul>
        <li><a href=\"archive/[file tail $version_uri]?version_id=$version_id\">Download a tarball from the package archive</a>
        </ul>
        "
    }
}


