<master>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <h1>@title@</h1>
<p>Notes in preparation for adding IMAP to legacy bounce MailDir paradigm</p>
  <h3>New procs</h3>
  <p>For imap, each begin of a process should not assume a connection exists or doesn't exist. Check connection using 'imap ping' before login.
    This should help re-correct any connection drop-outs due to intermittent or one-time connection issues.
  </p>
  <p>Each scheduled event should quit in time for next process, so that imap info being processed is always nearly up-to-date.
    This is important in case a separate manual imap process is working in tandem and changing circumstances.
    This is equally important to quit in time, because imap references relative sequences of emails.
    Two concurrent connections would likely have different and overlapping references.
    The overlapping references would likely cause issues, since each connection would expect to process
    the duplicates as if they are not duplicates.
  </p>
<h3>variables useful while exploring new processes like forecasting and scheduling</h3>
  <dl>
    <dt>scan_in_active_p</dt>
    <dd>(don't use. See si_active_cs). Answers question. Is a proc currently scanning replies?</dd>
    <dt>si_active_cs</dt>
    <dd>(don't use. See si_actives_list.) The clock scan of the most recently started cycle. If a cycle's poll doesn't match, it should not process any more email.</dd>
    <dt>si_actives_list</dt>
    <dd>A list of start clock seconds of active imap_checking_incoming procs</dd>
    <dt>scan_incoming_configured_p</dt>
    <dd>Is set to 0 if there is an error trying to connect. OTherwise is set to 1 by acs_mail_lite::imap_check_incoming</dd>

    <dt>replies_est_next_start</dt>
    <dd>Approx value of [clock seconds] next scan is expected to begin</dd>

    <dt>duration_ms_list</dt>
    <dd>Tracks duration of processing of each email in ms of most recent process, appended as a list.
      When a new process starts processing email, the list is reset to only include the last 100 emails. That way, there is always rolling statistics for forecasting process times.</dd>

    <dt>scan_in_est_dur_per_cycle_s</dt>
    <dd>Estimate of duration of current cycle</dd>

    <dt>scan_in_est_quit_cs</dt>
    <dd>When the current cycle should quit based on [clock seconds]</dd>

    <dt>scan_in_start_cs</dt>
    <dd>When the current cycle started scanning based on [clock seconds]</dd>

    <dt>cycle_start_cs</dt>
    <dd>When the current cycle started (pre IMAP authorization etc) based on [clock seconds]</dd>

    <dt>cycle_est_next_start_cs</dt>
    <dd>When the next cycle is to start (pre IMAP authorization etc) based on [clock seconds]</dd>

    <dt>parameter_val_changed_p</dt>
    <dd>If related parameters change, performance tuning underway. Reset statistics.</dd>

    <dt>scan_in_est_dur_per_cycle_s_override</dt>
    <dd>If this value is set, use it instead of the <code>scan_in_est_dur_per_cycle_s</code></dd>

    <dt>accumulative_delay_cycles</dt>
    <dd>Number of cycles that have been skipped 100% due to ongoing process (in cycles).</dd>
      
    
  </dl>
  <p>
    Check <code>scan_incoming_active_p</code> when running new cycle.
    Also set <code>replies_est_next_start</code> to clock seconds for use with time calcs later in cycle.
    If already running, wait a second, check again.. until 90% of duration has elapsed.
    If still running, log a message and quit in time for next event.
  </p>
  <p>
    Each scheduled procedure should also use as much time as it needs up to the cut-off at the next scheduled event.
    Ideally, it needs to forecast if it is going to go overtime with processing of the next email, and quit just before it does.
  </p>
  <p>
    Use <code>duration_ms_list</code> to determine a time adjustment for quitting before next cycle:
    <code>scan_in_est_dur_per_cycle_s</code> + <code>scan_repies_start_time</code> =
    <code>scan_in_est_quit_cs</code>
  </p>
  <p>
    And yet, predicting the duration of the future process is difficult.
    What if the email is 10MB and needs parsed, whereas all prior emails were less then 10kb?
    What if one of the callbacks converts a pdf into a png and annotates it for a web view and takes a few minutes?
    What if the next 5 emails have callbacks that take 5 to 15 minutes to process each waiting on an external service?
  </p>
  <p>The process needs to be split into at least two to handle all cases. 
  </p><p>
    The first process collects incoming email and puts it into a system standard format with a minimal amount of effort sufficient for use by callbacks. The goal of this process is to keep up with incoming email to all mail available to the system at the earliest possible moment.
  </p><p>
    The second process should render a prioritized queue of imported email that have not been processed. First prioritizing new entries, perhaps re-prioritizing any callbacks that error or sampling re-introducing prior errant callbacks etc. then continuing to process the stack. 
  </p><p>
Using this paradigm, parallel processes could be invoked for the queue without significantly changing the paradigm.
</p>
  <p>To reduce overhead on low volume systems, these processes should be scheduled to minimize concurrent operation.
  </p>
  <p>Priorities should offer 3 levels of performance. Colors designate priority to discern from other email priority schemes:</p>
  <ul><li>
      High (abbrev: hpri, Fast Priority, a priority value 1 to mpri_min  (default 999): allow concurrent processes. That is, when a new process starts, it can also process unprocessed cases. As the stack grows, processes run in parallel to reduce stack up to acs_mail_lite_ui.max_concurrent.
    </li><li>
      Med (abbrev: mpri, Standard Priority, a priority mpri_min to mpri_max (default 9999)): Process one at a time with casual overlap. (Try to) quit before next process starts. It's okay if there is a little overlapping.
    </li><li>
      Low (abbrev: lpri, Low Priority, a priority value over mpri_max): Process one at a time only. If a new cycle starts and the last is still running, wait for it to quit (or quit before next cycle).
  </li></ul>

<p>Priority is calculated based on timing and file size</p>
<pre> 
set range priority_max - priority_min
set deviation_max { ($range / 2 }
set midpoint { priority_min + $deviation_max }
time_priority =  $deviation_max (  clock seconds of received datetime - scan_in_start_cs ) / 
            ( 2 * scan_in_est_dur_per_cycle_s )

size_priority = 
   $deviation_max * ((  (size of email in characters)/(config.tcl's max_file_upload_mb *1000000) ) - 0.5)

set equation = int( $midpoint + ($time_priority + size_priority) / 2)
</pre>
<p>Average of time and file size priorities. </p>
<p>hpri_package_ids and lpri_package_ids and hpri_party_ids and lpri_party_ids and mpri_min and mpri_max and hpri_subject_glob and lpri_subject_glob are defined in acs_maile_lite_ui, so they can be tuned without restarting server. ps. Code should check if user is banned before parsing any further.</p>
<p>A proc should be available to recalculate existing email priorities. This means more info needs to be added to table acs_mail_lite_from_external (including size_chars)</p>
  <h3>Import Cycle</h3>
  <p>This scheduling should be simple.  Maybe check if a new process wants to take over. If so, quit.</p>
  
  <h3>Prioritized stack processing cycle</h3>
  <p>
    If next cylce starts and current cycle is still running,
    set <code>scan_in_est_dur_per_cycle_s_override</code> to actual wait time the current cycle has to wait including any prior cycle wait time --if the delays exceed one cycle (<code>accumulative_delay_cycles</code>.
  </p>
  <pre>From acs-tcl/tcl/test/ad-proc-test-procs.tcl
    # This example gets list of implementations of a callback: (so they could be triggered one by one)
     ad_proc -callback a_callback { -arg1 arg2 } { this is a test callback } -
    set callback_procs [info commands ::callback::a_callback::*]
    
  </pre>
  <p>
    Each subsequent cycle moves toward renormalization by adjusting
    <code>scan_in_est_dur_per_cycle_s_override</code> toward value of
    <code>scan_in_est_dur_per_cycle_s</code> by one
    <code>replies_est_dur_per_cycle</code> with minimum of
    <code>scan_in_est_dur_per_cycle_s</code>.
    Changes are exponential to quickly adjust to changing dynamics.
  </p>
  <p>
    For acs_mail_lite::scan_in,
  </p><p>
    Keep track of email flags while processing.<br/>
    Mark /read when reading.<br/>
    Mark /replied if replying.
  </p>
  <p>
    When quitting current scheduled event, don't log out if all processes are not done.
    Also, don't logout if <code>imaptimeout</code> is greater than duration to <code>cycle_est_next_start_cs</code>.
   
    Stay logged in for next cycle.
  </p>
  <p>
    Delete processed messages when done with a cycle?
    No. What if message is used by a callback with delay in processing?
    Move processed emails in a designated folder ProcessFolderName parameter.
    Designated folder may be Trash.
    Set ProcessFolderName by parameter If empty, Default is hostname of ad_url ie:
    [util::split_location [ad_url] protoVar ProcessFolderName portVar]
    If folder does not exist, create it. ProcessFolderName only needs checked if name has changed.
    </p><p>
    MailDir marks email as 'read' by moving from '/new' dir to '/cur' directory. ACS Mail Lite implementations should be consistent as much as possible, and so mark emails in IMAP as 'read' also.

  <h4>
    Email attachments
    </h4>
  <p>
   Since messages are not immediately deleted, create a table of attachment url references. Remove attachments older than AttachmentLife parameter seconds.
   Set default to 30 days old (2592000 seconds).
   Unless ProcessFolderName is Trash, email attachments can be recovered by original email in ProcessFolderName.
No. Once callbacks are processed, assume any transfer of attachments has occurred, so that processed email can be purged.    </p>
