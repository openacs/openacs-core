ad_page_contract { 
    List all the files in a particular version of a package.

    @param version_id The package to be processed.
    @param remove_files_p Set to 1 if you want to remove all the files. 
    @author Jon Salz [jsalz@arsdigita.com]
    @date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:integer}
    {remove_files_p 0}
}

db_1row apm_package_by_version_id {
	select pretty_name, version_name, package_key, installed_p, distribution_uri,
	tagged_p
	from apm_package_version_info where version_id = :version_id
}

if { $remove_files_p == 1 } {
    # This is really a "remove multiple files" page.
    set form "action=\"file-remove.tcl\" method=post"
    set apm_header_args [list [list "version-files?version_id=$version_id" "Files"] "Remove Files"]
} else {
    set form ""
    set apm_header_args [list "Files"]
}

doc_body_append "[eval [concat [list apm_header -form $form [list "version-view?version_id=$version_id" "$pretty_name $version_name"]] $apm_header_args]]
"

doc_body_append "

<blockquote>
<table cellspacing=0 cellpadding=0>
"
doc_body_flush

set last_components [list]
set counter 0

doc_body_append "<tr><th align=left>Path</th><th width=40></th><th align=left>File type</th><th width=40></th>
                 <th align=left>Database support</th><th width=40></th><th align=left>Actions</th></tr>\n"

db_foreach apm_all_files {
    select f.file_id, f.path, f.file_type, nvl(t.pretty_name, 'Unknown type') file_pretty_name,
           f.db_type, nvl(d.pretty_db_name, 'All') as db_pretty_name
    from   apm_package_files f, apm_package_file_types t, apm_package_db_types d
    where  f.version_id = :version_id
    and    f.file_type = t.file_type_key(+)
    and    f.db_type = d.db_type_key(+)
    order by path
} {
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
	    if { $remove_files_p == 1 } {
		# Display a checkbox which the user can check to delete the file.
		doc_body_append "<td><input type=checkbox name=file_id value=$file_id></td>"
	    } else {
		if { $installed_p == "t" } {
		    if { $file_type == "tcl_procs" || ($file_type == "query_file" && [db_compatible_rdbms_p $db_type]) } {
			if { [nsv_exists apm_reload_watch "packages/$package_key/$path"] } {
			    # This procs file is already being watched.
			    doc_body_append "<td>&nbsp;watch&nbsp;</td>"
			} else {
			    if {![ad_parameter -package_id [ad_acs_kernel_id] \
				    PerformanceModeP request-processor 1]} {
				# Provide a link to watch the procs file.
				doc_body_append "<td>&nbsp;<a href=\"file-watch?file_id=$file_id\">watch</a>&nbsp;</td>"
			    } else {
				doc_body_append "<td></td>"
			    }
			}
		    } else {
			doc_body_append "<td></td>"
		    }
		}
		# Allow the user to remove the file from the package.
		doc_body_append "<td><a href=\"javascript:if(confirm('Are you sure you want to remove this file from the package?\\nDoing so will not remove it from the filesystem.'))location.href='file-remove?[export_url_vars version_id file_id]'\">remove</a></td>"
	    }		
	}
	doc_body_append "</tr>\n"
	incr i
    }
    set last_components $components
} else {
    doc_body_append "<tr><td>This package does not contain any registered files.</td></tr>\n"
}

if { $counter > 0 && $remove_files_p == 1 } {
    doc_body_append "<tr><td colspan=3></td><td colspan=2>
[export_form_vars version_id]
<input type=button value=\"Remove Checked Files\" onClick=\"javascript:if(confirm('Are you sure you want to remove these files from the package?\\nDoing so will not remove them from the filesystem.'))form.submit()\"></td>"
}

doc_body_append "
</table>
</blockquote>
"

if { $remove_files_p } {
    doc_body_append "<ul><li><a href=\"version-files?version_id=$version_id\">Cancel the removal of files</a></ul>\n"
} else {
    if { $installed_p == "t" } {
	doc_body_append "<ul>
<li><a href=\"file-add?version_id=$version_id\">Scan the <tt>packages/$package_key</tt> directory for additional files in this package</a>
<li><a href=\"version-files?version_id=$version_id&remove_files_p=1\">Remove several files from this package</a>
"

        if { [info exists stricken_files] } {
	    foreach file_id $stricken_files {
		lappend stricken_file_query "file_id=$file_id"
	    }
	    doc_body_append "<li><a href=\"file-remove?[export_url_vars version_id]&[join $stricken_file_query "&"]\">Remove nonexistent (crossed-out) files</a>\n"
	}

        if { [empty_string_p $distribution_uri] } {
	    doc_body_append "
	<p>
	<!--li><a href=\"version-tag?version_id=$version_id\">Create a CVS tag for this version in each file</a-->
"
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
}

doc_body_append [ad_footer]

