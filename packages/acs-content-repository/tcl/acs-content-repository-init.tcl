template::filter add content::init

# a patch to the cr for handling the deleting revision's files
# when the revision has been deleted from the database
# schedules the sweep
#
# Walter McGinnis (wtem@olywa.net), 2001-09-23
# based on original photo-album package code by Tom Baginski

ad_schedule_proc -thread t 86400 cr_delete_scheduled_files

ad_proc -public acs_cr_scheduled_release_exec {} {

    This was handled by oracle, but since other dbs, such as postgresql don't 
    support job submission, the job scheduling has been moved to aolserver.
    (OpenACS - DanW)

} {

    db_exec_plsql schedule_releases {begin cr_scheduled_release_exec; end;}
}

ad_schedule_proc [expr 15 * 60] acs_cr_scheduled_release_exec

nsv_set CR_LOCATIONS . ""
if ![nsv_exists CR_LOCATIONS CR_FILES] {

    nsv_set CR_LOCATIONS CR_FILES "[file dirname [string trimright [ns_info tcllib] "/"]]/content-repository-content-files"

}
