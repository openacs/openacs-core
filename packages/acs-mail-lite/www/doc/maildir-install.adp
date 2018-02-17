<master>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <h1>@title@</h1>


  <h2>Postfix MailDir installation on Linux OS</h2>

  <p>For <strong>dynamic originator address</strong> handling of replies,
    one must have an understanding of postfix configuration basics. See <a  href='http://www.postfix.org/BASIC_CONFIGURATION_README.html'>http://www.postfix.org/BASIC_CONFIGURATION_README.html</a>.
  </p>
  <p>A default Postfix installation tends to work with a fixed email address without many modifications to configuration. 
  </p>
  <p>
    These instructions use the following example values:
  </p>

  <ul>
	<li>hostname: www.yourserver.com</li>
	<li>oacs server user: service0</li>
	<li>OS: Linux</li>
	<li>email user: service0</li>
	<li>email's home dir: /home/service0</li>
	<li>email user's mail dir: /home/service0/MailDir</li>
  </ul>

  <p>
    Important: 
    The email user service0 does not have a &quot;.forward&quot; file. 
    This user is only used for running the OpenACS website. 
    Follow strict configuration guidelines to avoid email looping back unchecked.
  </p>
  <p>The oacs server user needs to have read and write permissions to email user's mail dir. 
For test cases, one may use a common OS user for <code>oacs server user</code> and <code>email user</code>. 
For more strict server configurations, use a different OS user for each, and grant permission for <code>oacs server user</code> to access files and directories in <code>email user's mail dir</code>.
  <p>
    For Postfix, the email user and oacs user do not have to be the same. 
    Furthermore, Postfix makes distinctions between <a  href='http://www.postfix.org/VIRTUAL_README.html'>virtual users and user aliases</a>.
  </p><p>
    Future versions of this documentation should use examples with different names to help distinguish between <a  href='http://www.postfix.org/STANDARD_CONFIGURATION_README.html'>standard configuration examples</a> and the requirements of ACS Mail Lite package.
  </p>

  <p>
    Postfix configuration parameters:
  </p>

  <pre>
    myhostname=www.yourserver.com

    myorigin=$myhostname

    inet_interfaces=$myhostname, localhost

    mynetworks_style=host

    <a  href='http://www.postfix.org/postconf.5.html#virtual_alias_domains'>virtual_alias_domains</a> = www.yourserver.com

    <a  href='http://www.postfix.org/postconf.5.html#virtual_maps'>virtual_maps</a>=regexp:/etc/postfix/virtual

    home_mailbox=MailDir/</pre>

  <p>
    Here is the sequence to follow when installing email service on system for first time. If your system already has email service, adapt these steps accordingly:
  </p>

  <ol>
	<li>Install Postfix</li>
	<li>Install SMTP (for Postfix)</li>
	<li>Edit /etc/postfix/main.cf
      <ul><li>Set "recipient_delimiter" to " - "</li>
        <li>Set "home_mailbox" to "Maildir/"
        </li>
        <li>Make sure that /etc/postfix/aliases is hashed for the alias database
        </li>
      </ul>
    </li>
    <li>Edit /etc/postfix/aliases. Redirect all mail to "bounce". 
      If you're only running one server, 
      using user "nsadmin" maybe more convenient.
      In case of multiple services on one system, 
      create a bounce email for each of them by changing "bounce" to "bounce_service1", bounce_service2 et cetera.
      Create a new user for each NaviServer process.
      You do not want to have service1 deal with bounces for service2.
    </li>
    <li>Edit <a  href='http://www.postfix.org/virtual.5.html'>/etc/postfix/virtual</a>.
      Add a regular expression to filter relevant incoming emails for processing by OpenACS. 
	  <code>@www.yourserver.com service0</code>
	</li>
	<li>Edit /etc/postfix/master.cf
      Uncomment this line so Postfix listens to emails from internet:
	  <code>smtp inet n - n - - smtpd</code>
	</li>
	<li>Create a mail directory as service0
	  <code>mkdir /home/service0/mail</code>
	</li>
	<li>Configure ACS Mail Lite parameters
	  <code>BounceDomain: www.yourserver.com<br />
	    BounceMailDir: /home/service0/MailDir<br />
	    EnvelopePrefix: bounce<br />
	    <br />
	    The EnvelopePrefix is for bounce e-mails only.
	</li>
	<li>Configure Notifications parameters<br />
	  <code>EmailReplyAddressPrefix: notification<br />
	    EmailQmailQueueScanP: 0<br />
	    <br />
	    We want acs-mail-lite incoming handle the Email Scanning, not each package separately.</code>
	  Configure other packages likewise<br />
	</li>
	<li>Invoke <code>postmap</code> in OS shell to recompile virtual db:
	  <code>postmap /etc/postfix/virtual</code>
	</li>
	<li>Restart Postfix. <br />
	  <code>/etc/init.d/postfix restart</code>
	</li>
	<li>Restart OpenACS</li>
  </ol>
  <p>
    Developer note: Parameters should be renamed: <br />
    BounceDomain to IncomingDomain<br />
    BounceMailDir to IncomingMaildir<br />
    EnvelopePrefix to BouncePrefix<br />
    ..to reflect that acs-mail-lite is capable of dealing with other types of incoming e-mail.
  </p><p>
	Furthermore, 
    setting IncomingMaildir parameter clarifies that incoming email handling is setup. 
    This is useful for other packages to determine if they can rely on incoming e-mail working (e.g. to set the reply-to email to an  e-mail address which actually works through a callback if the IncomingMaildir parameter is enabled).
  </p>
