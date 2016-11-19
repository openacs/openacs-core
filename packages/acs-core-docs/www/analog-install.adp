
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install Analog web file analyzer}</property>
<property name="doc(title)">Install Analog web file analyzer</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-qmail" leftLabel="Prev"
		    title="
Appendix B. Install additional supporting
software"
		    rightLink="install-nspam" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="analog-install" id="analog-install"></a>Install Analog web file analyzer</h2></div></div></div><p>Download the Analog <a class="link" href="individual-programs" title="Analog 5.32 or newer, OPTIONAL">source tarball</a> in <code class="computeroutput">/tmp</code>. Unpack, compile, and install
analog.</p><pre class="screen">
[root aolserver]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>tar xzf /tmp/analog-5.32.tar.gz</code></strong>
[root src]# <strong class="userinput"><code>cd analog-5.32</code></strong>
[root analog-5.32]# <strong class="userinput"><code>make</code></strong>
cd src &amp;&amp; make
make[1]: Entering directory `/usr/local/src/analog-5.32/src'
<span class="emphasis"><em>(many lines omitted)</em></span>
***IMPORTANT: You must read the licence before using analog
***
make[1]: Leaving directory `/usr/local/src/analog-5.32/src'
[root analog-5.32]# <strong class="userinput"><code>cd ..</code></strong>
[root src]#<strong class="userinput"><code> mv analog-5.32 /usr/share/</code></strong>
[root src]#
<span class="action"><span class="action">cd /usr/local/src
tar xzf /tmp/analog-5.32.tar.gz
cd analog-5.32
make
cd ..
mv analog-5.32 /usr/share/</span></span>
</pre><p>See also <a class="xref" href="analog-setup" title="Set up Log Analysis Reports">the section called
&ldquo;Set up Log Analysis
Reports&rdquo;</a>
</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="install-qmail" leftLabel="Prev" leftTitle="Install qmail (OPTIONAL)"
		    rightLink="install-nspam" rightLabel="Next" rightTitle="Install nspam"
		    homeLink="index" homeLabel="Home" 
		    upLink="install-more-software" upLabel="Up"> 
		