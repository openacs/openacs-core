template::filter add content::init

ad_proc -public acs_cr_scheduled_release_exec {} {

    This was handled by oracle, but since other dbs, such as postgresql don't 
    support job submission, the job scheduling has been moved to aolserver.
    (OpenACS - DanW)

} {

    db_exec_plsql schedule_releases {begin cr_scheduled_release_exec; end;}
}

ad_schedule_proc [expr 15 * 60] acs_cr_scheduled_release_exec
