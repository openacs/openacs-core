ad_page_contract { 
    Scans the filesystem, adding files to the apm_package_files table.
    
    @param version_id The id of the package to process.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:integer}
}

db_1row apm_package_info {
    select p.package_key, p.package_url, v.package_name, v.version_name, v.package_id
    from   apm_packages p, apm_package_versions v
    where  v.version_id = :version_id
    and    v.package_id = p.package_id
}

# A callback to simply print out a bulleted item to the connection.
proc apm_version_fs_scan_callback { path status } {
    doc_body_append "<li>$path - $status\n"
}

doc_body_append "[apm_header [list "version-view?version_id=$version_id" "$package_name $version_name"] [list "version-files?version_id=$version_id" "Files"] "Scan Filesystem"]
<ul>
"

apm_package_scan_fs -callback apm_version_fs_scan_callback $version_id

doc_body_append "
</ul>

<a href=\"version-files?version_id=$version_id\">Return to the Package Manager</a>

[ad_footer]
"

