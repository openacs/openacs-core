
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Running multiple services on one machine}</property>
<property name="doc(title)">Running multiple services on one machine</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-openacs-inittab" leftLabel="Prev"
		    title="
Chapter 6. Production Environments"
		    rightLink="high-avail" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-next-add-server" id="install-next-add-server"></a>Running
multiple services on one machine</h2></div></div></div><p>
<strong>Services on different ports. </strong>To run
a different service on another port but the same ip, simply repeat
<a class="xref" href="openacs" title="Install OpenACS 5.9.0">Install OpenACS 5.9.0</a> replacing
<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>, and change
the</p><pre class="programlisting">
set httpport              8000
set httpsport             8443 
</pre><p>to different values.</p><p>
<strong>Services on different host
names. </strong>For example, suppose you want to
support <code class="computeroutput">http://service0.com</code> and
<code class="computeroutput">http://bar.com</code> on the same
machine. The easiest way is to assign each one a different ip
address. Then you can install two services as above, but with
different values for</p><pre class="programlisting">
set hostname               [ns_info hostname]
set address                127.0.0.1 
</pre><p>If you want to install two services with different host names
sharing the same ip, you&#39;ll need nsvhr to redirect requests
based on the contents of the tcp headers. See <a class="ulink" href="http://borkware.com/rants/aolserver-vhosting/" target="_top">AOLserver Virtual Hosting with TCP</a> by <a class="ulink" href="mailto:markd\@borkware.com" target="_top">markd</a>.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="install-openacs-inittab" leftLabel="Prev" leftTitle="AOLserver keepalive with inittab"
		    rightLink="high-avail" rightLabel="Next" rightTitle="High Availability/High Performance
Configurations"
		    homeLink="index" homeLabel="Home" 
		    upLink="maintenance-web" upLabel="Up"> 
		