ad_page_contract { 
    Marks all changed -procs.tcl files in a version for reloading.

    @param version_id The package to be processed.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:integer}
}

doc_body_append "[apm_header "Reload a Package"]
"

# files in $files.
apm_mark_version_for_reload $version_id files

set files_to_watch [list]

if { [llength $files] == 0 } {
    doc_body_append "There are no changed files to reload in this package.<p>"
} else {
    doc_body_append "Marked the following file[ad_decode [llength $files] 1 "" "s"] for reloading:<ul>\n"
    foreach file $files {
	doc_body_append "<li>$file"
	if { [nsv_exists apm_reload_watch $file] } {
	    doc_body_append " (currently being watched)"
	} else {
	    # This file isn't being watched right now - provide a link setting a watch on it.
	    set files_to_watch_p 1

            # Remove the two first elements of the path, namely packages/package-key/
            set local_path [eval [concat file join [lrange [file split $file] 2 end]]]

	    doc_body_append " (<a href=\"file-watch?[export_vars { version_id { paths $local_path } }]\">watch this file</a>)"
            lappend files_to_watch $file
	}
	doc_body_append "\n"
    }
    doc_body_append "</ul>\n"
}

if { [info exists files_to_watch_p] } {
    doc_body_append "If you know you're going to be modifying one of the above files frequently,
    select the \"watch this file\" link next to a filename to cause the interpreters to
    reload the file immediately whenever it is changed.<p>
    (<a href=\"file-watch?[export_vars { version_id { paths:multiple $files_to_watch } }]\">watch all above files</a>)
    <p>
"
}

doc_body_append "
<a href=\"index\">Return to the Package Manager</a>
[ad_footer]
"
