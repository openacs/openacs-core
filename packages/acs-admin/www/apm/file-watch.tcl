ad_page_contract {
    Schedules a file to be watched.


    @param file_id The id of the file to watch.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id $Id$
} {
    file_id:integer
} -validate {
    valid_version_id {
	set version_id [apm_version_from_file $file_id]
	if {$version_id == 0} {
	    ad_complain
	}
    }
} -errors {
    valid_version_id {The file you have requested is not registerd.}
}


db_1row apm_get_file_to_watch {
    select t.package_key,  t.pretty_name, 
           v.version_name, v.package_key, v.installed_p, 
           f.path, f.version_id
    from   apm_package_types t, apm_package_versions v, apm_package_files f
    where  f.file_id = :file_id
    and    f.version_id = v.version_id
    and    v.package_key = t.package_key
}

# Why did we need all that information? -KS

doc_body_append "[apm_header -form "method=post action=\"file-add-2.tcl\"" [list "version-view?version_id=$version_id" "$pretty_name $version_name"] [list "version-files?version_id=$version_id" "Files"] "Watch file"]

"

db_1row apm_get_path_from_file_id {
    select path from apm_package_files where file_id = :file_id
}

apm_file_watch "packages/$package_key/$path"

doc_body_append "Marking the following file to be watched:<ul><li>$path</ul>

<a href=\"version-files?version_id=$version_id\">Return to the list of files for $pretty_name $version_name</a><br>
<a href=\".\">Return to the Package Manager</a>

[ad_footer]
"

