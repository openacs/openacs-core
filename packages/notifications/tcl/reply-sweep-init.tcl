ad_library {

    notifications reply init - sets up scheduled procs

    @cvs-id $Id$
    @author Ben Adida (ben@openforce)
    @date 2002-05-27

}

ad_schedule_proc -thread t 60 notification::reply::sweep::scan_all_replies
ad_schedule_proc -thread t 60 notification::reply::sweep::process_all_replies

