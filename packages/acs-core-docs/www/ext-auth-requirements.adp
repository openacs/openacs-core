
<property name="context">{/doc/acs-core-docs {Documentation}} {External Authentication Requirements}</property>
<property name="doc(title)">External Authentication Requirements</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="bootstrap-acs" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="releasing-openacs" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="ext-auth-requirements" id="ext-auth-requirements"></a>External
Authentication Requirements</h2></div></div></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140480084369136" id="idp140480084369136"></a>Vision</h3></div></div></div><p>People have plenty of usernames and passwords already, we don't
want them to have yet another. We want people to be able to log in
to OpenACS with the same password they use to log in to any other
system.</p><p>Besides, administrators have better things to do than create
accounts for people. So we want them to be able to create just one
account on a central server (e.g. LDAP or RADIUS), and when they
log on to OpenACS, an account will automatically be created for
them here.</p><p>Finally, security is increased with fewer passwords, since users
generally can't remember all those passwords, so they tend to keep
them all the same and never change them.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="Design_Goal" id="Design_Goal"></a>Design
Goals</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Transparent: Users don't have to do anything special to get an
account on the local OpenACS system, if they already have an
account on the external authentication server.</p></li><li class="listitem"><p>Fall-back: Users who don't have an account on the external
authentication server are still allowed to create a local account
on OpenACS. This could be for external students who should have
access to .LRN, but not to the rest of the university's
resources.</p></li><li class="listitem"><p>Authentication Client Only: We want OpenACS to be able to
authenticate by asking some remote authority to verify the user's
username/password combination. The goal is explicitly <span class="emphasis"><em>not</em></span> (at this point) to have OpenACS act
as an authentication server for other systems, although this could
be easily added later. The goal is also <span class="emphasis"><em>not</em></span> to devise an infrastructure for
letting OpenACS access resources in various other systems on the
user's behalf, such as IMAP, iCalendar, SMB file servers, etc.,
although this is definitely an interesting use-case.</p></li><li class="listitem"><p>Easy configuration: We would like people to be able to configure
this without having to write code. In particular, we want to build
drivers that know how to talk with LDAP, RADIUS, PAM, etc., and
which won't have to be locally modified. Only configuration and
policies should change, code should not.</p></li><li class="listitem"><p>Usability: The solution must be easy to use for end users and
administrators alike. There's frequently a positive feedback effect
between usability and security, because when authentication schemes
have poor usability, users will think up ways to circumvent
them.</p></li><li class="listitem"><p>Open and modular: The design should be on the one hand open to
add other authentification mechanisms when needed and on the other
hand very modular to enable a start with minimal requirements
(driver implementations) as soon as possible.</p></li>
</ul></div><p>The problem can be split into several logically separate parts.
Each has a section below.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="Terminology" id="Terminology"></a>Terminology</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Authority: The name of an authority trusted to authenticate
users.</p></li><li class="listitem"><p>Authentication Driver: An implementation of the authentication
service contract, which talks to an authentication of a certain
type, e.g. PAM, RADIUS, LDAP, or Active Directory.</p></li><li class="listitem"><p>Authentication API: The API through which login pages and
applications talk to the authentication service. There's one and
only one implementation of the authentication API, namly the one
included in OpenACS Core.</p></li><li class="listitem"><p>Authentication Driver API: The service contract which
authentication drivers implement.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="Diagram" id="Diagram"></a>Conceptual
Pictures</h3></div></div></div><p>Authentication:</p><p><span class="inlinemediaobject"><img src="images/ext-auth.png"></span></p><p>Account Management (NO PICTURE YET)</p><p>Batch Synchronization (NO PICTURE YET)</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="Requirements" id="Requirements"></a>Requirements</h3></div></div></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140480084271664" id="idp140480084271664"></a>New API</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>New API</th></tr></thead><tbody>
<tr class="seglistitem">
<td class="seg">EXT-AUTH-01</td><td class="seg">A</td><td class="seg">Extend Authentication/Acct Status API</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-03</td><td class="seg">A</td><td class="seg">Account Creation API</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-05</td><td class="seg">A</td><td class="seg">Password Management API</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-30</td><td class="seg">A</td><td class="seg">Authority Management API</td>
</tr>
</tbody>
</table></div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Login" id="Login"></a>Login</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>Login</th></tr></thead><tbody>
<tr class="seglistitem">
<td class="seg">EXT-AUTH-04</td><td class="seg">A</td><td class="seg">Rewrite login, register, and admin pages to use
APIs</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-38</td><td class="seg">A</td><td class="seg">ad_form complain feature</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-19</td><td class="seg">A</td><td class="seg">Rewrite password recovery to use API</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-21</td><td class="seg">A</td><td class="seg">Rewrite email verification with API</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-28</td><td class="seg">A</td><td class="seg">Username is email switch</td>
</tr>
</tbody>
</table></div><p>Users will log in using a username, a authority, and a password.
The authority is the source for user/password verification. OpenACS
can be an authority itself.</p><p>Each user in OpenACS will belong to exactly one authority, which
can either be the "local" OpenACS users table, in which case the
password column is used, or it can be some external authority,
which will be communicated with using some protocol, as implemented
by an authentication driver.</p><p>Username will be separate from email address. It can be an email
address, it can look like an email address but not be the name of
an actual email mailbox, or it can be something else entirely.</p><p>We're assuming that user information (name, email, etc.) will
either already be in the users table through a batch
synchronization job, or that the relevant authentication
implementation supports real-time synchronization of user data.
Specifically, if you want remote users who haven't yet logged in to
OpenACS to show up in user searches, you'll have to do the batch
synchronization.</p><p>All in all, the login box will be an includeable template and
look like this:</p><pre class="programlisting">
Username:  ________
Password:  ________
Authority: [URZ   ]
            Athena
            Local

