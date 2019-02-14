
<property name="context">{/doc/acs-authentication/ {ACS Authentication}} {OpenACS Authentication}</property>
<property name="doc(title)">OpenACS Authentication</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="index" leftLabel="Prev"
			title="Introduction"
			rightLink="ext-auth-install" rightLabel="Next">
		    <p class="style1">acs-authentication</p>
<p>This document aims to help you understand how it works and how
you can use it for your own purpouses. By <a href="mailto:roc\@viaro.net">Rocael Hernández R.</a>
</p>
<p>
<strong>Main functionality:</strong> It is used to authenticate
any user in an openacs installations.</p>
<p>So far, you can use it to authenticate against LDAP &amp; PAM,
and of course, locally. You can implement your own based on your
needs, processes, etc.</p>
<p>Definition: SC = <a href="http://cvs.openacs.org/cvs/*checkout*/openacs-4/packages/acs-service-contract/www/doc/index.html?rev=1.2">
service-contract</a>
</p>
<p class="style2"> </p>
<p class="style2">Authorities</p>
<p>acs-authentication can have multiple authorities, each one
represent an specific configuration of authenticatication. For
instance, in your openacs installation you can have users related
to different authorities, some of them might authenticate locally
since they are external or invited, others belongs to your
corporate network and already have users, so might authenticate
against LDAP and others in your own work office might use PAM for
authentication because your local system authentication. Plus you
might define an specific implementation (using the set of SC) to
connect to your client DB, which is in another DB, and allow your
clients login to certain parts of your website. Then, this is right
way to handle all those set of users, that already might have an
account in another place and you just want them to authenticate
against that external system.<br>
</p>
<p>The idea is: <strong>each user belongs to a given authority, and
just one</strong> .</p>
<p>
<strong>To add an authority</strong> in your installation go to
/acs-admin/auth/ and click on "Create new authority".</p>
<p>When adding the authority you need to configure:</p>
<ul>
<li>Authentication method (where to authenticate, i.e. check
user/password)</li><li>Password Management (where to update passwords)</li><li>Account Registration (where to create new accounts)</li><li>On-Demand Sync (to get user info from the source in real
time)</li>
</ul>
<p>Those configurations simply will perform the tcl proc that is
defined in the SC above described for the given SC implementation
that you choose. In other words:</p>
<ul>
<li>For using LDAP, you need to install <a href="http://cvs.openacs.org/cvs/openacs-4/packages/auth-ldap/">auth-ldap</a>,
on its installation, this package will create an <a href="http://cvs.openacs.org/cvs/*checkout*/openacs-4/packages/auth-ldap/tcl/auth-ldap-procs.tcl?rev=1.8">
implementation</a> of the above mentioned SC definitions (look at
"specs" that define which proc needs to be called for
each alias).</li><li>PAM package is <a href="http://cvs.openacs.org/cvs/openacs-4/packages/auth-pam/">auth-pam</a>.</li><li>Probably, for any new authentication method you&#39;ll need to
create your own package in the same style of auth-ldap or
auth-pam.</li>
</ul>
<p> </p>
<p>Note: "Batch Synchronization" will not be administered
there anymore in the future, everything will go to <a href="http://cvs.openacs.org/cvs/openacs-4/packages/ims-ent/%27">ims-ent</a>.</p>
<p>Also, depending on each implementation, it has a set of
parameters that will require for the configuration to work. And
those parameters are set independently by authority /
authentication method, so for LDAP you&#39;ll be able to configure
the next set of parameters:</p>
<ul>
<li>DNPattern</li><li>UsernameAttribute</li><li>Elements</li><li>BaseDN</li><li>Attributes</li><li>PasswordHash</li>
</ul>
<p>Then you can enter your specific values for your server, is
likely that the recomemded ones will work fine.</p>
<p>Hint: nssha (SSHA) doesn&#39;t work well with LDAP use ns_passwd
or another encryption method (MD5...)</p>
<p>You can make your users to logging using the email or username,
by changing the parameter at the kernel named: UseEmailForLoginP
under Security section. If username is used for logging, it will
ask for the authority to use, since username is unique by authority
but not for the entire openacs installation (can exists several
identic usernames but each one belongs to a different
authority).</p>
<p class="style2"> </p>
<p class="style2"><strong>acs-authentication defines a set of SC to
interact with the different authentication implementations (LDAP or
PAM):</strong></p>
<ol>
<li>auth_authentication "Authenticate users and retrieve their
account status.", with the operations:
<ul>
<li>Authenticate</li><li>GetParameters</li>
</ul>
</li><li>auth_password "Update, reset, and retrieve passwords for
authentication.", with the operations:
<ul>
<li>CanChangePassword</li><li>ChangePassword</li><li>CanRetrievePassword</li><li>RetrievePassword</li><li>CanResetPassword</li><li>ResetPassword</li><li>GetParameters</li>
</ul>
</li><li>auth_registration "Registering accounts for
authentication", with the operations:
<ul>
<li>GetElements</li><li>Register</li><li>GetParameters</li>
</ul>
</li><li>auth_sync_retrieve</li><li>auth_sync_process</li><li>auth_user_info
<ul>
<li>GetUserInfo</li><li>GetParameters</li>
</ul>
</li>
</ol>
<p>Note: #4 &amp; #5 will be taken out from authentication and
moved to the package <a href="http://cvs.openacs.org/cvs/openacs-4/packages/ims-ent/">ims-ent</a>.</p>
<p>The SC definitions are quite straightforward, then worth to look
<a href="http://cvs.openacs.org/cvs/openacs-4/packages/acs-authentication/tcl/apm-callback-procs.tcl?rev=1.13&amp;only_with_tag=HEAD&amp;view=auto">
at them</a> for better understanding.</p>
<p class="style2"> </p>
<p class="style2">Login process</p>
<p>In an openacs site the login is managed through
acs-authentication. It happens like this:<br>
</p>
<ol>
<li>The user enters the email/user &amp; password</li><li>It will search the user in the users table and return the
authority_id</li><li>With that authority_id it will find the respective SC
implementation <em>which contains the adequate tcl proc for the
authentication process</em>
</li><li>That proc will check the identity of the user based on the
password (right now could be locally, pam or ldap authenticated,
though this model supports N methods of authentication)</li>
</ol>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="index" leftLabel="Prev" leftTitle=""
			rightLink="ext-auth-install" rightLabel="Next" rightTitle="Installation"
			homeLink="index" homeLabel="Home" 
			upLink="index" upLabel="Up"> 
		    <p> </p>
