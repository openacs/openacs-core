
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Request Processor Requirements}</property>
<property name="doc(title)">Request Processor Requirements</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="security-notes" leftLabel="Prev"
			title="Chapter 15. Kernel
Documentation"
			rightLink="rp-design" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="rp-requirements" id="rp-requirements"></a>Request Processor Requirements</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By <a class="ulink" href="http://planitia.org" target="_top">Rafael H.
Schloming</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-requirements-intro" id="rp-requirements-intro"></a>Introduction</h3></div></div></div><p>The following is a requirements document for the OpenACS 4.0
request processor. The major enhancements in the 4.0 version
include a more sophisticated directory mapping system that allows
package pageroots to be mounted at arbitrary urls, and tighter
integration with the database to allow for flexible user controlled
url structures, and subsites.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-requirements-vision" id="rp-requirements-vision"></a>Vision Statement</h3></div></div></div><p>Most web servers are designed to serve pages from exactly one
static pageroot. This restriction can become cumbersome when trying
to build a web toolkit full of reusable and reconfigurable
components.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-requirements-system-overview" id="rp-requirements-system-overview"></a>System Overview</h3></div></div></div><p>The request processor&#39;s functionality can be split into two
main pieces.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>Set up the environment in which a server side script expects to
run. This includes things like:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Initialize common variables associated with a request.</p></li><li class="listitem"><p>Authenticate the connecting party.</p></li><li class="listitem"><p>Check that the connecting party is authorized to proceed with
the request.</p></li><li class="listitem"><p>Invoke any filters associated with the request URI.</p></li>
</ul></div>
</li><li class="listitem"><p>Determine to which entity the request URI maps, and deliver the
content provided by this entity. If this entity is a proc, then it
is invoked. If this entitty is a file then this step involves
determining the file type, and the manner in which the file must be
processed to produce content appropriate for the connecting party.
Eventually this may also require determining the capabilities of
the connecting browser and choosing the most appropriate form for
the delivered content.</p></li>
</ol></div><p>It is essential that any errors that occur during the above
steps be reported to developers in an easily decipherable
manner.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-requirements-links" id="rp-requirements-links"></a>Related Links</h3></div></div></div><p><a class="xref" href="rp-design" title="Request Processor Design">OpenACS 4 Request Processor
Design</a></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-requirements-req" id="rp-requirements-req"></a>Requirements</h3></div></div></div><p><span class="strong"><strong>10.0 Multiple
Pageroots</strong></span></p><div class="blockquote"><blockquote class="blockquote">
<p>
<span class="strong"><strong>10.10</strong></span> Pageroots may
be combined into one URL space.</p><p>
<span class="strong"><strong>10.20</strong></span> Pageroots may
be mounted at more than one location in the URL space.</p>
</blockquote></div><p><span class="strong"><strong>20.0 Application
Context</strong></span></p><div class="blockquote"><blockquote class="blockquote"><p>
<span class="strong"><strong>20.10</strong></span> The request
processor must be able to determine a primary context or state
associated with a pageroot based on it&#39;s location within the
URL space.</p></blockquote></div><p><span class="strong"><strong>30.0
Authentication</strong></span></p><div class="blockquote"><blockquote class="blockquote"><p>
<span class="strong"><strong>30.10</strong></span> The request
processor must be able to verify that the connecting browser
actually represents the party it claims to represent.</p></blockquote></div><p><span class="strong"><strong>40.0
Authorization</strong></span></p><div class="blockquote"><blockquote class="blockquote"><p>
<span class="strong"><strong>40.10</strong></span> The request
processor must be able to verify that the party the connecting
browser represents is allowed to make the request.</p></blockquote></div><p><span class="strong"><strong>50.0
Scalability</strong></span></p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="security-notes" leftLabel="Prev" leftTitle="Security Notes"
			rightLink="rp-design" rightLabel="Next" rightTitle="Request Processor Design"
			homeLink="index" homeLabel="Home" 
			upLink="kernel-doc" upLabel="Up"> 
		    