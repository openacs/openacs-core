<master>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <h1>@title@</h1>

  <p>
    Inbound Message Bot is designed to handle more email faster
    while making available more email content in a consistent, useful way.
    It <a href="/api-doc/proc-view?version_id=774&proc=acs_mail_lite::inbound_prioritize">prioritizes incoming messages using a variety of indicators</a>
    into a queue for processing and triggering callbacks.
  </p>
  <p>
    Inbound Message Bot works with the latest version of acs-mail-lite
    in a general fashion using callbacks.
  </p>
<p>
    The code is general enough to adapt to any message sources,
    such as social network apps for example.
  </p>
  <p>The first implementation of Message Bot handles email imported from IMAP or MailDir. These can operate concurrently.</p>
<ul>
  <li>
    See <a href="maildir-install">MailDir installation notes</a> to install.
    For details of operation, see
    <a href="/api-doc/proc-view?proc=acs_mail_lite::maildir_check_incoming&amp;source_p=1">acs_mail_lite::maildir_check_incoming</a>.

  </li><li>
   See <a href="imap-install">IMAP installation notes</a> to install. 
    For details of operation, see 
    <a href="/api-doc/proc-view?proc=acs_mail_lite::imap_check_incoming&amp;source_p=1">acs_mail_lite::imap_check_incoming</a>.
  </li>
</ul>
<h3>Overview of operation</h3>
  <p>
    New messages can be processed by setting the package parameter 
    <code>IncomingFilterProcName</code> to
    the name of a custom filter that examines headers 
    of each email and assigns a
    <code>package_id</code> or modifies other flags based on custom criteria.
  </p>
  <p>
    Incoming attachments are placed in folder acs_root_dir/acs-mail-lite
    since emails are queued. 
    Attachments might need to persist passed a system reset, 
    which may clear a standard system tmp directory used by ad_tmpdir.
    Note that this is different than the value provided by parameter
    FilesystemAttachmentsRoot. 
    FilesystemAttachmentsRoot is for outbound attachments.
  </p>
  <p>
    A callback is subsequently triggered. Packages with a 
    registered callbacks process the email.
  </p>
  <p>
    When callbacks are finished, email is marked as 'read' by
    the importing procedure, and deleted from the import queue
    at a regular interval. An error in one of the callbacks will
    prevent an email from being deleted without concern that
    the email will be re-processed by other callback implementations.
  </p>
