ad_library {

    initialization for acs_mail_lite module

    @author Eric Lorenzo (eric@openforce.net)
    @creation-date 22 March, 2002
    @cvs-id $Id$

}

#
# outbound
#

# Default interval is about one minute (reduce lock contention with other jobs scheduled at full minutes)
ad_schedule_proc -thread t 61 acs_mail_lite::sweeper

#if {$queue_dir ne ""} {
    # if BounceMailDir is set then handle incoming mail
#    ad_schedule_proc -thread t 120 acs_mail_lite::load_mails -queue_dir $queue_dir
#}
nsv_set acs_mail_lite send_mails_p 0
nsv_set acs_mail_lite check_bounce_p 0

# Redefine ns_sendmail as a wrapper for acs_mail_lite::send
#ns_log Notice "acs-mail-lite: renaming acs_mail_lite::sendmail to ns_sendmail"
#rename ns_sendmail _old_ns_sendmail
#rename acs_mail_lite::sendmail ns_sendmail



#
# inbound 
#
# acs_mail_lite::load_mails -queue_dir $queue_dir

set inbound_queue_dir [file join [acs_root_dir] acs-mail-lite ]
file mkdir $inbound_queue_dir
# imap scan incoming = si_
# maildir scan incoming = sj_
# Scan incoming start time in clock seconds.
set si_start_time_cs [clock seconds]
# Scan incoming estimated duration pur cycle in seconds
#set scan_in_est_dur_per_cycle_s 120
set si_dur_per_cycle_s [parameter::get_from_package_key -parameter "IncomingScanRate" -package_key "acs-mail-lite" -default 120]
# max_import_rate_per_s .5
set si_mirps .16
# Used by incoming email system
#nsv_set acs_mail_lite scan_in_start_t_cs $si_start_time_cs
nsv_set acs_mail_lite si_start_t_cs $si_start_time_cs
nsv_set acs_mail_lite si_dur_per_cycle_s $si_dur_per_cycle_s
nsv_set acs_mail_lite si_dur_per_cycle_s_override ""
nsv_set acs_mail_lite si_max_ct_per_cycle \
    [expr { int( $si_mirps * $si_dur_per_cycle_s ) } ]
if { [db_table_exists acs_mail_lite_ui] } {
    acs_mail_lite::sched_parameters
}
ad_schedule_proc -thread t \
    $si_dur_per_cycle_s acs_mail_lite::imap_check_incoming

# offset next cycle start
after 314
ad_schedule_proc -thread t \
    $si_dur_per_cycle_s acs_mail_lite::maildir_check_incoming

# offset next cycle start
after 314
ad_schedule_proc -thread t \
    $si_dur_per_cycle_s acs_mail_lite::inbound_queue_pull

ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 1 41] acs_mail_lite::inbound_queue_release



# acs_mail_lite::check_bounces 
ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 0 25] acs_mail_lite::check_bounces



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
