ad_library {

    Set up a scheduled process to send out email messages.

    @cvs-id $Id$
    @author John Prevost <jmp@arsdigita.com>
    @creation-date 2000-10-28

}

# Schedule every 15 minutes
ad_schedule_proc -thread t 900 acs_messaging_process_queue

