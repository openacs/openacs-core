template::filter add content::init

# a patch to the cr for handling the deleting revision's files
# when the revision has been deleted from the database
# schedules the sweep
#
# Walter McGinnis (wtem@olywa.net), 2001-09-23
# based on original photo-album package code by Tom Baginski

# Daveb: unless someone has a good reason this should go away for OpenACS 5.1
# we should promote a Tcl api to the cr instead of each package accessing
# the pl/sql procs directly. 

ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 22 0] cr_delete_scheduled_files

ad_proc -public acs_cr_scheduled_release_exec {} {

    This was handled by oracle, but since other dbs, such as postgresql don't 
    support job submission, the job scheduling has been moved to aolserver.
    (OpenACS - DanW)

} {

    db_exec_plsql schedule_releases {}
}

ad_schedule_proc [expr {15 * 60}] acs_cr_scheduled_release_exec
nsv_set CR_LOCATIONS . ""

if {![nsv_exists CR_LOCATIONS CR_FILES]} {
    
    # Take the directory from the FileLocation parameter that 
    # must be specified in acs-content-repository package.
    set relativepath_p [parameter::get_from_package_key -package_key "acs-content-repository" -parameter FileLocationRelativeP -default "1"]
    set file_location ""

    if {$relativepath_p} {
	# The file location is relative to $::acs::rootdir
	set file_location $::acs::rootdir/
    }
    append file_location [parameter::get_from_package_key -package_key "acs-content-repository" -parameter "CRFileLocationRoot" -default "content-repository-content-files"]
    
    nsv_set CR_LOCATIONS CR_FILES "$file_location"

}


##
## At boot time, we should scan AOLserver mime types and insert them if they're
## not there already. (ben@openforce)
##

cr_scan_mime_types

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
