
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install qmail (OPTIONAL)}</property>
<property name="doc(title)">Install qmail (OPTIONAL)</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-daemontools" leftLabel="Prev"
		    title="
Appendix B. Install additional supporting
software"
		    rightLink="analog-install" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-qmail" id="install-qmail"></a>Install qmail (OPTIONAL)</h2></div></div></div><p>Qmail is a Mail Transfer Agent. It handles incoming and outgoing
mail. Install qmail if you want your OpenACS server to send and
receive mail, and you don&#39;t want to use an alternate MTA.</p><p>Red Hat 9: all djb tools (qmail, daemontools, ucspi) will fail
to compile in Red Hat 9 because of changes to glibc (<a class="ulink" href="http://moni.csi.hu/pub/glibc-2.3.1/" target="_top">patches</a>)</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>
<strong>Install ucspi. </strong>This program handles
incoming tcp connections. <a class="link" href="individual-programs" title="ucspi-tcp 0.88, OPTIONAL">Download ucspi</a> and install it.</p><pre class="screen">
[root root]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>wget http://cr.yp.to/ucspi-tcp/ucspi-tcp-0.88.tar.gz</code></strong>
[root src]# <strong class="userinput"><code>tar xzf ucspi-tcp-0.88.tar.gz</code></strong><span class="action"><span class="action">cd /usr/local/src 
wget http://cr.yp.to/ucspi-tcp/ucspi-tcp-0.88.tar.gz
tar xzf ucspi-tcp-0.88.tar.gz </span></span>
</pre><p>Red Hat 9 only</p><pre class="screen"><span class="action"><span class="action">wget http://moni.csi.hu/pub/glibc-2.3.1/ucspi-tcp-0.88.errno.patch
cd ucspi-tcp-0.88
patch -p1 &lt;../ucspi-tcp-0.88.errno.patch
cd ..</span></span></pre><p>All platforms continue:</p><pre class="screen">
[root src]# <strong class="userinput"><code>cd ucspi-tcp-0.88</code></strong>
[root ucspi-tcp-0.88]#<strong class="userinput"><code> make</code></strong>
( cat warn-auto.sh; \
echo 'main="$1"; shift'; \<span class="emphasis"><em>(many lines omitted)</em></span>
./compile instcheck.c
./load instcheck hier.o auto_home.o unix.a byte.a
[root ucspi-tcp-0.88]# <strong class="userinput"><code>make setup check</code></strong>
./install
./instcheck
[root ucspi-tcp-0.88]#
<span class="action"><span class="action">
cd ucspi-tcp-0.88 
make 
make setup check</span></span>
</pre><p>Verify that ucspi-tcp was installed successfully by running the
tcpserver program which is part of ucspi-tcp:</p><pre class="screen">
[root ucspi-tcp-0.88]# <strong class="userinput"><code>tcpserver</code></strong>
tcpserver: usage: tcpserver [ -1UXpPhHrRoOdDqQv ] [ -c limit ] [ -x rules.cdb ] [ -B banner ] [ -g gid ] [ -u uid
] [ -b backlog ] [ -l localname ] [ -t timeout ] host port program
[root ucspi-tcp-0.88]#
</pre><p>
<a class="indexterm" name="idp140592107236824" id="idp140592107236824"></a> (I&#39;m not sure if this next step is
100% necessary, but when I skip it I get problems. If you get the
error <code class="computeroutput">553 sorry, that domain isn&#39;t
in my list of allowed rcpthosts (#5.7.1)</code> then you need to do
this.) AOLserver sends outgoing mail via the ns_sendmail command,
which pipes a command to the sendmail executable. Or, in our case,
the qmail replacement wrapper for the sendmail executable. In some
cases, though, the outgoing mail requset is apparently sent through
tcp/ip, so that it comes to qmail from 127.0.0.1 (a special IP
address that means the local machine - the "loopback"
interface). Unless this mail is addressed to the same machine,
qmail thinks that it&#39;s an attempt to relay mail, and rejects
it. So these two commands set up an exception so that any mail sent
from 127.0.0.1 is allowed to send outgoing mail.</p><pre class="screen">
[root ucspi-tcp-0.88]# <strong class="userinput"><code>cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/tcp.smtp.txt /etc/tcp.smtp</code></strong>
[root ucspi-tcp-0.88]# <strong class="userinput"><code>tcprules /etc/tcp.smtp.cdb /etc/tcp.smtp.tmp &lt; /etc/tcp.smtp</code></strong><span class="action"><span class="action">cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/tcp.smtp.txt /etc/tcp.smtp 
tcprules /etc/tcp.smtp.cdb /etc/tcp.smtp.tmp &lt; /etc/tcp.smtp </span></span>
</pre>
</li><li class="listitem">
<p>
<strong>Install Qmail. </strong><a class="indexterm" name="idp140592107243816" id="idp140592107243816"></a>
</p><p>
<a class="link" href="individual-programs" title="ucspi-tcp 0.88, OPTIONAL">Download qmail</a>, set up the
standard supporting users and build the binaries:</p><pre class="screen">
[root root]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>wget http://www.qmail.org/netqmail-1.04.tar.gz</code></strong>
[root src]# <strong class="userinput"><code>tar xzf netqmail-1.04.tar.gz</code></strong>
--15:04:11--  http://www.qmail.org/netqmail-1.04.tar.gz
           =&gt; `netqmail-1.04.tar.gz'
Resolving www.qmail.org... done.
Connecting to www.qmail.org[192.203.178.37]:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 242,310 [application/x-gunzip]

88% [===============================&gt;     ] 214,620       22.93K/s ETA 00:01

15:04:21 (24.04 KB/s) - `netqmail-1.04.tar.gz' saved [242310/242310]

[root src]# <strong class="userinput"><code>mkdir /var/qmail</code></strong>
[root src]#<strong class="userinput"><code> groupadd nofiles</code></strong>
[root src]# <strong class="userinput"><code>useradd -g nofiles -d /var/qmail/alias alias</code></strong>
[root src]# <strong class="userinput"><code>useradd -g nofiles -d /var/qmail qmaild</code></strong>
[root src]# <strong class="userinput"><code>useradd -g nofiles -d /var/qmail qmaill</code></strong>
[root src]# <strong class="userinput"><code>useradd -g nofiles -d /var/qmail qmailp</code></strong>
[root src]# <strong class="userinput"><code>groupadd qmail</code></strong>
[root src]# <strong class="userinput"><code>useradd -g qmail -d /var/qmail qmailq</code></strong>
[root src]# <strong class="userinput"><code>useradd -g qmail -d /var/qmail qmailr</code></strong>
[root src]# <strong class="userinput"><code>useradd -g qmail -d /var/qmail qmails</code></strong>
[root src]# <strong class="userinput"><code>cd netqmail-1.04</code></strong>
[root netqmail-1.04]# <strong class="userinput"><code>./collate.sh</code></strong>

You should see 7 lines of text below.  If you see anything
else, then something might be wrong.
[1] Extracting qmail-1.03...
[2] Patching qmail-1.03 into netqmail-1.04.  Look for errors below:
     20
[4] The previous line should say 20 if you used GNU patch.
[5] Renaming qmail-1.03 to netqmail-1.04...
[6] Continue installing qmail using the instructions found at:
[7] http://www.lifewithqmail.org/lwq.html#installation
[root netqmail-1.04]# <strong class="userinput"><code>cd netqmail-1.04</code></strong>
[root netqmail-1.04]# <strong class="userinput"><code>make setup check</code></strong>
( cat warn-auto.sh; \
echo CC=\'`head -1 conf-cc`\'; \<span class="emphasis"><em>(many lines omitted)</em></span>
./install
./instcheck
<span class="action"><span class="action">cd /usr/local/src 
wget http://www.qmail.org/netqmail-1.04.tar.gz
tar xzf netqmail-1.04.tar.gz
mkdir /var/qmail 
groupadd nofiles 
useradd -g nofiles -d /var/qmail/alias alias 
useradd -g nofiles -d /var/qmail qmaild 
useradd -g nofiles -d /var/qmail qmaill 
useradd -g nofiles -d /var/qmail qmailp 
groupadd qmail 
useradd -g qmail -d /var/qmail qmailq 
useradd -g qmail -d /var/qmail qmailr 
useradd -g qmail -d /var/qmail qmails
cd netqmail-1.04
./collate.sh
cd netqmail-1.04
make setup check</span></span>
</pre><p>Replace sendmail with qmail&#39;s wrapper.</p><a class="indexterm" name="idp140592107290328" id="idp140592107290328"></a><pre class="screen">
[root qmail-1.03]# <strong class="userinput"><code>rm -f /usr/bin/sendmail /usr/sbin/sendmail</code></strong>
[root qmail-1.03]# <strong class="userinput"><code>ln -s /var/qmail/bin/sendmail /usr/sbin/sendmail</code></strong>
[root qmail-1.03]#
<span class="action"><span class="action">rm -f /usr/bin/sendmail /usr/sbin/sendmail
ln -s /var/qmail/bin/sendmail /usr/sbin/sendmail</span></span>
</pre><p>Configure qmail - specifically, run the config script to set up
files in <code class="computeroutput">/var/qmail/control</code>
specifying the computer&#39;s identity and which addresses it
should accept mail for. This command will automatically set up
qmail correctly if you have correctly set a valid host nome. If
not, you&#39;ll want to read <code class="computeroutput">/var/qmail/doc/INSTALL.ctl</code> to find out how
to configure qmail.</p><pre class="screen">
[root qmail-1.03]# <strong class="userinput"><code>./config-fast <span class="replaceable"><span class="replaceable">yourserver.test</span></span>
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
<span class="action"><span class="action">./config-fast <span class="replaceable"><span class="replaceable">yourserver.test</span></span>
</span></span>
</pre><p>All incoming mail that isn&#39;t for a specific user is handled
by the <code class="computeroutput">alias</code> user. This
includes all root mail. These commands prepare the alias user to
receive mail.</p><pre class="screen">
[root qmail-1.03]# <strong class="userinput"><code>cd ~alias; touch .qmail-postmaster .qmail-mailer-daemon .qmail-root</code></strong>
[root alias]# <strong class="userinput"><code>chmod 644 ~alias/.qmail*</code></strong>
[root alias]# <strong class="userinput"><code>/var/qmail/bin/maildirmake ~alias/Maildir/</code></strong>
[root alias]# <strong class="userinput"><code>chown -R alias.nofiles /var/qmail/alias/Maildir</code></strong>
[root alias]#
<span class="action"><span class="action">cd ~alias; touch .qmail-postmaster .qmail-mailer-daemon .qmail-root 
chmod 644 ~alias/.qmail* 
/var/qmail/bin/maildirmake ~alias/Maildir/ 
chown -R alias.nofiles /var/qmail/alias/Maildir</span></span>
</pre><a class="indexterm" name="idp140592107304760" id="idp140592107304760"></a><p>Configure qmail to use the Maildir delivery format (instead of
mbox), and install a version of the qmail startup script modified
to use Maildir.</p><pre class="screen">
[root alias]# <strong class="userinput"><code>echo "./Maildir" &gt; /var/qmail/bin/.qmail</code></strong>
[root alias]# <strong class="userinput"><code>cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail.rc.txt /var/qmail/rc</code></strong>
[root alias]# <strong class="userinput"><code>chmod 755 /var/qmail/rc</code></strong>
[root alias]# 
<span class="action"><span class="action">echo "./Maildir" &gt; /var/qmail/bin/.qmail 
cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/qmail.rc.txt /var/qmail/rc 
chmod 755 /var/qmail/rc 
</span></span>
</pre><p>Set up the skeleton directory so that new users will be
configured for qmail.</p><pre class="screen">
[root root]# <strong class="userinput"><code>/var/qmail/bin/maildirmake /etc/skel/Maildir</code></strong>
[root root]# <strong class="userinput"><code>echo "./Maildir/" &gt; /etc/skel/.qmail</code></strong>
[root root]# 
<span class="action"><span class="action">/var/qmail/bin/maildirmake /etc/skel/Maildir
echo "./Maildir/" &gt; /etc/skel/.qmail</span></span>
</pre><p>As recommended, we will run qmail with daemontools control
files. Create daemontools control directories, set up a daemontools
control script, copy the supervise control files, and set
permissions. The last line links the control directories to
/service, which will cause supervise to detect them and execute the
run files, causing qmail to start.</p><pre class="screen">
[root root]# <strong class="userinput"><code>mkdir -p /var/qmail/supervise/qmail-send/log</code></strong>
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
[root root]# <strong class="userinput"><code>ln -s /var/qmail/supervise/qmail-send /var/qmail/supervise/qmail-smtpd /service</code></strong><span class="action"><span class="action">mkdir -p /var/qmail/supervise/qmail-send/log
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
</span></span>
</pre><p>Wait ten seconds or so, and then verify that that the four qmail
processes are running. If uptimes don&#39;t rise above 1 second,
this may indicate broken scripts that are continuously restarting.
In that case, start debugging by checking permissions.</p><pre class="screen">
[root root]# <strong class="userinput"><code>qmailctl stat</code></strong>
/service/qmail-send: up (pid 32700) 430 seconds
/service/qmail-send/log: up (pid 32701) 430 seconds
/service/qmail-smtpd: up (pid 32704) 430 seconds
/service/qmail-smtpd/log: up (pid 32705) 430 seconds
messages in queue: 0
messages in queue but not yet preprocessed: 0
[root root]#
</pre><p>Further verify by sending and receiving email. Incoming mail for
root is stored in <code class="computeroutput">/var/qmail/alias/Maildir</code>.</p>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="install-daemontools" leftLabel="Prev" leftTitle="Install Daemontools (OPTIONAL)"
		    rightLink="analog-install" rightLabel="Next" rightTitle="Install Analog web file analyzer"
		    homeLink="index" homeLabel="Home" 
		    upLink="install-more-software" upLabel="Up"> 
		