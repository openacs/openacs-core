ad_page_contract {
    Stops watching a particular file.
   
    @param watch_file The file to stop watching.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id $Id$
} {
    watch_file
}

doc_body_append "[apm_header "Cancel a Watch"]
"

catch { nsv_unset apm_reload_watch $watch_file }

doc_body_append "No longer watching the following file:<ul><li>$watch_file</ul>

<a href=\"./\">Return to the Package Manager</a>

[ad_footer]
"

