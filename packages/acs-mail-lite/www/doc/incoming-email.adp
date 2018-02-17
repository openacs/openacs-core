<master>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <h1>@title@</h1>

  <p>
    Incoming E-Mail in OpenACS works with the latest version of acs-mail-lite in a general fashion using callbacks to interface with individual package features.
  </p>

  <h2>Processing incoming e-mail</h2>
  <p>
    A scheduled like <a  href='http://openacs.org/api-doc/proc-view?proc=acs_mail_lite::inbound_queue_pull&amp;amp;source_p=1'>acs_mail_lite::inbound_queue_pull</a> processes incoming email by loading each email and triggering callbacks.
  </p>

  <h3>notifications package</h3>
  <p>Alternately, return email can be processed via notifications package.
    Forums package uses this method. See usage of notification::reply::get
    in forums/tcl/forum-reply-procs.tcl. notification::reply::get is
    defined in notifications/tcl/notification-reply-docs.tcl.
    To use this method, install the notifications package, and 
    read documentation in notifications package.
  </p><p>
    Note: Notifications package requires ACS-Mail-Lite package.
    ACS-Mail-Lite is the most direct way of interfacing with email
    send and receive.
  </p>

<h2>Release Notes</h2>

<p>Please file bugs in the <a href="http://openacs.org/bugtracker/openacs/">Bug Tracker</a>.</p>

