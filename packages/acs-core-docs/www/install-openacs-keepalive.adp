
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Starting and Stopping an OpenACS instance.}</property>
<property name="doc(title)">Starting and Stopping an OpenACS instance.</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="maintenance-web" leftLabel="Prev"
		    title="
Chapter 6. Production Environments"
		    rightLink="install-openacs-inittab" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-openacs-keepalive" id="install-openacs-keepalive"></a>Starting and Stopping an OpenACS
instance.</h2></div></div></div><p>The simplest way to start and stop and OpenACS site is to run
the startup shell script provided, <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/daemontools/run</code>.
This runs as a regular task, and logs to the logfile. To stop the
site, kill the script.</p><p>A more stable way to run OpenACS is with a "keepalive"
mechanism of some sort, so that whenever the server halts or is
stopped for a reset, it restarts automatically. This is recommended
for development and production servers.</p><p>The Reference Platform uses Daemontools to control AOLserver. A
simpler method, using <code class="computeroutput">init</code>, is
<a class="link" href="install-openacs-inittab" title="AOLserver keepalive with inittab">here</a>.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Daemontools must already be installed. If not, <a class="link" href="install-daemontools" title="Install Daemontools (OPTIONAL)">install it</a>.</p></li><li class="listitem">
<p>Each service controlled by daemontools must have a directory in
<code class="computeroutput">/service</code>. That directory must
have a file called <code class="computeroutput">run</code>. It
works like this:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The <code class="computeroutput">init</code> program starts
every time the computer is booted.</p></li><li class="listitem"><p>A line in <code class="computeroutput">init</code>'s
configuration file, <code class="computeroutput">/etc/inittab</code>, tells init to run, and to
restart if necessary, <code class="computeroutput">svscanboot</code>.</p></li><li class="listitem"><p>
<code class="computeroutput">svscanboot</code> checks the
directory <code class="computeroutput">/service</code> every few
seconds.</p></li><li class="listitem"><p>If it sees a subdirectory there, it looks for a file in the
subdirectory called <code class="computeroutput">run</code>. If it
finds a run file, it creates a <code class="computeroutput">supervise</code> process</p></li><li class="listitem"><p>
<code class="computeroutput">supervise</code> executes the run
script. Whenever the run script stops, <code class="computeroutput">supervise</code> executes it again. It also
creates additional control files in the same directory.</p></li>
</ul></div><p>Hence, the AOLserver instance for your development server is
started by the file <code class="computeroutput">/service/$OPENACS_SERVICE_NAME/run</code>. But we
use a symlink to make it easier to add and remove stuff from the
<code class="computeroutput">/service</code>, so the actual
location is <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>etc/daemontools/run</code>.</p><p>Daemontools creates additional files and directories to track
status and log. A daemontools directory is included in the OpenACS
tarball at <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/daemontools</code>.
To use it, first ill any existing AOLserver instances. As root,
link the <code class="computeroutput">daemontools</code> directory
into the <code class="computeroutput">/service</code> directory.
Daemontools' <code class="computeroutput">svscan</code> process
checks this directory every five seconds, and will quickly execute
<code class="computeroutput">run</code>.</p><pre class="screen">
[$OPENACS_SERVICE_NAME etc]$ <strong class="userinput"><code>killall nsd</code></strong>
nsd: no process killed
[$OPENACS_SERVICE_NAME etc]$ <strong class="userinput"><code>emacs /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/daemontools/run</code></strong>
[$OPENACS_SERVICE_NAME etc]$ <strong class="userinput"><code>exit</code></strong>