[Forgot my password]
[New user registration]
</pre><p>If there's only one active authority, we don't display the
authority drop-down element at all.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Configuratio" id="Configuratio"></a>Configuration</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>Configuration</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-07</td><td class="seg">A</td><td class="seg">Admin pages to control Ext-Auth parameters</td>
</tr></tbody>
</table></div><p>The site-wide systems administrator can configure the
authentication process from a page linked under /acs-admin.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Authorities - ordered list of authorities defined</p></li><li class="listitem"><p>Account Registration Allowed: Yes/No. Account registration can
be disabled altogether.</p></li><li class="listitem"><p>Registration authority - the authority in which accounts should
be created, using the relevant driver, if account registration is
allowed.</p></li><li class="listitem"><p>Username is email? - instead of asking for username, we'll ask
for email. And we'll store the value in both columns, username and
email. This is a setting that spans all authorities, and is
primarily meant for backwards compatibility with the old OpenACS
login process.</p></li>
</ul></div><p>The local authority driver is an encapsulation of current
functionality within an driver matching a service contract. The
other drivers call external functions. The possible functions for
each authority are split into several drivers for convenience. One
driver handles authentication, one account creation, and one
changing passwords.</p><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>create service contract</th></tr></thead><tbody>
<tr class="seglistitem">
<td class="seg">EXT-AUTH-16</td><td class="seg">A</td><td class="seg">Create service contract for Authentication</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-17</td><td class="seg">A</td><td class="seg">Create service contract for Acct. Creation</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-29</td><td class="seg">A</td><td class="seg">Create service contract for Passwd Management</td>
</tr>
</tbody>
</table></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th></th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-18</td><td class="seg">A</td><td class="seg">Authority configuration data model</td>
</tr></tbody>
</table></div><p>Each authority is defined like this:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Authority pretty-name, e.g. "URZ"</p></li><li class="listitem"><p>Authentication Driver, e.g. "RADIUS". In practice, this would be
a reference to a service contract implementation.</p></li><li class="listitem"><p>Authentication Driver configuration settings, e.g. host name,
port, etc., as required by the particular driver. Note that this is
per authority, not per driver, i.e., you can have multiple
authorities with the same driver but different configuration
options.</p></li><li class="listitem"><p>AuthenticationAllowed - true/false, so you can disable login
through some authority without having to delete the authority, and
hence also all the users who belong to that authority.</p></li><li class="listitem"><p>ForgottenPasswordUrl - a URL to redirect to instead of trying to
use the authentication driver's password management features.</p></li><li class="listitem"><p>ChangePasswordUrl - a URL to redirect to instead of trying to
use the authentication driver's password management features.</p></li><li class="listitem"><p>Account Creation Driver, e.g. "RADIUS". In practice, this would
be a reference to a service contract implementation. The reason we
have separate drivers for authentication and account creation is
that organizations are likely to have a home-grown account
registration process.</p></li><li class="listitem"><p>Account Creation Driver configuration settings, e.g. host name,
port, etc., as required by the particular driver. Note that this is
per authority, not per driver, i.e., you can have multiple
authorities with the same driver but different configuration
options.</p></li><li class="listitem"><p>RegistrationUrl - instead of registering using OpenACS, redirect
to a certain URL site for account registration.</p></li><li class="listitem"><p>RegistrationAllowed - true/false, so you can disable
registration using this account.</p></li><li class="listitem"><p>Sort order: Preference order of authorities.</p></li><li class="listitem"><p>HelpContactText: Text or HTML to be displayed when user has
trouble authenticating with the authority. Should include contact
information such as a phone number or email.</p></li>
</ul></div><p>Each authority driver will have a set of configuration options
dependent on the driver, such as host, port, etc. We will need to
find a mechanism for the driver to tell us which configuration
options are available, a way to set these, and a way for the driver
to access these settings.</p><p>OpenACS will come pre-configured with one authority, which is
the "local" authority, meaning we'll authenticate as normal using
the local users table. This will, just like any other authority, be
implemetned using a service contract.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Synchronizing_and_Linking_User" id="Synchronizing_and_Linking_User"></a>Synchronizing and Linking
Users</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>Synchronizing and linking users</th></tr></thead><tbody>
<tr class="seglistitem">
<td class="seg">EXT-AUTH-28</td><td class="seg">A</td><td class="seg">Create service contract for Batch Sync.</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-38</td><td class="seg">A</td><td class="seg">Batch User Synchronization API</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-38</td><td class="seg">A</td><td class="seg">IMS Synchronization driver</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-08</td><td class="seg">A</td><td class="seg">Automation of batch Synchronization</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-15</td><td class="seg">B</td><td class="seg">On-demand syncronization</td>
</tr>
</tbody>
</table></div><p>Regardless of the login method, the user needs to have a row in
the OpenACS users table. This can happen through a batch job, in
real-time, or both in combination. We use the <a class="ulink" href="http://ims.edna.edu.au/enterprise/" target="_top">IMS
Enterprise 1.1</a> specification.</p><p>Batch job means that we do a synchronization (import new users,
modify changed, purge deleted) on a regular interval, e.g. every
night. You can also decide to have a monthly full synchronization,
plus daily incremental ones. That's up to you. The advantage is
that you have all users in OpenACS, so when you search for a user,
you'll see all the organization's users, not just those who happen
to have used the OpenACS-based system. The down-side is that it
takes some time for user information to propagate. This can be
remedied by using the real-time solution. The batch job will also
require error logging and an admin interface to view logs.</p><p>If an email already belongs to some other user, we log it as an
error.</p><p>A user will always belong to exactly one authority, which can be
either the "local" authority or some other. Thus, the OpenACS
user's table will have to be augmented with the following
columns:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Authority. Reference to the site-wide authorities list. The
authority which can authenticate this user.</p></li><li class="listitem"><p>Authority-specific username.</p></li>
</ul></div><p>Real-time means that the first time the user logs into OpenACS,
we'll query the authority that authenticated him for information
about this user. That authentication authority will then give us at
least first names, last name and email. The pros and cons are the
opposite of batch jobs. Using both in combination is ideal.</p><p>Note: One solution to the "two users from different authorities
have the same email" problem above would be to allow users to
belong to multiple authorities. Then we would notice that the email
already exists, ask the user if he thinks he's the same person, and
if so, ask him to prove so by authenticating using the other
authority. Thus he'll have just authenticated in two different
authorities, and we can record that this is the same person. We'd
still have a problem if there was an email conflict between two
accounts on the same authority. Hm. I don't think it's worth
spending too much time trying to solve this problem through
software.</p><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-31</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-31</td><td class="seg">A</td><td class="seg">Upgrade user data model for ext-auth</td>
</tr></tbody>
</table></div><p>After having authenticated using the relevant authority driver,
we'll look for the username/authority pair in the users table.</p><p>If we don't find any, that means that we're either not doing
batch synchronizing, or that the user has been added since the last
sync. In that case, we'll try to do a real-time synchronization, if
the driver supports it. If it does, it'll return email,
first_names, last_name, and other relevant information, and we'll
create a row in the local users table using that information.</p><p>If that doesn't work, we'll tell the user that their account
isn't yet available, and the driver will supply a message for us,
which could say "The account should be available tomorrow. If not,
contact X."</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Account_Registratio" id="Account_Registratio"></a>Account Registration</h4></div></div></div><p>If a user doesn't have an account, the site-wide configuration
can allow the user to register for one, as defined in the
configuration discussed above. This section is about normal account
registration through a authority driver.</p><p>The account creation service contract implementation will need
to tell us which information to ask the user for:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Required Fields: A list of fields which are required.</p></li><li class="listitem"><p>Optional Fields: A list of fields which are optional.</p></li>
</ul></div><p>The fields to choose from are these:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Username</p></li><li class="listitem"><p>First names</p></li><li class="listitem"><p>Last name</p></li><li class="listitem"><p>Email</p></li><li class="listitem"><p>URL</p></li><li class="listitem"><p>Password</p></li><li class="listitem"><p>Secret question</p></li><li class="listitem"><p>Secret answer</p></li>
</ul></div><p>It should return the following:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Creation status (OK, Try-Again, Fail)</p></li><li class="listitem"><p>Creation message: What went wrong, or a welcome message.</p></li><li class="listitem"><p>Account status: Is the account ready for use?</p></li><li class="listitem"><p>User information: first_names, last_name, email, url, password,
password_hash, secret_question, secret_answer. The driver only
needs to return the columns which were changed or added through the
registration process. Typically, only the "local" driver will
return password and secret question/answer.</p></li>
</ul></div><p>After creating the remote account, a local account is created
with the information gathered through the form/returned by the
driver.</p><p>By default, a local account creation implementation is provided,
which will create a new OpenACS user, and, in addition to the
default local account creation above, also store the password in
hashed form.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Password_Managemen" id="Password_Managemen"></a>Password Management</h4></div></div></div><p>Password management is about changing password, retrieving
password, and resetting password.</p><p>It's up to the authority driver implementation to decide whether
to support any or all of these features, and to say so using the
CanXXX methods (see driver API below).</p><p>Additionally, the authority can be configured with a URL to
redirect to in the case of forgotten passwords, or when the user
desires to change password.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Login_Pages_Over_HTTP" id="Login_Pages_Over_HTTP"></a>Login Pages Over HTTPS</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-20</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-20</td><td class="seg">A</td><td class="seg">Login over HTTPS</td>
</tr></tbody>
</table></div><p>Login pages must be able to be sent over a secure connection
(https), so your password won't get sent over the wire in
cleartext, while leaving the rest of the site non-secure (http). I
believe that this requires some (minor) changes to the current
session handling code.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Email_Verificatio" id="Email_Verificatio"></a>Email Verification</h4></div></div></div><p>Email verification needs to be handled both at registration and
at login.</p><p>In both cases, it'll be handled by the driver sending
automatically sending the email containing a link for the user to
verify his account. Then the driver will return an account status
of "closed,temporary", and a message that says "Check your inbox
and click the link in the email".</p><p>OpenACS will have a page which receives the email verification,
for use by local accounts. Other authorities will have to implement
their own page, most likely on the authority's own server.</p>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="Other_Item" id="Other_Item"></a>Other
Items</h3></div></div></div><p>There are a number of items which touch on external
authentication and session management. And even though they're not
directly linked to external authentication, I would recommend that
we handle a number of them, either because they're important for
security, or because it makes sense to fix them while we're messing
with this part of the codebase anyway.</p><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Recommended__Untrusted_Logins_and_Login_Leve" id="Recommended__Untrusted_Logins_and_Login_Leve"></a>Recommended:
Untrusted Logins and Login Levels</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-33</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-33</td><td class="seg">A</td><td class="seg">Untrusted Logins</td>
</tr></tbody>
</table></div><p>I like the idea of having multiple login levels:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Not logged in</p></li><li class="listitem"><p>Untrusted login: We'll show you un-sensitive personal content,
but won't let you modify anything or see personal data. A normal
login becomes untrusted after a certain amount of time, and the
user will have to re-enter his/her password in order to gain access
to personal data. Untrusted login never expires, unless explicitly
done so through either changing password or clicking a special
"expire all logins" link.</p></li><li class="listitem"><p>Normal login: The user is logged, and has type his password
sufficiently recently that we trust the login. All normal
operations are allowed. Will degrade to untrusted login after a
specified amount of time.</p></li><li class="listitem"><p>Secure login: The user is logged in over a secure connection
(HTTPS), potentially even using a special secure password. This
would be for sensitive actions, such as credit card
transactions.</p></li>
</ol></div><p>There are two advantages to this. First, when people's login
expires, we can ask them to re-enter only their password, and not
both username and password, since we'll still remember who they
were the last time their login was valid. This is a much faster
operation (the password input field will be focused by default, so
you just type your password and hit Return) that typing both
username and password, which will make it practical to have your
site configured to expire people's login after e.g. 2, 4, or 8
hours.</p><p>The other advantage is that we can still offer certain
functionality to you, even when your login is not trusted. For
example, we could let you browse publically available forums, and
only when you want to post do you need to log in. This makes it
even more feasible to have a more secure login expiration
setting.</p><p>By default, <code class="literal">auth::require_login</code>
would bounce to the login page if the user is only logged in at the
untrusted level. Only if you explicitly say <code class="literal">auth::require_login -untrusted</code> will we give you
the user_id of a user who's only logged in in untrusted mode.</p><p>Similarly, <code class="literal">ad_conn user_id</code> will
continue to return 0 (not logged in) when the user is only logged
in untrusted, and we'll supply another variable, <code class="literal">ad_conn untrusted_user_id</code>, which wlll be set to
the user_id for all login levels.</p><p>This should ensure that we get full access to the new feature,
while leaving all current code just as secure as it was before.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Recommended__Make_Non-Persistent_Login_Wor" id="Recommended__Make_Non-Persistent_Login_Wor"></a>Recommended: Make
Non-Persistent Login Work</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-34</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-34</td><td class="seg">A</td><td class="seg">Expire Logins</td>
</tr></tbody>
</table></div><p>Currently, OpenACS is unusable in practice without persistent
login. The login will expire after just a few minutes of
inactivity, and you'll get bounced to the login page where you have
to enter both email and password again. Unacceptable in
practice.</p><p>We should change the default, so a non-persistent login doesn't
expire until you either close your browser, or a few hours have
elapsed. Even if you are constantly active, the login should still
expire after at most x number of hours. We can still make the login
expire after a period of inactivity, but the amount of time should
be configurable and default to something reasonable like an hour or
so.</p><p>This will require looking into and changing the design of the
current session handling code.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Recommended__Single-Sign-O" id="Recommended__Single-Sign-O"></a>Recommended: Single-Sign-On</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-23</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-23</td><td class="seg"></td><td class="seg">Single sign-on</td>
</tr></tbody>
</table></div><p>Instead of redirecting to the login page, auth::require_login
can redirect to an authentication server, which can redirect back
to a page that logs the user in. This should be very easy to
implement.</p><p>Alternatively, if you want to combine this with fallback to
OpenACS accounts, we would instead present the normal login screen,
but put a button which says "Login using X", where X is the
redirection-based external authority.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Recommended__Expire_All_Login" id="Recommended__Expire_All_Login"></a>Recommended: Expire All
Logins</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-22</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-22</td><td class="seg">B</td><td class="seg">rewrite cookie handling</td>
</tr></tbody>
</table></div><p>Currently, if you've ever left a permanent login cookie on
someone elses machine, that person will be forever logged in until
he/she explicitly logs out. You can change your password, you can
do anything you want, but unless a logout is requested from that
particular browser, that browser will be logged in forever.</p><p>I want to change our session handling code so that old login
cookies can be expired. This would be done automatically whenever
you change your password, and we could also offer a link which does
this without changing passwords. It's an important security
measure.</p><p>The implementation is simply to autogenerate some secret token
which is stored in the users table, and is also stored in the
cookie somehow. Then, whenever we want to expire all logins, we'll
just regenerate a new secret token, and the other cookies will be
void. Of course, we don't want to incur a DB hit on every request,
so we'll need to cache the secret token, or only check it when
refreshing the session cookie, which, I believe, normally happens
every 10 minutes or so.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Recommended__Email_account_owner_on_password" id="Recommended__Email_account_owner_on_password"></a>Recommended:
Email account owner on password change</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-24</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-24</td><td class="seg">A</td><td class="seg">Email on password change</td>
</tr></tbody>
</table></div><p>As an additional security measure, we should email the account's
email address whenever the password is changed, so that he/she is
at least alerted to the fact.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Optional__Password_polic" id="Optional__Password_polic"></a>Optional: Password policy</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-25</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-25</td><td class="seg">A</td><td class="seg">Implement password policy</td>
</tr></tbody>
</table></div><p>Again, to increase security, we should add password policies,
such as passwords needing to be changed after a certain number of
days, change on next login (after a new random password has been
generated), or requiring that the password satisfies certain
complexity rules, i.e. both upper and lowercase characters,
numbers, special chars, etc.</p><p>It would good to extend the current maximum password length from
10 to at least 32 characters.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Optional__Login_Without_Explicit_Domai" id="Optional__Login_Without_Explicit_Domai"></a>Optional: Login
Without Explicit Authority</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-26</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-26</td><td class="seg">B</td><td class="seg">Login without explicit domain</td>
</tr></tbody>
</table></div><p>In order to make it easier for people, we've been toying with
the idea of a functionality like this:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>If the user enters "foobar\@ix.urz.uni-heidelberg.de", it is
translated to mean username = "foobar", authority =
"ix.urz.uni-heidelberg.de".</p></li><li class="listitem"><p>If the user enters "foobar", it's recognized to not include any
authority, and the default authority of "ix.urz.uni-heidelberg.de"
is used.</p></li><li class="listitem"><p>If the user enters "foo\@bar.com", it's recognized as not
belonging to any known authority, and as such, it's translated to
mean username = "foo\@bar.com", authority = "local".</p></li>
</ul></div><p>If this is deemed desirable, a way to implement this would be
through these settings:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Split: A regexp which will split the user's entry into username
and authority parts. For example "^([^\@]+)(\@[^\@]+)?$". An easier to
use but less flexible method would be that you simply specify a
certain character to split by, such as "\@" or "\". If the regexp
doesn't match, or in the latter case, if there's more than one
occurrence of the specified character sequence, the split will
fail, signaling that the user's entry was not valid.</p></li><li class="listitem"><p>Default authority: The default authority will be the first one
in the sort order.</p></li>
</ul></div><p>The relevant code in user-login.tcl would look like this:</p><pre class="programlisting">
if { ![auth::split_username -username_var username -authority_var authority] } {
    # bounce back to the form with a message saying that the login wasn't valid.
    ad_script_abort
}

