ad_library {

    initialization for acs_mail_lite module

    @author Eric Lorenzo (eric@openforce.net)
    @creation-date 22 March, 2002
    @cvs-id $Id$

}

# Default interval is 1 minute.
ad_schedule_proc -thread t 60 acs_mail_lite::sweeper
