ad_page_contract { 
    
    Generates diffs for a version of a package.
    
    @param version_id The package to be processed.
    @param context_p Set to 0 if you don't want the diffs to be listed with context.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:integer}
    {context_p:boolean 1}
}

db_1row apm_package_by_version_id {}

set analyze_dir [ns_mktemp "[acs_root_dir]/apm-workspace/diffs-XXXXXX"]

doc_body_append "[apm_header "Create Diffs for $pretty_name $version_name"]

<ul><li>Extracting the archive into $analyze_dir...<li>
"
doc_body_flush

apm_extract_tarball $version_id $analyze_dir

doc_body_append "Analyzing files...</ul>\n"
doc_body_flush

set no_changes [list]

foreach file [apm_get_package_files -package_key $package_key] {
    if { ![file isfile "[acs_root_dir]/$file"] } {
	doc_body_append "<h3>$file</h3>\n<blockquote>This file has been locally added.</blockquote>\n"
	continue
    }
    if { ![file isfile "$analyze_dir/$file"] } {
	doc_body_append "<h3>$file</h3>\n<blockquote>This file has been locally removed.</blockquote>\n"
	continue
    }

    if {[set diff [util::which diff]] eq ""} {
        error "'diff' command not found on the system"
    }
    set cmd [list exec $diff]
    if { $context_p } {
	lappend cmd "-c"
    }
    lappend cmd "[acs_root_dir]/$file" $analyze_dir/$file
    set errno [catch $cmd diffs]
    if { $errno == 0 } {
	lappend no_changes $file
    } else {
	set status [lindex $::errorCode 2]
	if { $status == 1 } {
	    regsub {child process exited abnormally$} $diffs "" diffs
	    doc_body_append "<h3>$file</h3>\n<blockquote><pre>[ns_quotehtml $diffs]</pre></blockquote>\n"
	} else {
	    doc_body_append "<h3>$file</h3>\n<blockquote><pre>$diffs</pre></blockquote>\n"
	}
    }
    doc_body_flush
}

if { [llength $no_changes] > 0 } {
    doc_body_append "<h3>No changes to:</h3><ul><li>[join $no_changes "\n<li>"]</ul>\n"
}

doc_body_append [ad_footer]


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
