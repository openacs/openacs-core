ad_page_contract {
    Add files to a package.

    @param version_id       The identifier for the package.
    @param file_index       The files to be added.
    @param processed_files  The paths and types of the files to be added.
    @author Jon Salz (jsalz@arsdigita.com)
    @date 17 April 2000
    @cvs-id file-add-2.tcl,v 1.3 2000/10/18 17:25:38 bquinn Exp
} {
    {version_id:integer}
    {file_index:multiple}
    processed_files
}

db_transaction {
    foreach index $file_index {
	set info [lindex $processed_files $index]
	set index_path [lindex $info 0]
	set file_type [lindex $info 1]
        set db_type [lindex $info 2]
	# Do a doubleclick protection check.
	if { ![db_string apm_file_add_doubleclick_ck {
	    select count(*) from apm_package_files
	    where version_id = :version_id
	    and path = :index_path
	} -default 0] } {
	    apm_file_add $version_id $index_path $file_type $db_type
	}
    }
    apm_package_install_spec $version_id
}

db_release_unused_handles
ad_returnredirect "version-files?version_id=$version_id"

