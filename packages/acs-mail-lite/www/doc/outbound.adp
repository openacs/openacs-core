<master>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <h1>@title@</h1>

  <p>
    Email is sent via sendmail or SMTP. If SMTP is not configured,
    sendmail is assumed.
  </p><p>
    A bounce management system is available for tracking accounts with
    email that have issues receiving email. 
  </p><p>
    Email can be sent immediately
    or placed in an outgoing queue that
    is processed at regular intervals.
    Package parameter <code>sendImmediatelyP</code> sets the default.
  </p><p>
    If sending fails, mail to send is put in the outgoing queue
    again. The queue is processed every few minutes.
  </p>
  <h2>A legacy description of the process</h2>
<p>
Acs Mail Lite handles sending of email via sendmail or smtp
and includes a bounce management system for invalid email
accounts.
</p><p>
When called to send a mail, the mail will either get sent immediately
or placed in an outgoing queue (changeable via parameter) which
will be processed every few minutes.
</p><p>
    Each outbound email contains an
    "<code>X-Envelope-From &lt;address@IncomingDomain&gt;</code>" header.
    The address part consists of values from package parameter
    <code>EvenlopePrefix</code>
    followed by the email sender's <code>user_id</code>, a hashkey,
    and the <code>package_id</code> of the
    package instance that is sending the email.
    The address components are separated by a dash ("-").
    <code>IncomingDomain</code> refers to the value of package parameter <code>IncomingDomain</code>.
  </p><p>
ACS Mail Lite uses either sendmail (you have to provide the
location of the binary as a parameter) or SMTP to send the mail.
If the sending fails, the mail will be placed in the outgoing queue
again and be given another try a few minutes later when processing
the queue again.
</p><p>
Each email contains an X-Envelope-From address constructed as
follows:<br>
The address starts with "bounce" (can be changed by a parameter)
followed by the user_id, a hashkey and the package_id of the
package instance that sent the email, separated by "-". The
domain name of this address can be changed with a parameter.
</p><p>
The system checks every 2 minutes (configurable) in a certain
maildirectory (configurable) for newly bounced emails, so the
mailsystem will have to place every mail to an address beginning
with "bounce" (or whatever the appropriate parameter says) in that
directory. The system then processes each of the bounced emails,
strips out the message_id and verifies the hashkey in the bounce-address.
After that the package-key of the package sending the original mail
is found out by using the package_id provided in the bounce
address. With that, the system then tries to invoke a callback
procedure via a service contract if one is registered for that
particular package-key. This enables each package to deal with
bouncing mails on their own - probably logging this in special tables.
ACS Mail Lite then logs the event of a bounced mail of that
user.
</p><p>
Every day a procedure is run that checks if an email account
has to be disabled from receiving any more mail. This is done
the following way:
</p>
<ul>
<li>If a user received his last mail X days ago without any further
bounced mail then his bounce-record gets deleted since it can
be assumed that his email account is working again and no longer
refusing emails. This value can be changed with the parameter
"MaxDaysToBounce".</li>
<li>If more then Y emails were returned by a particular user then
his email account gets disabled from receiving any more mails
from the system by setting the email_bouncing_p flag to t. This
value can be changed with the parameter "MaxBounceCount".</li>
<li>To notify users that they will not receive any more mails and to
tell them how to re-enable the email account in the system again,
a notification email gets sent every 7 days (configurable)
up to 4 times (configurable) that contains a link to re-enable
the email account.</li>
</ul>
