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
        db_foreach fetch_paths {} {
            set file [cr_fs_path $storage_area_key]/$path
            if {[regexp {^[0-9/]+$} $path]} {
                # the filename looks valid, delete the file from filesystem
                ns_log Debug "cr_delete_scheduled_files: deleting $file"
                file delete -- $file
            } else {
                ns_log Warning "cr_delete_scheduled_files: refuse to delete $file"
            }
        }
        # now that all scheduled files deleted, clear table
        db_dml delete_files {}
    }

    #
    # cleanup orphaned files (leftovers from aborted transactions)
    #
    cr_cleanup_orphaned_files
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

##
## Check for orphans in the content respository directory, and delete
## such files if required.
##
## gustaf.neumann@wu-wien.ac.at
##


ad_proc cr_check_orphaned_files {-delete:boolean {-mtime ""}} { 

    Check for orphaned files in the content respository directory, and
    delete such files if required.  Orphaned files might be created,
    when files are added to the content repository, but the transaction
    is being aborted. This function is intended to be used for one-time
    maintainenace operations. Starting with 5.8.1, OpenACS contains
    support for handling orphaned files much more efficiently via a
    transaction log that is checked via cr_cleanup_orphaned_files in
    cr_delete_scheduled_files.

    @param -delete delete the orphaned files
    @param -mtime same semantics as mtime in the file command
    
} {
    set cr_root [nsv_get CR_LOCATIONS CR_FILES]
    set root_length [string length $cr_root]
    set result ""

    set cmd [list exec find $cr_root/ -type f]
    if {$mtime ne ""} {lappend cmd -mtime $mtime}
    foreach f [split [{*}$cmd] \n] {
        set name [string range $f $root_length end]
        if {![regexp {^[0-9/]+$} $name]} continue

        # For every file in the content respository directory, check if this
        # file is still referenced from the content-revisions.

        set x [cr_count_file_entries $name]
        if {$x > 0} continue
        
        lappend result $f
        if {$delete_p} {
            file delete -- $f
        }
    }
    
    return $result
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