# username will now contain username
# authority will now contain authority
</pre>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Optional__Whois_Onlin" id="Optional__Whois_Onlin"></a>Optional: Who's Online</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-27</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-27</td><td class="seg">B</td><td class="seg">Who's online list</td>
</tr></tbody>
</table></div><p>While we're touching the session handling code, anyway, it would
be nice to add a feature to show who's currently online, a nice
real-time collaboration feature frequently requested by members of
the community. This is particularly interesting when integrated
with a chat or instant messaging service like Jabber.</p><p>What I'm concretely suggesting is that we keep a record of which
authenticated users have requested pags on the site in the last x
minutes (typically about 5), and thus are considered to be
currently online. There's nothing more to it. This lets us display
a list of "active users" somewhere on the site, and make their name
a link to a real-time chat service like Jabber.</p><p>We've already made the changes necessary to security-procs.tcl
to do this on an earlier project, but haven't quite finished the
work and put it back into the tree.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Optional__Subsite-level_configuratio" id="Optional__Subsite-level_configuratio"></a>Optional:
Subsite-level configuration</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-28</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-28</td><td class="seg"></td><td class="seg">implement subsite-level config</td>
</tr></tbody>
</table></div><p>If we want to, we could let subsite administrators configure the
login process for that particular subsite. This would probably only
entail letting the subsite admin leave out certain authorities
defined site-wide, and change the sort order.</p><p>I think we should leave this out until we have a use case for
it, someone who'd need it.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Future__Making_the_Authentication_API_itself" id="Future__Making_the_Authentication_API_itself"></a>Future: Making
the Authentication API itself a service contract</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-32</th></tr></thead><tbody>
<tr class="seglistitem">
<td class="seg">EXT-AUTH-32</td><td class="seg">A</td><td class="seg">Parameters for Service Contract Implementation</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-35</td><td class="seg">A</td><td class="seg">Make the Authentication API a service contract</td>
</tr>
</tbody>
</table></div><p>For completely free-form authentication logic and mechanisms,
something like Andrew Grumet's <a class="ulink" href="http://openacs.org/new-file-storage/download/oacs-pam.html?version_id=687" target="_top">Pluggable Authentication for OACS Draft</a> is
interesting. He's proposing a scheme where the entire user
interaction is encapsulated in, and left entirely to, a service
contract. This certainly opens up more advanced possibilities, such
as perhaps smart cards, personal certificates, etc.</p><p>I have chosen not to go this route, because I think that most
people are going to want to use a username/password-based scheme,
and having easy configuration through a web UI is more important
than total flexibility at this point.</p><p>Besides, we can always do this in the future, by letting the
public Authentication API (<code class="literal">auth::require_login</code> and <code class="literal">auth::authenticate</code>) be implemented through a
service contract.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Future__Authenticating_against_multiple_serv" id="Future__Authenticating_against_multiple_serv"></a>Future:
Authenticating against multiple servers simultaneously</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>EXT-AUTH-36</th></tr></thead><tbody><tr class="seglistitem">
<td class="seg">EXT-AUTH-36</td><td class="seg">A</td><td class="seg">Authenticate against multiple servers</td>
</tr></tbody>
</table></div><p>Both OKI and OpenACS supports a form of stacking, where you can
be logged into multiple authorities at the same time. This is
useful if, for example, you need to get login tokens such as
Kerberos tickets for access to shared resources.</p><p>I can see the value in this, but for simplicity's sake, I'm in
favor of keeping this use-case out of the loop until we have
someone with a real requirement who could help us guide
development.</p><p>For now, OpenACS is still more of an integrated suite, it
doesn't access many outside applications. I think it would be
excellent for OpenACS to do so, e.g. by using an IMAP server to
store emails, an iCal server to store calendar appointments, LDAP
for user/group data and access control lists, SMB for file storage,
etc. But at the moment, we don't have any users of such things that
are ready. We have some who are on the steps, but let's wait till
they're there.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Implement_Specific_Driver" id="Implement_Specific_Driver"></a>Implement Specific Drivers</h4></div></div></div><div class="segmentedlist"><table border="1" cellpadding="3" cellspacing="0" width="90%">
<tr>
<th width="15%">Feature</th><th width="8%">Status</th><th width="77%">Description</th>
</tr><thead><tr><th>Implement specific drivers</th></tr></thead><tbody>
<tr class="seglistitem">
<td class="seg">EXT-AUTH-09</td><td class="seg">A</td><td class="seg">Create Auth. drivers for Local Authority</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-10</td><td class="seg">A</td><td class="seg">Create Acct. Creation driver for Local
Authority</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-11</td><td class="seg">A</td><td class="seg">Create Auth. driver for PAM</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-12</td><td class="seg">X</td><td class="seg"><span class="emphasis"><em>Create Acct. Creation
driver for PAM - this functionality is explicitly excluded from
PAM</em></span></td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-13</td><td class="seg">A</td><td class="seg">Create Acct. Creation driver for LDAP</td>
</tr><tr class="seglistitem">
<td class="seg">EXT-AUTH-14</td><td class="seg">A</td><td class="seg">Create Auth. driver for LDAP</td>
</tr>
</tbody>
</table></div><p>We'll need drivers for:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Operating system (Linux/Solaris) PAM: Delegate to the operating
system, which can then talk to RADIUS, LDAP, whatever. This is
convenient because there'll be plenty of drivers for the OS PAM
level, so we don't have to write them all ourselves. The downside
is that we can't do things like account creation, password
management, real-time account synchronization, etc., not supported
by PAM (I'm not entirely sure what is and is not supported).</p></li><li class="listitem"><p>RADIUS</p></li><li class="listitem"><p>LDAP</p></li>
</ul></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="RADIU" id="RADIU"></a>RADIUS</h5></div></div></div><p>RADIUS is a simple username/password-type authentication
server.</p><p>It also supports sending a challenge to which the user must
respond with the proper answer (e.g. mother's maiden name, or could
be additional password), but we will not support this feature.</p><p>A RADIUS client <a class="ulink" href="http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/exuserfolder/exUserFolder/radiusAuthSource/radius.py?rev=1.4&amp;content-type=text/vnd.viewcvs-markup" target="_top">implementation in Python</a> can be found in the
<a class="ulink" href="http://exuserfolder.sourceforge.net/" target="_top">exUserFolder module</a> for Zope (<a class="ulink" href="http://sourceforge.net/docman/display_doc.php?docid=7238&amp;group_id=36318" target="_top">documentation</a>).</p>
</div>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="Feedbac" id="Feedbac"></a>Feedback</h3></div></div></div><p>We'd really appreciate feedback on this proposal. Please follow
up at <a class="ulink" href="http://openacs.org/forums/message-view?message_id=97341" target="_top">this openacs.org forums thread</a>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="Reference" id="Reference"></a>References</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="ulink" href="http://ims.edna.edu.au/enterprise/" target="_top">IMS Enterprise</a></p></li><li class="listitem"><p>
<a class="ulink" href="http://openacs.org/projects/openacs/packages/ex-auth/" target="_top">Threads and links</a> collected by Carl Blesius.</p></li><li class="listitem"><p><a class="ulink" href="http://java.sun.com/security/jaas/doc/pam.html" target="_top">Solaris/Linux PAM specification</a></p></li><li class="listitem"><p>
<a class="ulink" href="http://openacs.org/new-file-storage/download/oacs-pam.html?version_id=687" target="_top">Draft Proposal</a> by Andrew Grumet.</p></li><li class="listitem"><p>
<a class="ulink" href="http://www.yale.edu/tp/auth/" target="_top">Yale CAS</a>, a centrl authentication service a' la
Passport.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="ext-auth-revision-history" id="ext-auth-revision-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>Document Revision
#</strong></span></td><td><span class="strong"><strong>Action Taken,
Notes</strong></span></td><td><span class="strong"><strong>When?</strong></span></td><td><span class="strong"><strong>By Whom?</strong></span></td>
</tr><tr>
<td>1</td><td>Updated work-in-progress for consortium-sponsored ext-auth work
at Collaboraid.</td><td>20 Aug 2003</td><td>Joel Aufrecht</td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="bootstrap-acs" leftLabel="Prev" leftTitle="Bootstrapping OpenACS"
		    rightLink="releasing-openacs" rightLabel="Next" rightTitle="
Chapter 16. Releasing OpenACS"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		