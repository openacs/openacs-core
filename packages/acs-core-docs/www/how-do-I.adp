
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {How Do I?}</property>
<property name="doc(title)">How Do I?</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="configuring-configuring-permissions" leftLabel="Prev"
			title="Chapter 4. Configuring a
new OpenACS Site"
			rightLink="upgrade" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="how-do-I" id="how-do-I"></a>How Do I?</h2></div></div></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140682188417816" id="idp140682188417816"></a>How do I edit the front page of a new site
through a web interface?</h3></div></div></div><p>The easiest way is to install the Edit-This-Page package.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Log in to the web site as an administrator.</p></li><li class="listitem"><p>Click on Admin &gt; Install Software &gt; Install from OpenACS
Repository / Install new application</p></li><li class="listitem"><p>Choose Edit This Page and install</p></li><li class="listitem"><p>Follow the instructions within <a class="ulink" href="/doc/edit-this-page/install" target="_top">Edit This Page</a> (the
link will only work after Edit This Page is installed).</p></li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140682182808328" id="idp140682182808328"></a>How do I let anybody who registers post to
a weblog?</h3></div></div></div><p>Go to <code class="computeroutput"><a class="ulink" href="/admin/permissions" target="_top">/admin/permissions</a></code>
and grant Create to Registered Users</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140682182810840" id="idp140682182810840"></a>How do I replace the front page of a new
site with the front page of an application on that site</h3></div></div></div><p>Suppose you install a new site and install Weblogger, and you
want all visitors to see weblogger automatically.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>On the front page, click the <code class="computeroutput"><a class="ulink" href="/admin" target="_top">Admin</a></code> button.</p></li><li class="listitem"><p>On the administration page, click <code class="computeroutput">Parameters</code> link.</p></li><li class="listitem"><p>Change the parameter <code class="computeroutput">IndexRedirectUrl</code> to be the URI of the
desired application. For a default weblogger installation, this
would be <code class="computeroutput"><strong class="userinput"><code>weblogger/</code></strong></code>. Note the
trailing slash.</p></li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140682183490200" id="idp140682183490200"></a>How do I put custom functionality on front
page of a new site?</h3></div></div></div><p>Every page within an OpenACS site is part of a <span class="strong"><strong>subsite</strong></span><a class="ulink" href="/doc/acs-subsite" target="_top">More information)</a>. The home
page of the entire site is the front page is a special, default
instance of a subsite, served from <code class="computeroutput">/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/www</code>.
If an index page is not found there, the default index page for all
subsites is used. To customize the code on the front page, copy the
default index page from the Subsite package to the Main site and
edit it:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><pre class="screen"><strong class="userinput"><code>cp <code class="computeroutput">/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/packages/acs-subsite/www/index*</code><code class="computeroutput">/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/www</code>
</code></strong></pre></li><li class="listitem"><p>Edit the new <code class="computeroutput">index.adp</code> to
change the text; you shouldn&#39;t need to edit <code class="computeroutput">index.tcl</code> unless you are adding new
functionality.</p></li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140682188136376" id="idp140682188136376"></a>How do I change the site-wide style?</h3></div></div></div><p>Almost all pages on an OpenACS site use <a class="ulink" href="/doc/acs-templating" target="_top">ACS Templating</a>, and so
their appearance is driven by a layer of different files. Let&#39;s
examine how this works:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>A templated page uses an ADP/Tcl pair. The first line in the ADP
file is usually:</p><pre class="programlisting">&lt;master&gt;</pre><p>If it appears exactly like this, without any arguments, the
template processor uses <code class="computeroutput">default-master</code> for that subsite. For pages
in <code class="computeroutput">/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/www</code>,
this is <code class="computeroutput">/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/www/default-master.adp</code>
and the associated .tcl file.</p>
</li><li class="listitem"><p>The <code class="computeroutput">default-master</code> is itself
a normal ADP page. It draws the subsite navigation elements and
invokes <code class="computeroutput">site-master</code>
(<code class="computeroutput">/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/www/site-master.adp</code>
and .tcl)</p></li><li class="listitem"><p>The <code class="computeroutput">site-master</code> draws
site-wide navigation elements and invokes <code class="computeroutput">blank-master</code> (<code class="computeroutput">/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/www/blank-master.adp</code>
and .tcl).</p></li><li class="listitem"><p>
<code class="computeroutput">Blank-master</code> does HTML
housekeeping and provides a framework for special sitewide
navigation "meta" elements such as Translator widgets and
Admin widgets.</p></li>
</ul></div><div class="figure">
<a name="idp140682183059880" id="idp140682183059880"></a><p class="title"><strong>Figure 4.1. Site
Templates</strong></p><div class="figure-contents"><div class="mediaobject"><img src="images/site-templates.png" alt="Site Templates"></div></div>
</div><br class="figure-break">
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140682183062632" id="idp140682183062632"></a>How do I diagnose a permissions
problem?</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<strong>Steps to Reproduce. </strong> The events package
does not allow users to register for new events.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Go to the http://yourserver.net/events as a visitor (ie, log out
and, if necessary, clear cookies). This in on a 4.6.3 site with
events version 0.1d3.</p></li><li class="listitem"><p>Select an available event</p></li><li class="listitem"><p>A link such as <code class="computeroutput">Registration:
Deadline is 03/15/2004 10:00am. » Login or sign up to register for
this event.</code> is visible. Click on "Login or sign
up"</p></li><li class="listitem"><p>Complete a new registration. Afterwards, you should be
redirected back to the same page.</p></li>
</ol></div><p>Actual Results: The page says <code class="computeroutput">"You do not have permission to register for
this event."</code>
</p><p>Expected results: A link or form to sign up for the event is
shown.</p>
</li><li class="listitem">
<p>
<strong>Finding the problem. </strong> We start with the
page that has the error. In the URL it&#39;s <code class="computeroutput">http://myserver.net/events/event-info.tcl</code>,
so open the file <code class="computeroutput">/var/lib/aolserver/$OPENACS_SERVICE_NAME/packages/events/www/event-info.tcl</code>.
It contains this line:</p><pre class="programlisting">
set can_register_p [events::security::can_register_for_event_p -event_id $event_id]</pre><p>We need to know what that procedure does, so go to <a class="ulink" href="/api-doc" target="_top">/api-doc</a>, paste
events::security::can_register_for_event_p into the ACS Tcl API
Search box, and click Feeling Lucky. The next pages shows the proc,
and we click "show source" to see more information. The
body of the proc is simply</p><pre class="programlisting">
return [permission::permission_p -party_id $user_id -object_id $event_id -privilege write]</pre><p>This means that a given user must have the write privilege on
the event in order to register. Let&#39;s assume that the
privileges inherit, so that if a user has the write privilege on
the whole package, they will have the write privilege on the
event.</p>
</li><li class="listitem">
<p>
<strong>Setting Permissions. </strong> A permission has
three parts: the privilege, the object of the privilege, and the
subject being granted the privilege. In this case the privilege is
"write," the object is the Events package, and the
subject is all Registered Users.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>To grant permissions on a package, start at the <a class="ulink" href="/admin/site-map" target="_top">site map</a>. Find the event
package and click "Set permissions".</p></li><li class="listitem"><p>Click "Grant Permission"</p></li><li class="listitem">
<p>Grant the write permission to Registered Users.</p><div class="figure">
<a name="idp140682182761064" id="idp140682182761064"></a><p class="title"><strong>Figure 4.2. Granting
Permissions</strong></p><div class="figure-contents"><div class="mediaobject"><img src="images/grant-perm-463.png" alt="Granting Permissions"></div></div>
</div><br class="figure-break">
</li>
</ol></div><p>OpenACS 5.0 offers a prettier version at <a class="ulink" href="/admin/applications" target="_top">/admin/applications</a>.</p><div class="figure">
<a name="idp140682182765048" id="idp140682182765048"></a><p class="title"><strong>Figure 4.3. Granting Permissions
in 5.0</strong></p><div class="figure-contents"><div class="mediaobject"><img src="images/grant-perm-50.png" alt="Granting Permissions in 5.0"></div></div>
</div><br class="figure-break">
</li>
</ul></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="configuring-configuring-permissions" leftLabel="Prev" leftTitle="Setting Permissions on an OpenACS
package"
			rightLink="upgrade" rightLabel="Next" rightTitle="Chapter 5. Upgrading"
			homeLink="index" homeLabel="Home" 
			upLink="configuring-new-site" upLabel="Up"> 
		    