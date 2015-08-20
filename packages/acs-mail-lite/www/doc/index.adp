
<property name="context">{/doc/acs-mail-lite {Mail Services Lite}} {User Documentation for ACS Mail Lite}</property>
<property name="doc(title)">User Documentation for ACS Mail Lite</property>
<master>

<body>
<h2>User Documentation for ACS Mail Lite</h2>
Acs Mail Lite handles sending of email via sendmail or smtp and
includes a bounce management system for invalid email accounts.
<p>When called to send a mail, the mail will either get sent
immediately or placed in an outgoing queue (changeable via
parameter) which will be processed every few minutes.</p><p>ACS Mail Lite uses either sendmail (you have to provide the
location of the binary as a parameter) or SMTP to send the mail. If
the sending fails, the mail will be placed in the outgoing queue
again and be given another try a few minutes later when processing
the queue again.</p><p>Each email contains an X-Envelope-From adress constructed as
follows:<br>
The adress starts with "bounce" (can be changed by a parameter)
followed by the user_id, a hashkey and the package_id of the
package instance that sent the email, separated by "-". The domain
name of this adress can be changed with a parameter.</p><p>The system checks every 2 minutes (configurable) in a certain
maildirectory (configurable) for newly bounced emails, so the
mailsystem will have to place every mail to an address beginning
with "bounce" (or whatever the appropriate parameter says) in that
directory. The system then processes each of the bounced emails,
strips out the message_id and verifies the hashkey in the
bounce-address. After that the package-key of the package sending
the original mail is found out by using the package_id provided in
the bounce adress. With that, the system then tries to invoke a
callback procedure via a service contract if one is registered for
that particular package-key. This enables each package to deal with
bouncing mails on their own - probably logging this in special
tables. ACS Mail Lite then logs the event of a bounced mail of that
user.</p><p>Every day a procedure is run that checks if an email account has
to be disabled from receiving any more mail. This is done the
following way:</p><ul>
<li>If a user received his last mail X days ago without any further
bounced mail then his bounce-record gets deleted since it can be
assumed that his email account is working again and no longer
refusing emails. This value can be changed with the parameter
"MaxDaysToBounce".</li><li>If more then Y emails were returned by a particular user then
his email account gets disabled from receiving any more mails from
the system by setting the email_bouncing_p flag to t. This value
can be changed with the parameter "MaxBounceCount".</li><li>To notify users that they will not receive any more mails and
to tell them how to reenable the email account in the system again,
a notification email gets sent every 7 days (configurable) up to 4
times (configurable) that contains a link to reenable the email
account.</li>
</ul>
To use this system here is a quick guide how to do it with postfix.
<ul>
<li>Edit /etc/postfix/main.cf
<ul>
<li>Set "recipient_delimiter" to " - "</li><li>Set "home_mailbox" to "Maildir/"</li><li>Make sure that /etc/postfix/aliases is hashed for the alias
database</li>
</ul>
</li><li>Edit /etc/postfix/aliases. Redirect all mail to "bounce" (if
you leave the parameter as it was) to "nsadmin" (in case you only
run one server).</li>
</ul>
In case of multiple services on one system, create a bounce email
for each of them (e.g. changeing "bounce" to "bounce_service1") and
create a new user that runs the aolserver process for each of them.
You do not want to have service1 deal with bounces for service2.
</body>
