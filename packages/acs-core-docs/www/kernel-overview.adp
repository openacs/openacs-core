
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Overview}</property>
<property name="doc(title)">Overview</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="kernel-doc" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="object-system-requirements" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="kernel-overview" id="kernel-overview"></a>Overview</h2></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The <span class="emphasis"><em>OpenACS Kernel</em></span>, which
handles system-wide necessities such as metadata, security, users
and groups, subsites, and package management and deployment.</p></li><li class="listitem"><p>The <span class="emphasis"><em>OpenACS Core</em></span>, which
comprises all the other packages that ship with the kernel and are
most frequently needed by users, such as templating, forums, and
user registration/management. The packages tend to be developed and
distributed with the kernel.</p></li><li class="listitem"><p>
<span class="emphasis"><em>OpenACS Application
packages</em></span>, which typically provide user-level web
services built on top of the Kernel and Core. Application packages
are developed separately from the Kernel, and are typically
released independently of it.</p></li>
</ul></div><p>This document provides a high level overview of the kernel
package. <a class="ulink" href="index" target="_top">Documentation for other packages on this server</a>
</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="kernel-doc" leftLabel="Prev" leftTitle="
Chapter 15. Kernel Documentation"
		    rightLink="object-system-requirements" rightLabel="Next" rightTitle="Object Model Requirements"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		