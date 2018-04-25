
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install qmail (OPTIONAL)}</property>
<property name="doc(title)">Install qmail (OPTIONAL)</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install-daemontools" leftLabel="Prev"
			title="Appendix B. Install
additional supporting software"
			rightLink="analog-install" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-qmail" id="install-qmail"></a>Install qmail (OPTIONAL)</h2></div></div></div><p>Qmail is a secure, reliable, efficient, simple Mail Transfer
Agent. It handles incoming and outgoing mail. Install qmail if you
want your OpenACS server to send and receive mail, and you
don&#39;t want to use an alternate MTA.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<strong>Install qmail. </strong> QMail is available as
standard Debian/Ubuntu package, rpms for Fedora/Redhat/CenTOS are
available from <a class="ulink" href="https://en.wikipedia.org/wiki/Qmail" target="_top">QMail wiki
page</a>
</p></li><li class="listitem">
<p>Replace sendmail with qmail&#39;s wrapper.</p><a class="indexterm" name="idp140682186435976" id="idp140682186435976"></a><pre class="screen">[root qmail-1.03]# <strong class="userinput"><code>rm -f /usr/bin/sendmail /usr/sbin/sendmail</code></strong>
[root qmail-1.03]# <strong class="userinput"><code>ln -s /var/qmail/bin/sendmail /usr/sbin/sendmail</code></strong>
[root qmail-1.03]#
<span class="action">rm -f /usr/bin/sendmail /usr/sbin/sendmail
ln -s /var/qmail/bin/sendmail /usr/sbin/sendmail</span>
</pre><p>Configure qmail - specifically, run the config script to set up
files in <code class="computeroutput">/var/qmail/control</code>
specifying the computer&#39;s identity and which addresses it
should accept mail for. This command will automatically set up
qmail correctly if you have correctly set a valid host nome. If
not, you&#39;ll want to read <code class="computeroutput">/var/qmail/doc/INSTALL.ctl</code> to find out how
to configure qmail.</p><pre class="screen">[root qmail-1.03]# <strong class="userinput"><code>./config-fast <em class="replaceable"><code>yourserver.test</code></em>
</code></strong>
Your fully qualified host name is yourserver.test.
Putting yourserver.test into control/me...
Putting yourserver.test into control/defaultdomain...
Putting yourserver.test into control/plusdomain...
Putting yourserver.test into control/locals...
Putting yourserver.test into control/rcpthosts...
Now qmail will refuse to accept SMTP messages except to yourserver.test.
Make sure to change rcpthosts if you add hosts to locals or virtualdomains!
[root qmail-1.03]#
<span class="action">./config-fast <em class="replaceable"><code>yourserver.test</code></em>
</span>
</pre><p>All incoming mail that isn&#39;t for a specific user is handled
by the <code class="computeroutput">alias</code> user. This
includes all root mail. These commands prepare the alias user to
receive mail.</p><pre class="screen">[root qmail-1.03]# <strong class="userinput"><code>cd ~alias; touch .qmail-postmaster .qmail-mailer-daemon .qmail-root</code></strong>
[root alias]# <strong class="userinput"><code>chmod 644 ~alias/.qmail*</code></strong>
[root alias]# <strong class="userinput"><code>/var/qmail/bin/maildirmake ~alias/Maildir/</code></strong>
[root alias]# <strong class="userinput"><code>chown -R alias.nofiles /var/qmail/alias/Maildir</code></strong>
[root alias]#
<span class="action">cd ~alias; touch .qmail-postmaster .qmail-mailer-daemon .qmail-root 
chmod 644 ~alias/.qmail* 
/var/qmail/bin/maildirmake ~alias/Maildir/ 
chown -R alias.nofiles /var/qmail/alias/Maildir</span>
</pre><a class="indexterm" name="idp140682186420440" id="idp140682186420440"></a><p>Configure qmail to use the Maildir delivery format (instead of
mbox), and install a version of the qmail startup script modified
to use Maildir.</p><pre class="screen">[root alias]# <strong class="userinput"><code>echo "./Maildir" &gt; /var/qmail/bin/.qmail</code></strong>
[root alias]# <strong class="userinput"><code>cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail.rc.txt /var/qmail/rc</code></strong>
[root alias]# <strong class="userinput"><code>chmod 755 /var/qmail/rc</code></strong>
[root alias]# 
<span class="action">echo "./Maildir" &gt; /var/qmail/bin/.qmail 
cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail.rc.txt /var/qmail/rc 
chmod 755 /var/qmail/rc 
</span>
</pre><p>Set up the skeleton directory so that new users will be
configured for qmail.</p><pre class="screen">[root root]# <strong class="userinput"><code>/var/qmail/bin/maildirmake /etc/skel/Maildir</code></strong>
[root root]# <strong class="userinput"><code>echo "./Maildir/" &gt; /etc/skel/.qmail</code></strong>
[root root]# 
<span class="action">/var/qmail/bin/maildirmake /etc/skel/Maildir
echo "./Maildir/" &gt; /etc/skel/.qmail</span>
</pre><p>As recommended, we will run qmail with daemontools control
files. Create daemontools control directories, set up a daemontools
control script, copy the supervise control files, and set
permissions. The last line links the control directories to
/service, which will cause supervise to detect them and execute the
run files, causing qmail to start.</p><pre class="screen">[root root]# <strong class="userinput"><code>mkdir -p /var/qmail/supervise/qmail-send/log</code></strong>
[root root]# <strong class="userinput"><code>mkdir -p /var/qmail/supervise/qmail-smtpd/log</code></strong>
[root root]# <strong class="userinput"><code>mkdir /var/log/qmail</code></strong>
[root root]# <strong class="userinput"><code>chown qmaill /var/log/qmail</code></strong>
[root root]# <strong class="userinput"><code>cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmailctl.txt /var/qmail/bin/qmailctl</code></strong>
[root root]# <strong class="userinput"><code>chmod 755 /var/qmail/bin/qmailctl</code></strong>
[root root]# <strong class="userinput"><code>ln -s /var/qmail/bin/qmailctl /usr/bin</code></strong>
[root root]# <strong class="userinput"><code>cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail-send-run.txt /var/qmail/supervise/qmail-send/run </code></strong>
[root root]# <strong class="userinput"><code>cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail-send-log-run.txt /var/qmail/supervise/qmail-send/log/run</code></strong>
[root root]# <strong class="userinput"><code>cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail-smtpd-run.txt /var/qmail/supervise/qmail-smtpd/run</code></strong>
[root root]# <strong class="userinput"><code>cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail-smtpd-log-run.txt /var/qmail/supervise/qmail-smtpd/log/run</code></strong>
[root root]# <strong class="userinput"><code>chmod 755 /var/qmail/supervise/qmail-send/run</code></strong>
[root root]# <strong class="userinput"><code>chmod 755 /var/qmail/supervise/qmail-send/log/run</code></strong>
[root root]# <strong class="userinput"><code>chmod 755 /var/qmail/supervise/qmail-smtpd/run</code></strong>
[root root]# <strong class="userinput"><code>chmod 755 /var/qmail/supervise/qmail-smtpd/log/run</code></strong>
[root root]# <strong class="userinput"><code>ln -s /var/qmail/supervise/qmail-send /var/qmail/supervise/qmail-smtpd /service</code></strong>
[root root]# <strong class="userinput"><code>ln -s /var/qmail/supervise/qmail-send /var/qmail/supervise/qmail-smtpd /service</code></strong><span class="action">mkdir -p /var/qmail/supervise/qmail-send/log
mkdir -p /var/qmail/supervise/qmail-smtpd/log
mkdir /var/log/qmail
chown qmaill /var/log/qmail
cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmailctl.txt /var/qmail/bin/qmailctl
chmod 755 /var/qmail/bin/qmailctl
ln -s /var/qmail/bin/qmailctl /usr/bin
cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail-send-run.txt /var/qmail/supervise/qmail-send/run
cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail-send-log-run.txt /var/qmail/supervise/qmail-send/log/run
cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail-smtpd-run.txt /var/qmail/supervise/qmail-smtpd/run
cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail-smtpd-log-run.txt /var/qmail/supervise/qmail-smtpd/log/run
chmod 755 /var/qmail/supervise/qmail-send/run
chmod 755 /var/qmail/supervise/qmail-send/log/run
chmod 755 /var/qmail/supervise/qmail-smtpd/run
chmod 755 /var/qmail/supervise/qmail-smtpd/log/run
ln -s /var/qmail/supervise/qmail-send /var/qmail/supervise/qmail-smtpd /service
</span>
</pre><p>Wait ten seconds or so, and then verify that the four qmail
processes are running. If uptimes don&#39;t rise above 1 second,
this may indicate broken scripts that are continuously restarting.
In that case, start debugging by checking permissions.</p><pre class="screen">[root root]# <strong class="userinput"><code>qmailctl stat</code></strong>
/service/qmail-send: up (pid 32700) 430 seconds
/service/qmail-send/log: up (pid 32701) 430 seconds
/service/qmail-smtpd: up (pid 32704) 430 seconds
/service/qmail-smtpd/log: up (pid 32705) 430 seconds
messages in queue: 0
messages in queue but not yet preprocessed: 0
[root root]#</pre><p>Further verify by sending and receiving email. Incoming mail for
root is stored in <code class="computeroutput">/var/qmail/alias/Maildir</code>.</p>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install-daemontools" leftLabel="Prev" leftTitle="Install Daemontools (OPTIONAL)"
			rightLink="analog-install" rightLabel="Next" rightTitle="Install Analog web file analyzer"
			homeLink="index" homeLabel="Home" 
			upLink="install-more-software" upLabel="Up"> 
		    