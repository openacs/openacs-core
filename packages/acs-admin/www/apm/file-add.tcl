ad_page_contract {
    Allows the user to add files to a package.
    @param version_id The identifier for the package.
    @author Jon Salz (jsalz@arsdigita.com)
    @date 17 April 2000
    @cvs-id file-add.tcl,v 1.4 2000/10/12 00:48:48 bquinn Exp    
} {
    {version_id:integer}
}

apm_version_info $version_id

doc_body_append "[apm_header -form "method=post action=\"file-add-2\"" [list "version-view?version_id=$version_id" "$pretty_name $version_name"] [list "version-files?version_id=$version_id" "Files"] "Add Files"]

[export_form_vars version_id]

<blockquote>
<table cellspacing=0 cellpadding=0>
"

doc_body_flush

# Obtain a list of all files registered to the package already.
array set registered_files [list]
foreach file [db_list apm_file_paths {
    select path from apm_package_files where version_id = :version_id
}] {
    set registered_files($file) 1
}

db_release_unused_handles

# processed_files is a list of sublists, each of which contains
# the path of a file and its file type.
set processed_files [list]
set counter 0

foreach file [lsort [ad_find_all_files -check_file_func apm_include_file_p [acs_package_root_dir $package_key]]] {
    set relative_path [ad_make_relative_path $file]

    # Now kill "packages" and the package_key from the path.
    set components [split $relative_path "/"]
    set relative_path [join [lrange $components 2 [llength $components]] "/"]

    if { [info exists registered_files($relative_path)] } {
	doc_body_append "<tr><td></td><td>$relative_path (already registered to this package)</td></tr>\n"
    } else {
	set type [apm_guess_file_type $package_key $relative_path]
	set db_type [apm_guess_db_type $package_key $relative_path]
	doc_body_append "<tr><td><input type=checkbox name=file_index value=[llength $processed_files] checked>&nbsp;</td><td><b>$relative_path</b>: [apm_pretty_name_for_file_type $type]"
        if { ![empty_string_p $db_type] } {
            doc_body_append " ([apm_pretty_name_for_db_type $db_type])"
        }
        doc_body_append "</td></tr>\n"
	lappend processed_files [list $relative_path $type $db_type]
    }
    incr counter
}

db_release_unused_handles

# Transport the list of files to the next page.
doc_body_append [export_form_vars processed_files]

if { $counter == 0 } {
    doc_body_append "<tr><td colspan=2>There are no files in the <tt>packages/$package_key</tt> directory.</td></tr></table></blockquote>"
} elseif { [llength $processed_files] > 0 } {
    doc_body_append "</table></blockquote>
<script language=javascript>
function uncheckAll() {
    for (var i = 0; i < [llength $processed_files]; ++i)
        document.forms\[0\].file_index\[i\].checked = false;
}
function checkAll() {
    for (var i = 0; i < [llength $processed_files]; ++i)
        document.forms\[0\].file_index\[i\].checked = true;
}
</script>
<blockquote>
\[ <a href=\"javascript:checkAll()\">check all</a> |
<a href=\"javascript:uncheckAll()\">uncheck all</a> \]
</blockquote>

<center>
<input type=submit value=\"Add Checked Files\">
"
} else {
    doc_body_append "<tr><td colspan=2><br>There are no additional files to add to the package.</td></tr></table></blockquote>"
}

doc_body_append "</center>\n[ad_footer]\n"

