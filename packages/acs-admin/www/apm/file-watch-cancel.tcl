ad_page_contract {
    Stops watching a particular file or all files if
    no file is specified.
   
    @param watch_file The file to stop watching.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {watch_file ""}
}

doc_body_append "[apm_header "Cancel a Watch"]
"

apm_file_watch_cancel -path $watch_file

if { ![empty_string_p $watch_file] } {
    doc_body_append "No longer watching the following file:<ul><li>$watch_file</ul>"
} else {
    doc_body_append "Canceled all watches"
}


doc_body_append "
<p>
<a href=\"./\">Return to the Package Manager</a>
</p>

[ad_footer]
"
