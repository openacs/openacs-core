<master>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <h1>@title@</h1>
  <p>
    Messages can come from a variety of sources.
    Handling replies to outbound email is a common case.
  </p>
  Currently there are these distinct paradigms for setting up return email:
</p>
  <ol>
    <li>
      A <strong>fixed outbound email address</strong>. FixedSenderEmail parameter defines
      the fixed email address used. Each package sending email can create
      and set its own FixedSenderEmail parameter. The default
      is to use ACS-Mail-Lite's parameter. 
      As an originating SMTP agent, orignator is set to the
      ACS-Mail-Lite's parameter, if it is not empty.
      The replying email's message-id is used to reference any mapped
      information about the email, such as package_id or object_id.
      The message-id includes a signed signature to detect and reject
      a tampered message-id, and prevents publishing of system ids.
    </li><li>
      A <strong>dynamic originator address</strong> that results in 
      a custom return email address for each outbound email. 
      This provides an alternate way to supply the original message_id key, 
      if the message_id key is altered. 
      For this to work, the email system must be configured to
      accept email to any account at the domain specified by the
      BounceDomain parameter.
    </li>
  </ol>

  <h3>IMAP</h3>
  <p>After <a href="imap-install">installing nsimap</a>, setup consists of filling out the relevant parameters in the acs-mail-lite package, mainly: BounceDomain, FixedSenderEmail and the IMAP section.
</p>
  <h3>Postfix MailDir on Linux OS</h3>
  <p>After <a href="maildir-install">installing and configuring Postifx</a>, a setup consists of filling out the relevant parameters in the acs-mail-lite package.
