
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install Daemontools (OPTIONAL)}</property>
<property name="doc(title)">Install Daemontools (OPTIONAL)</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="psgml-for-emacs" leftLabel="Prev"
			title="Appendix B. Install
additional supporting software"
			rightLink="install-qmail" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-daemontools" id="install-daemontools"></a>Install Daemontools (OPTIONAL)</h2></div></div></div><p>Daemontools is a collection of programs for controlling other
processes. We use daemontools to run and monitor AOLserver. It is
installed in /package. These commands install daemontools and
svgroup. svgroup is a script for granting permissions, to allow
users other than root to use daemontools for specific services.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>Install Daemontools</p><a class="indexterm" name="idp140682186500936" id="idp140682186500936"></a><p>
<a class="link" href="individual-programs">download
daemontools</a> and install it.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Red Hat 8</p><pre class="screen">[root root]# <strong class="userinput"><code>mkdir -p /package</code></strong>
[root root]# <strong class="userinput"><code>chmod 1755 /package/</code></strong>
[root root]# <strong class="userinput"><code>cd /package/</code></strong>
[root package]# <strong class="userinput"><code>tar xzf /tmp/daemontools-0.76.tar.gz</code></strong>
[root package]# <strong class="userinput"><code>cd admin/daemontools-0.76/</code></strong>
[root daemontools-0.76]# <strong class="userinput"><code>package/install</code></strong>
Linking ./src/* into ./compile...

Creating /service...
Adding svscanboot to inittab...
init should start svscan now.
[root root]#
<span class="action">mkdir -p /package 
chmod 1755 /package 
cd /package 
tar xzf /tmp/daemontools-0.76.tar.gz 
cd admin/daemontools-0.76 
package/install</span>
</pre>
</li><li class="listitem">
<p>Red Hat 9, Fedora Core 1-4</p><p>Make sure you have the source tarball in <code class="computeroutput">/tmp</code>, or <a class="link" href="individual-programs">download
it</a>.</p><pre class="screen">[root root]# <strong class="userinput"><code>mkdir -p /package</code></strong>
[root root]# <strong class="userinput"><code>chmod 1755 /package/</code></strong>
[root root]# <strong class="userinput"><code>cd /package/</code></strong>
[root package]# <strong class="userinput"><code>tar xzf /tmp/daemontools-0.76.tar.gz</code></strong>
[root package]# <strong class="userinput"><code>cd admin</code></strong>
[root admin]# <strong class="userinput"><code>wget http://www.qmail.org/moni.csi.hu/pub/glibc-2.3.1/daemontools-0.76.errno.patch</code></strong>
--14:19:24--  http://moni.csi.hu/pub/glibc-2.3.1/daemontools-0.76.errno.patch
           =&gt; `daemontools-0.76.errno.patch'
Resolving moni.csi.hu... done.
Connecting to www.qmail.org[141.225.11.87]:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 355 [text/plain]

100%[====================================&gt;] 355          346.68K/s    ETA 00:00

14:19:24 (346.68 KB/s) - `daemontools-0.76.errno.patch' saved [355/355]

[root admin]# <strong class="userinput"><code>cd daemontools-0.76</code></strong>
[root daemontools-0.76]# <strong class="userinput"><code>patch -p1 &lt; ../daemontools-0.76.errno.patch</code></strong>
[root daemontools-0.76]# <strong class="userinput"><code>package/install</code></strong>
Linking ./src/* into ./compile...<span class="emphasis"><em>(many lines omitted)</em></span>
Creating /service...
Adding svscanboot to inittab...
init should start svscan now.
[root root]#
<span class="action">mkdir -p /package 
chmod 1755 /package 
cd /package 
tar xzf /tmp/daemontools-0.76.tar.gz 
cd admin
wget http://moni.csi.hu/pub/glibc-2.3.1/daemontools-0.76.errno.patch
cd daemontools-0.76
patch -p1 &lt; ../daemontools-0.76.errno.patch
package/install</span>
</pre>
</li><li class="listitem">
<p>FreeBSD (follow standard install)</p><p>Make sure you have the source tarball in <code class="computeroutput">/tmp</code>, or <a class="link" href="individual-programs">download
it</a>.</p><pre class="screen">[root root]# <strong class="userinput"><code>mkdir -p /package</code></strong>
[root root]# <strong class="userinput"><code>chmod 1755 /package/</code></strong>
[root root]# <strong class="userinput"><code>cd /package/</code></strong>
[root package]# <strong class="userinput"><code>tar xzf /tmp/daemontools-0.76.tar.gz</code></strong>
[root package]# <strong class="userinput"><code>cd admin/daemontools-0.76</code></strong>
[root daemontools-0.76]# <strong class="userinput"><code>package/install</code></strong>
Linking ./src/* into ./compile...<span class="emphasis"><em>(many lines omitted)</em></span>
Creating /service...
Adding svscanboot to inittab...
init should start svscan now.
[root root]#
<span class="action">mkdir -p /package 
chmod 1755 /package 
cd /package 
tar xzf /tmp/daemontools-0.76.tar.gz 
cd admin/daemontools-0.76
package/install</span>
</pre>
</li><li class="listitem">
<p>Debian</p><pre class="screen">[root ~]# <strong class="userinput"><code>apt-get install daemontools-installer</code></strong>
[root ~]# <strong class="userinput"><code>build-daemontools</code></strong>
</pre>
</li>
</ul></div>
</li><li class="listitem">
<p>Verify that svscan is running. If it is, you should see these
two processes running:</p><pre class="screen">[root root]# <strong class="userinput"><code>ps -auxw | grep service</code></strong>
root     13294  0.0  0.1  1352  272 ?        S    09:51   0:00 svscan /service
root     13295  0.0  0.0  1304  208 ?        S    09:51   0:00 readproctitle service errors: .......................................
[root root]#</pre>
</li><li class="listitem">
<p>Install a script to grant non-root users permission to control
daemontools services.</p><pre class="screen">[root root]# <strong class="userinput"><code>cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/svgroup.txt /usr/local/bin/svgroup</code></strong>
[root root]# <strong class="userinput"><code>chmod 755 /usr/local/bin/svgroup</code></strong><span class="action">cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/svgroup.txt /usr/local/bin/svgroup 
chmod 755 /usr/local/bin/svgroup</span>
</pre>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="psgml-for-emacs" leftLabel="Prev" leftTitle="Add PSGML commands to emacs init file
(OPTIONAL)"
			rightLink="install-qmail" rightLabel="Next" rightTitle="Install qmail (OPTIONAL)"
			homeLink="index" homeLabel="Home" 
			upLink="install-more-software" upLabel="Up"> 
		    