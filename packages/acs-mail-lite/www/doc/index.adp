<master>
  <property name="doc(title)">@title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <h1>@title@</h1>
  <p>
    Acs Mail Lite provides a standard way for OpenACS packages to send and receive email.
  </p>
  <h2>features</h2>
<ul>
  <li>API for sending email</li>
  <li>Outgoing email processed via SMTP or system's sendmail agent.</li>
  <li>Bounce detection for outgoing email</li>
  <li>Incoming email processed via IMAP4 or system's MailDir facility.</li>
  <li>API for receiving email via custom method</li>
  <li>Callback hooks to other packages triggered by replies to sent email</li>
  <li>Callback hooks to other packages triggered by incoming email events</li>
</ul>

  <h2>Contents</h2>
  <ul>
    <li>
      <a href="setup">ACS Mail Lite setup and configuration</a>
    </li><li>
      <a href="inbound-message-bot">Inbound Message Bot</a>
    </li><li>
      <a href="outbound">Outgoing E-mail</a>
    </li><li>
      <a href="inbound">Legacy Incoming E-mail (to version OpenACS 5.9)</a>
    </li>
    <li>
      <a href="glossary">Glossary</a>
    </li>
  </ul>
  
  <h2>Release Notes</h2>
  
  <p>
    A new IMAP4 feature. See <a href="analysis-notes">planning notes</a> and <a href="devel-notes-change-log.txt">development and change notes</a> for change details and reasoning.
  </p>
  <p>
    Please file bugs in the <a href="http://openacs.org/bugtracker/openacs/">Bug Tracker</a>.
  </p>
