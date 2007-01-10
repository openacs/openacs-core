# tcl/acs-content-repository-procs.tcl patch
#
# a patch to the cr for handling the deleting revision's files
# when the revision has been deleted from the database
#
# Walter McGinnis (wtem@olywa.net), 2001-09-23
# based on original photo-album package code by Tom Baginski
#
# JCD 2002-12-96 This should be fixed since on oracle anyway, being in a
# transaction does not mean that you get read level consistency across
# queries.  End result is that someone can do an insert into the
# delete list and the delete_files query will whack it and the file
# will then never be deleted.  Oops.


ad_proc -private cr_delete_scheduled_files {} {
    Tries to delete all the files in cr_files_to_delete.  Makes sure
    file isn't being used by another revision prior to deleting it.
    Should be scheduled daily.

    This proc is extremely simple, and does not have any concurrancy
    checks to make sure another version of the proc is
    running/deleting a file.  Will add some concurancy checks to a
    future revision.  Right now go with short and sweet, count on
    scheduling to prevent conflicts
} {
     db_transaction {
	# subselect makes sure there isn't a parent revision still lying around
         db_foreach fetch_paths { *SQL* } {

             # try to remove file from filesystem
             set file "[cr_fs_path $storage_area_key]/${path}"
             ns_log Debug "cr_delete_scheduled_files: deleting $file"
             ns_unlink  -nocomplain "$file"
         }
         # now that all scheduled files deleted, clear table
         db_dml delete_files { *SQL* }
    }
}



##
## Scan AOLserver mime types and insert them into cr_mime_types
##
## ben@openforce
##

ad_proc -private cr_scan_mime_types {} {
    # Get the config file ns_set
    set mime_types [ns_configsection "ns/mimetypes"]
    if {$mime_types ne ""} { 
        set n_mime_types [ns_set size $mime_types]

        for {set i 0} {$i < $n_mime_types} {incr i} {
            set extension [ns_set key $mime_types $i]
            set mime_type [ns_set value $mime_types $i]
            
            # special case
            if {$extension eq "NoExtension" || $extension eq "Default"} {
                continue
            }

            ns_log Notice "cr_scan_mime_types: inserting MIME TYPE - $extension maps to $mime_type"
            # Insert the mime type
            db_dml insert_mime_type {}
        }
    }
}
