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

