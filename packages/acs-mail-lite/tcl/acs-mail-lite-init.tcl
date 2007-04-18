ad_library {

    initialization for acs_mail_lite module

    @author Eric Lorenzo (eric@openforce.net)
    @creation-date 22 March, 2002
    @cvs-id $Id$

}

# Default interval is 1 minute.
ad_schedule_proc -thread t 60 acs_mail_lite::sweeper
# Run the complex_sweeper every 180s (3min)
ad_schedule_proc -thread t 180 acs_mail_lite::complex_sweeper 

set queue_dir [parameter::get_from_package_key -parameter "BounceMailDir" -package_key "acs-mail-lite"]

# ad_schedule_proc -thread t 120 acs_mail_lite::load_mails -queue_dir $queue_dir

# check every few minutes for bounces
#ad_schedule_proc -thread t [acs_mail_lite::get_parameter -name BounceScanQueue -default 120] acs_mail_lite::scan_replies

nsv_set acs_mail_lite send_mails_p 0
nsv_set acs_mail_lite check_bounce_p 0

# ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 0 25] acs_mail_lite::check_bounces
