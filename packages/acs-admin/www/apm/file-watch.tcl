ad_page_contract {
    Schedules a file to be watched.

    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    version_id:integer
    paths:multiple
} 

apm_version_info $version_id

set count 0
foreach path $paths {
    incr count

    apm_file_watch "packages/$package_key/$path"

    lappend path_list $path
}

doc_body_append "[apm_header -form "method=post action=\"file-add-2\"" [list "version-view?version_id=$version_id" "$pretty_name $version_name"] [list "version-files?version_id=$version_id" "Files"] "Watch file"]"


doc_body_append "Marking the following files to be watched:<ul><li>[join $path_list "<li>"]</ul>

<a href=\"version-files?version_id=$version_id\">Return to the list of files for $pretty_name $version_name</a><br>
<a href=\"./\">Return to the Package Manager</a>

[ad_footer]
"

