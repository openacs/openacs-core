ad_page_contract { 
    Marks all changed -procs.tcl files in a version for reloading.

    @param version_id The package to be processed.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:integer}
    {return_url "index"}
}

apm_version_info $version_id

set page_title "Reload $pretty_name"
set context [list [list "../developer" "Developer's Administration"] [list "/acs-admin/apm/" "Package Manager"] [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] $page_title]

# files in $files.
apm_mark_version_for_reload $version_id files

set files_to_watch [list]

if { [llength $files] == 0 } {
    append body "There are no changed files to reload in this package.<p>"
} else {
    append body "Marked the following file[ad_decode [llength $files] 1 "" "s"] for reloading:<ul>\n"
    foreach file $files {
	append body "<li>$file"
	if { [nsv_exists apm_reload_watch $file] } {
	    append body " (currently being watched)"
	} else {
	    # This file isn't being watched right now - provide a link setting a watch on it.
	    set files_to_watch_p 1

            # Remove the two first elements of the path, namely packages/package-key/
            set local_path [eval [concat file join [lrange [file split $file] 2 end]]]

	    append body " (<a href=\"file-watch?[export_vars { version_id { paths $local_path } }]\">watch this file</a>)"
            lappend files_to_watch $local_path
	}
	append body "\n"
    }
    append body "</ul>\n"
}


if { [info exists files_to_watch_p] } {
    append body "If you know you're going to be modifying one of the above files frequently,
    select the \"watch this file\" link next to a filename to cause the interpreters to
    reload the file immediately whenever it is changed.<p>
    <ul class=\"action-links\">
    <li><a href=\"file-watch?[export_vars { version_id { paths:multiple $files_to_watch } }]\">Watch all above files</a></li>"
} else {
    append body "<ul class=\"action-links\">"
}

append body "
<li><a href=\"$return_url\">Return</a></li>
</ul>"

