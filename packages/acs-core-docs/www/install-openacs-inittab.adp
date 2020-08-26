
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {AOLserver keepalive with inittab}</property>
<property name="doc(title)">AOLserver keepalive with inittab</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install-openacs-keepalive" leftLabel="Prev"
			title="Chapter 6. Production
Environments"
			rightLink="install-next-add-server" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-openacs-inittab" id="install-openacs-inittab"></a>AOLserver keepalive with inittab</h2></div></div></div><p>This is an alternative method for keeping the AOLserver process
running. The recommended method is to <a class="link" href="install-openacs-keepalive" title="Starting and Stopping an OpenACS instance.">run AOLserver
supervised</a>.</p><p>This step should be completed as root. This can break every
service on your machine, so proceed with caution.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>There are 2 general steps to getting this working.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Install a script called <code class="computeroutput">restart-aolserver</code>. This script doesn&#39;t
actually restart AOLserver - it just kills it.</p></li><li class="listitem"><p>Ask the OS to restart our service whenever it&#39;s not running.
We do this by adding a line to <code class="computeroutput">/etc/inittab</code>.</p></li>
</ol></div><p>Calling <code class="computeroutput">restart-aolserver</code>
kills our service. The OS notices that our service is not running,
so it automatically restarts it. Thus, calling <code class="computeroutput">restart-aolserver</code> effectively restarts our
service.</p>
</li><li class="listitem"><p>Copy this <a class="ulink" href="files/restart-aolserver.txt" target="_top">file</a> into <code class="computeroutput">/var/tmp/restart-aolserver.txt</code>.</p></li><li class="listitem">
<p>This script needs to be SUID-root, which means that the script
will run as root. This is necessary to ensure that the AOLserver
processes are killed regardless of who owns them. However the
script should be executable by the <code class="computeroutput">web</code> group to ensure that the users updating
the web page can use the script, but that general system users
cannot run the script. You also need to have Perl installed and
also a symbolic link to it in <code class="computeroutput">/usr/local/bin</code>.</p><pre class="programlisting">
[joeuser ~]$ su - 
Password: ***********
[root ~]# cp /var/tmp/restart-aolserver.txt /usr/local/bin/restart-aolserver
[root ~]# chown root.web /usr/local/bin/restart-aolserver
[root ~]# chmod 4750 /usr/local/bin/restart-aolserver
[root ~]# ln -s /usr/bin/perl /usr/local/bin/perl
[root ~]# exit</pre>
</li><li class="listitem">
<p>Test the <code class="computeroutput">restart-aolserver</code>
script. We&#39;ll first kill all running servers to clean the
slate. Then, we&#39;ll start one server and use <code class="computeroutput">restart-aolserver</code> to kill it. If it works,
then there should be no more servers running. You should see the
following lines.</p><pre class="programlisting">
[joeuser ~]$ killall nsd
nsd: no process killed
[joeuser ~]$ /usr/local/aolserver/bin/nsd-postgres -t ~/var/lib/aolserver/<span class="emphasis"><em>birdnotes</em></span>/nsd.tcl
[joeuser ~]$ restart-aolserver <span class="emphasis"><em>birdnotes</em></span>
Killing 23727 
[joeuser ~]$ killall nsd
nsd: no process killed</pre><p>The number 23727 indicates the process id(s) (PIDs) of the
processes being killed. It is important that <span class="strong"><strong>no processes are killed</strong></span> by the
second call to <code class="computeroutput">killall</code>. If
there are processes being killed, it means that the script is not
working.</p>
</li><li class="listitem">
<p>Assuming that the <code class="computeroutput">restart-aolserver</code> script worked, login as
root and open <code class="computeroutput">/etc/inittab</code> for
editing.</p><pre class="programlisting">
[joeuser ~]$ su -
Password: ************
[root ~]# emacs -nw /etc/inittab</pre>
</li><li class="listitem">
<p>Copy this line into the bottom of the file as a template, making
sure that the first field <code class="computeroutput">nss1</code>
is unique.</p><pre class="programlisting">
nss1:345:respawn:/usr/local/aolserver/bin/nsd-postgres -i -u nobody -g web -t /home/<span class="emphasis"><em>joeuser</em></span>/var/lib/aolserver/<span class="emphasis"><em>birdnotes</em></span>/nsd.tcl</pre>
</li><li class="listitem"><p>
<span class="strong"><strong>Important:</strong></span> Make
sure there is a newline at the end of the file. If there is not a
newline at the end of the file, the system may suffer catastrophic
failures.</p></li><li class="listitem">
<p>Still as root, enter the following command to re-initialize
<code class="computeroutput">/etc/inittab</code>.</p><pre class="programlisting">
[root ~]# killall nsd    
nsd: no process killed
[root ~]# /sbin/init q</pre>
</li><li class="listitem">
<p>See if it worked by running the <code class="computeroutput">restart-aolserver</code> script again.</p><pre class="programlisting">
[root ~]# restart-aolserver <span class="emphasis"><em>birdnotes</em></span>
Killing 23750</pre>
</li>
</ul></div><p>If processes were killed, congratulations, your server is now
automated for startup and shutdown.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install-openacs-keepalive" leftLabel="Prev" leftTitle="Starting and Stopping an OpenACS
instance."
			rightLink="install-next-add-server" rightLabel="Next" rightTitle="Running multiple services on one
machine"
			homeLink="index" homeLabel="Home" 
			upLink="maintenance-web" upLabel="Up"> 
		    