[root root]# <strong class="userinput"><code>ln -s /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/daemontools/ /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
</pre><p>Verify that AOLserver is running.</p><pre class="screen">
[root root]#<strong class="userinput"><code> ps -auxw | grep nsd</code></strong><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>   5562 14.4  6.2 22436 15952 ?       S    11:55   0:04 /usr/local/aolserver/bin/nsd -it /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/config.tcl -u serve
root      5582  0.0  0.2  3276  628 pts/0    S    11:55   0:00 grep nsd
[root root]#
</pre>
</li><li class="listitem">
<p>The user <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> can now control
the service <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> with these
commands:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<code class="computeroutput">svc -d /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code> - Bring
the server down</p></li><li class="listitem"><p>
<code class="computeroutput">svc -u /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code> - Start
the server up and leave it in keepalive mode.</p></li><li class="listitem"><p>
<code class="computeroutput">svc -o /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code> - Start
the server up once. Do not restart it if it stops.</p></li><li class="listitem"><p>
<code class="computeroutput">svc -t /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code> - Stop and
immediately restart the server.</p></li><li class="listitem"><p>
<code class="computeroutput">svc -k /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code> - Sends
the server a KILL signal. This is like KILL -9. AOLserver exits
immediately. If svc -t fails to fully kill AOLserver, use this
option. This does not take the server out of keepalive mode, so it
should still bounce back up immediately.</p></li>
</ul></div>
</li><li class="listitem">
<p>Install a script to automate the stopping and starting of
AOLserver services via daemontools. You can then restart a service
via <code class="computeroutput">restart-aolserver <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code>
</p><pre class="screen">
[root root]# <strong class="userinput"><code>cp /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/acs-core-docs/www/files/restart-aolserver-daemontools.txt /usr/local/bin/restart-aolserver</code></strong>
[root root]# <strong class="userinput"><code>chmod 755 /usr/local/bin/restart-aolserver</code></strong>
[root root]#
</pre>
</li><li class="listitem">
<p>At this point, these commands will work only for the
<code class="computeroutput">root</code> user. Grant permission for
the <code class="computeroutput">web</code> group to use
<code class="computeroutput">svc</code> commands on the
<span class="emphasis"><em><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></em></span>
server.</p><pre class="screen">
[root root]# <strong class="userinput"><code>/usr/local/bin/svgroup web /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[root root]#
</pre>
</li><li class="listitem">
<p>Verify that the controls work. You may want to <code class="computeroutput">tail -f /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/log/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-error.log</code>
in another window, so you can see what happens when you type these
commands.</p><p>More information can be found on the <a class="ulink" href="http://panoptic.com/wiki/aolserver/How_to_start_stop_AOLserver_using_Daemontools" target="_top">AOLserver Daemontools</a> page.</p>
</li>
</ol></div><div class="table">
<a name="idp140592099316488" id="idp140592099316488"></a><p class="title"><strong>Table 6.1. How it
Works</strong></p><div class="table-contents"><table class="table" summary="How it Works" cellspacing="0" border="1">
<colgroup>
<col><col><col><col><col><col>
</colgroup><thead><tr>
<th align="center">Program</th><th align="center">Invoked by this program ...</th><th align="center">... using this file</th><th align="center">Where to find errors</th><th align="center">Log goes to</th><th align="center">Use these commands to control it</th>
</tr></thead><tbody>
<tr>
<td align="center">svscanboot</td><td align="center">init</td><td align="center">/etc/inittab</td><td align="center">ps -auxw | grep readproctitle</td><td align="center">n/a</td><td align="center"> </td>
</tr><tr>
<td align="center">aolserver</td><td align="center">supervise (a child of svscanboot)</td><td align="center">/service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/run</td><td align="center">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/log/error.log</td><td align="center">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/log/$OPENACS_SERVICE_NAME.log</td><td align="center">svc -k /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</td>
</tr><tr>
<td align="center">postgresql</td><td align="center">Redhat init scripts during boot</td><td align="center">/etc/init.d/postgresql</td><td align="center">/usr/local/pgsql/data/server.log</td><td align="center"> </td><td align="center">service postgresql start (Red Hat),
/etc/init.d/postgresql start (Debian)</td>
</tr>
</tbody>
</table></div>
</div><br class="table-break">
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="maintenance-web" leftLabel="Prev" leftTitle="
Chapter 6. Production Environments"
		    rightLink="install-openacs-inittab" rightLabel="Next" rightTitle="AOLserver keepalive with inittab"
		    homeLink="index" homeLabel="Home" 
		    upLink="maintenance-web" upLabel="Up"> 
		