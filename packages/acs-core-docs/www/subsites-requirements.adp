
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Subsites Requirements}</property>
<property name="doc(title)">Subsites Requirements</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="groups-design" leftLabel="Prev"
			title="Chapter 15. Kernel
Documentation"
			rightLink="subsites-design" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="subsites-requirements" id="subsites-requirements"></a>Subsites
Requirements</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By <a class="ulink" href="http://planitia.org" target="_top">Rafael H. Schloming</a> and
Dennis Gregorovic</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-requirements-intro" id="subsites-requirements-intro"></a>Introduction</h3></div></div></div><p>The following is a requirements document for OpenACS 4 Subsites,
part of the OpenACS 4 Kernel. The Subsites system allows one
OpenACS server instance to serve multiple user communities, by
enabling the suite of available OpenACS applications to be
customized for defined user communities.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-requirements-vision" id="subsites-requirements-vision"></a>Vision Statement</h3></div></div></div><p>Many online communities are also collections of discrete
subcommunities, reflecting real-world relationships. For example, a
corporate intranet/extranet website serves both units within the
company (e.g., offices, departments, teams, projects) and external
parties (e.g., customers, partners, vendors). Subsites enable a
single OpenACS instance to provide each subcommunity with its own
"virtual website," by assembling OpenACS packages that
together deliver a feature set tailored to the needs of the
subcommunity.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-requirements-system-overview" id="subsites-requirements-system-overview"></a>System Overview</h3></div></div></div><p>The OpenACS subsite system allows a single OpenACS installation
to serve multiple communities. At an implementation level this is
primarily accomplished by having an application "scope"
its content to a particular package instance. The <a class="link" href="rp-design" title="Request Processor Design">request
processor</a> then figures out which package_id a particular URL
references and then provides this information through the
<code class="computeroutput">ad_conn</code> api (<code class="computeroutput">[ad_conn package_id]</code>, <code class="computeroutput">[ad_conn package_url]</code>).</p><p>The other piece of the subsite system is a subsite package that
provides subsite admins a "control panel" for
administering their subsite. This is the same package used to
provide all the community core functionality available at the
"main" site which is in fact simply another subsite.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-requirements-use-cases" id="subsites-requirements-use-cases"></a>Use-cases and
User-scenarios</h3></div></div></div><p>The Subsites functionality is intended for use by two different
classes of users:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Package programmers (referred to as 'the programmer')
must develop subcommunity-aware applications.</p></li><li class="listitem"><p>Site administrators (referred to as 'the administrator')
use subsites to provide tailored "virtual websites" to
different subcommunities.</p></li>
</ol></div><p>Joe Programmer is working on the forum package and wants to make
it subsite-aware. Using [ad_conn package_id], Joe adds code that
only displays forum messages associated with the current package
instance. Joe is happy to realize that parameter::get is already
smart enough to return configuration parameters for the current
package instance, and so he has to do no extra work to tailor
configuration parameters to the current subsite.</p><p>Jane Admin maintains www.company.com. She learns of Joe&#39;s
work and would like to set up individual forums for the Boston and
Austin offices of her company. The first thing she does is use the
APM to install the new forum package.</p><p>Next, Jane uses the Subsite UI to create subsites for the Boston
and Austin offices. Then Jane uses the Subsite UI to create forums
for each office.</p><p>Now, the Boston office employees have their own forum at
http://www.company.com/offices/boston/forum, and similarly for the
Austin office. At this point, the Boston and Austin office admins
can customize the configurations for each of their forums, or they
can just use the defaults.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-requirements-links" id="subsites-requirements-links"></a>Related Links</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="xref" href="subsites-design" title="Subsites Design Document">OpenACS 4 Subsites Design
Document</a></p></li><li class="listitem"><p>Test plan (Not available yet)</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-requirements-api" id="subsites-requirements-api"></a>Requirements: Programmer&#39;s
API</h3></div></div></div><p>A subsite API is required for programmers to ensure their
packages are subsite-aware. The following functions should be
sufficient for this:</p><p><span class="strong"><strong>10.10.0 Package
creation</strong></span></p><p>The system must provide an API call to create a package, and it
must be possible for the context (to which the package belongs) to
be specified.</p><p><span class="strong"><strong>10.20.0 Package
deletion</strong></span></p><p>The system must provide an API call to delete a package and all
related objects in the subsite&#39;s context.</p><p><span class="strong"><strong>10.30.0 Object&#39;s package
information</strong></span></p><p>Given an object ID, the system must provide an API call to
determine the package (ID) to which the object belongs.</p><p><span class="strong"><strong>10.40.0 URL from
package</strong></span></p><p>Given a package (ID), the system must provide an API call to
return the canonical URL for that package.</p><p><span class="strong"><strong>10.50.0 Main subsite&#39;s
package_id</strong></span></p><p>The system must provide an API call to return a package ID
corresponding to the main subsite&#39;s package ID (the degenerate
subsite).</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-requirements-ui" id="subsites-requirements-ui"></a>Requirements: The User
Interface</h3></div></div></div><p><span class="strong"><strong>The Programmer&#39;s User
Interface</strong></span></p><p>There is no programmer&#39;s UI, other than the API described
above.</p><p><span class="strong"><strong>The Administrator&#39;s User
Interface</strong></span></p><p>The UI for administrators is a set of HTML pages that are used
to drive the underlying API for package instance management (i.e.
adding, removing, or altering packages). It is restricted to
administrators of the current subsite such that administrators can
only manage their own subsites. Of course, Site-Wide Administrators
can manage all subsites.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p><span class="strong"><strong>20.10.0 Package
creation</strong></span></p><p>
<span class="strong"><strong>20.10.1</strong></span> The
administrator should be able to create a package and make it
available at a URL underneath the subsite.</p>
</li><li class="listitem">
<p><span class="strong"><strong>20.20.0 Package
deactivation</strong></span></p><p>
<span class="strong"><strong>20.20.1</strong></span> The
administrator should be able to deactivate any package, causing it
to be inaccessible to users.</p><p>
<span class="strong"><strong>20.20.5</strong></span>
Deactivating a package makes the package no longer accessible, but
it does not remove data created within the context of that
package.</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-requirements-rev-history" id="subsites-requirements-rev-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>Document Revision
#</strong></span></td><td><span class="strong"><strong>Action Taken,
Notes</strong></span></td><td><span class="strong"><strong>When?</strong></span></td><td><span class="strong"><strong>By Whom?</strong></span></td>
</tr><tr>
<td>0.1</td><td>Creation</td><td>08/18/2000</td><td>Dennis Gregorovic</td>
</tr><tr>
<td>0.2</td><td>Edited, reviewed</td><td>08/29/2000</td><td>Kai Wu</td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="groups-design" leftLabel="Prev" leftTitle="Groups Design"
			rightLink="subsites-design" rightLabel="Next" rightTitle="Subsites Design Document"
			homeLink="index" homeLabel="Home" 
			upLink="kernel-doc" upLabel="Up"> 
		    