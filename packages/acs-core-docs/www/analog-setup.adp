
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Set up Log Analysis Reports}</property>
<property name="doc(title)">Set up Log Analysis Reports</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install-ssl" leftLabel="Prev"
			title="Chapter 6. Production
Environments"
			rightLink="uptime" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="analog-setup" id="analog-setup"></a>Set up Log Analysis Reports</h2></div></div></div><p>Analog is a program with processes webserver access logs,
performs DNS lookup, and outputs HTML reports. Analog should
<a class="link" href="analog-install" title="Install Analog web file analyzer">already be installed.</a> A
modified configuration file is included in the OpenACS tarball.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<pre class="screen">[root src]# <strong class="userinput"><code>su - $OPENACS_SERVICE_NAME</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd /var/lib/aolserver/$OPENACS_SERVICE_NAME</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>mkdir www/log</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cp -r /usr/share/analog-5.32/images www/log/</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <span class="action">
su - $OPENACS_SERVICE_NAME
cd /var/lib/aolserver/$OPENACS_SERVICE_NAME
cp /var/lib/aolserver/$OPENACS_SERVICE_NAME/packages/acs-core-docs/www/files/analog.cfg.txt etc/analog.cfg
mkdir www/log
cp -r /usr/share/analog-5.32/images www/log/</span>
</pre><p>Edit <code class="computeroutput">/var/lib/aolserver/$OPENACS_SERVICE_NAME/etc/analog.cfg</code>
and change the variable in <code class="computeroutput">HOSTNAME
"[my organisation]"</code> to reflect your website title.
If you don&#39;t want the traffic log to be publicly visible,
change <code class="computeroutput">OUTFILE
/var/lib/aolserver/$OPENACS_SERVICE_NAME/www/log/traffic.html</code>
to use a private directory. You&#39;ll also need to edit all
instances of service0 to your $OPENACS_SERVICE_NAME.</p>
</li><li class="listitem">
<p>Run it.</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>/usr/share/analog-5.32/analog -G -g/var/lib/aolserver/$OPENACS_SERVICE_NAME/etc/analog.cfg</code></strong>
/usr/share/analog-5.32/analog: analog version 5.32/Unix
/usr/share/analog-5.32/analog: Warning F: Failed to open DNS input file
  /home/$OPENACS_SERVICE_NAME/dnscache: ignoring it
  (For help on all errors and warnings, see docs/errors.html)
/usr/share/analog-5.32/analog: Warning R: Turning off empty Search Word Report
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$</pre><p>Verify that it works by browing to <code class="computeroutput">http://yourserver.test:8000/log/traffic.html</code>
</p>
</li><li class="listitem">
<p>Automate this by creating a file in <code class="computeroutput">/etc/cron.daily</code>.</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>exit</code></strong>
logout

[root root]# <strong class="userinput"><code>emacs /etc/cron.daily/analog</code></strong>
</pre><p>Put this into the file:</p><pre class="programlisting">#!/bin/sh

/usr/share/analog-5.32/analog -G -g/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/etc/analog.cfg</pre><pre class="screen">[root root]# <strong class="userinput"><code>chmod 755 /etc/cron.daily/analog</code></strong>
</pre><p>Test it by running the script.</p><pre class="screen">[root root]# <strong class="userinput"><code>sh /etc/cron.daily/analog</code></strong>
</pre><p>Browse to <code class="computeroutput">http://<em class="replaceable"><code>yourserver.test</code></em>/log/traffic.html</code>
</p>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install-ssl" leftLabel="Prev" leftTitle="Installing SSL Support for an OpenACS
service"
			rightLink="uptime" rightLabel="Next" rightTitle="External uptime validation"
			homeLink="index" homeLabel="Home" 
			upLink="maintenance-web" upLabel="Up"> 
		    