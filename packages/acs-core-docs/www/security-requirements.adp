
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Security Requirements}</property>
<property name="doc(title)">Security Requirements</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="i18n-requirements" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="security-design" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="security-requirements" id="security-requirements"></a>Security
Requirements</h2></div></div></div><div class="authorblurb">
<p>By Richard Li</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="security-requirements-intro" id="security-requirements-intro"></a>Introduction</h3></div></div></div><p>This document lists the requirements for the security system for
the OpenACS.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="security-requirements-vision" id="security-requirements-vision"></a>Vision Statement</h3></div></div></div><p>Virtually all web sites support personalized content based on
user identity. The level of personalization may be as simple as
displaying the name of the user on certain pages or can be as
sophisticated as dynamically recommending sections of site that the
user may be interested in based on prior browsing history. In any
case, the user&#39;s identity must be validated and made available
to the rest of the system. In addition, sites such as ecommerce
vendors require that the user identity be securely validated.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="security-requirements-system-overview" id="security-requirements-system-overview"></a>Security System
Overview</h3></div></div></div><p>The security system consists of a number of subsystems.</p><p><span class="strong"><strong>Signed Cookies</strong></span></p><p>Cookies play a key role in storing user information. However,
since they are stored in plaintext on a user&#39;s system, the
validity of cookies is an important issue in trusting cookie
information. Thus, we want to be able to validate a cookie, but we
also want to validate the cookie without a database hit.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>10.0 Guaranteed Tamper
Detection</strong></span> Any tampering of cookie data should be
easily detectable by the web server.</p></li><li class="listitem"><p>
<span class="strong"><strong>10.1 Performance and
Scalability</strong></span> Validation and verification of the
cookie should be easily scalable and should not require a database
query on every hit.</p></li>
</ul></div><p><span class="strong"><strong>Session
Properties</strong></span></p><p>Applications should be able to store session-level properties in
a database table.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>11.0 Storage API</strong></span>
Session-level data should be accessible via an API.</p></li><li class="listitem"><p>
<span class="strong"><strong>11.1 Purge
Mechanism</strong></span> An efficient pruning mechanism should be
used to prevent old session level properties from filling up the
table.</p></li>
</ul></div><p><span class="strong"><strong>Login</strong></span></p><p>The security system should support the concept of persistent
user logins. This persistence takes several forms.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>12.0 Permanent
Login</strong></span> Users should be able to maintain a permanent
user login so that they never need to type their password.</p></li><li class="listitem"><p>
<span class="strong"><strong>12.1 Session Login</strong></span>
The security system should support the concept of a session, with
authentication tokens that become invalid after a certain period of
time.</p></li><li class="listitem"><p>
<span class="strong"><strong>12.2 Session
Definition</strong></span> A session is a sequence of clicks by one
user from one browser in which no two clicks are separated by more
than some constant (the session timeout).</p></li><li class="listitem"><p>
<span class="strong"><strong>12.3 Stateless</strong></span> The
security system should not require state that is stored in the
server. Required state may reside only in the user request
(including cookies), and in the database. A single user should be
able to log in to the system even if the user is sent to a
different AOLserver for each step of the login process (e.g., by a
load balancer).</p></li><li class="listitem"><p>
<span class="strong"><strong>12.4 Secure</strong></span> The
security system should not store passwords in clear text in the
database.</p></li>
</ul></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p>
<span class="strong"><strong>13.0 SSL Hardware</strong></span>
The system must work when the SSL processing occurs outside of the
web server (in specialized hardware, in a firewall, etc.).</p></li></ul></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="i18n-requirements" leftLabel="Prev" leftTitle="OpenACS Internationalization
Requirements"
		    rightLink="security-design" rightLabel="Next" rightTitle="Security Design"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		