
<property name="context">{/doc/acs-authentication/ {ACS Authentication}} {Using LDAP/Active Directory with OpenACS}</property>
<property name="doc(title)">Using LDAP/Active Directory with OpenACS</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="ext-auth-pam-install" leftLabel="Prev"
			title="Installation"
			rightLink="configure-batch-sync" rightLabel="Next">
		    <div class="sect1" lang="en">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="ext-auth-ldap-install" id="ext-auth-ldap-install"></a>Using
LDAP/Active Directory with OpenACS</h2></div></div></div><div class="authorblurb">by <a href="http://openacs.org/shared/community-member?user_id=8551" target="_top">John Sequeira</a>, <a href="http://openacs.org/shared/community-member?user_id=8263" target="_top">Michael Steigman</a>, and <a href="http://openacs.org/shared/community-member?user_id=12805" target="_top">Carl Blesius</a>. OpenACS docs are written by the named
authors, and may be edited by OpenACS documentation staff.</div><p>
<strong>ToDo: </strong>Add/verify information on on-demand
sync, account registration, and batch synchronization. Add section
on ldapsearch.</p><p>
<strong>Overview. </strong>You do not want to make users
remember yet another password and username. If you can avoid it you
do not want to store their passwords either. This document should
help you set your system up so your users can seamlessly log in to
your OpenACS instance using the password they are accustomed to
using for other things at your institution.</p><p>
<strong>Background. </strong>The original OpenACS LDAP
implementation (which has been deprecated by this package) treated
the LDAP server as another data store similar to Oracle or
Postgresql. It opened a connection using a privileged account and
read or stored an encrypted password for the user in question. This
password was independent of the user&#39;s operating system or
network account, and had to be synchronized if you wanted the same
password for OpenACS.Save their passwords? Sync passwords? Deal
with forgotten password requests? No Thanks. Using ldap bind, you
can delegate authentication completely to LDAP. This way you can
let the IT department (if you are lucky) worry about password
storage/synchronization/etc. The bind operation takes a username
and password and returns a true of false depending on whether they
match up. This document takes the 'bind' approach so that
your users LDAP/AD password (or whatever else you use) can be used
to login to OpenACS.</p><p>
<strong>Note on Account Creation. </strong>On the
authentication driver configure screens, you will also see lots of
options for synchronizing users between your directory and OpenACS.
This document takes the approach of provisioning users on demand
instead of ahead-of-time. This means that when they attempt to
login to OpenACS, if they have a valid Windows account, we&#39;ll
create an account for them in OpenACS and log them in.</p><div class="orderedlist"><ol type="1">
<li>
<p>
<a name="ext-auth-ldap-setup" id="ext-auth-ldap-setup"></a><strong>Installing AOLserver LDAP support
(openldap and nsldap). </strong>Install openldap and nsldap
using <a href="http://openacs.org/doc/current/install-ldap-radius.html" target="_top">the document Malte created</a> Next, modify your config.tcl
file as directed in the nsldap README. Here&#39;s what the relevant
additions should look like:</p><pre class="screen"><code class="computeroutput">
# LDAP authentication
ns_param   nsldap             ${bindir}/nsldap.so

...

ns_section "ns/ldap/pool/ldap"
ns_param user "cn=Administrator, cn=Users, dc=mydomain, dc=com"
ns_param password "password"
ns_param host "directory.mydomain.com"
ns_param connections 1
ns_param verbose On

ns_section "ns/ldap/pools"
ns_param ldap ldap

ns_section "ns/server/${server}/ldap"
ns_param pools *
ns_param defaultpool ldap
   </code></pre><p>To verify that this is all working, restart Aolserver and ensure
that you see something like this in your error.log:</p><pre class="screen"><code class="computeroutput">
[10/Jan/2006:11:11:07][22553.3076437088][-main-] Notice: modload: loading '/usr/local/aolserver/bin/nsldap.so'
[10/Jan/2006:11:11:08][22553.3076437088][-main-] Debug: nsldap: allowing * -&gt; pool ldap
[10/Jan/2006:11:11:08][22553.3076437088][-main-] Debug: nsldap: adding pool ldap to the list of allowed pools
[10/Jan/2006:11:11:08][22553.3076437088][-main-] Debug: nsldap: Registering LDAPCheckPools (600)
    </code></pre>
</li><li><p>
<strong>auth-ldap + driver installation. </strong>Next,
visit the software installation page in acs-admin and install the
auth-ldap package. Your OpenACS installation now has all the code
required to authenticate using nsldap, so now you need to configure
your site&#39;s authentication to take advantage of it. To add the
authentication driver to your OpenACS instance, go to: Main Site,
Site-Wide Administration, and then AuthenticationHere&#39;s some
sample Authentication Driver values:Name=Active Directory, Short
Name=AD, Enabled=Yes, Authentication=LDAP, Password
Management=LDAPYou may wish to push this new authority to the top
of the list so it will become the default for users on the login
screen.Next, you have to configure the authentication driver
parameters by going to: Main Site, Site-Wide Administration,
Authentication, Active Directory, and then ConfigureParameters that
match our example will look like:UsernameAttribute=sAMAccountNMame,
BaseDN= cn=Users,dc=mydomain,dc=com,
InfoAttributeMap=first_names=givenName;last_name=sn;email=mail,
PasswordHash=N/A</p></li><li>
<p>
<strong>Code Tweaks for Bind. </strong>Bind-style
authentication is not supported via configuration parameters, so we
will have to modify the tcl authentication routine to provide this
behavior.You&#39;ll have to modify the existing
./packages/auth-ldap/tcl/auth-ldap-procs.tcl file to support bind
authentication.First toggle ldap bind support.Change this:</p><pre class="screen"><code class="computeroutput">
# LDAP bind based authentication ?
set ldap_bind_p 0
if {$ldap_bind_p==1} {
...
    </code></pre><p>to this:</p><pre class="screen"><code class="computeroutput">
# LDAP bind based authentication ?
set ldap_bind_p 1

if {$ldap_bind_p==1} {
...
    </code></pre><p>Then change the bind to first do a search to resolve to account
name provided by the user to a fully qualified domain name (FQDN),
which the LDAP server uses as a primary key.Change this:</p><pre class="screen"><code class="computeroutput">
set lh [ns_ldap gethandle]

if {[ns_ldap bind $lh "cn=$cn" "$password"]} {
    set result(auth_status) ok
}    
    </code></pre><p>to this</p><pre class="screen"><code class="computeroutput">
set lh [ns_ldap gethandle]

set fdn [lindex [lindex [ns_ldap search $lh -scope subtree $params(BaseDN) "($params(UsernameAttribute)=$username)" dn] 0] 1]

if {[ns_ldap bind $lh $fdn $password]} {
    set result(auth_status) ok
}    
    </code></pre>
</li>
</ol></div><p>
<strong>Troubleshooting. </strong>If you&#39;re having
trouble figuring out some the values for the ldapm, see this useful
page on <a href="https://www.rhyous.com/2009/11/10/how-to-configure-bugzilla-to-authenticate-to-active-directory/" target="_top">setting up Active Directory integration with
Bugzilla</a>. It explains how distinguished names are defined in
Active Directory, and how to test that you have the correct values
for connectivity and base DN using the OpenLDAP command-line
utility ldapsearch.John had an issue where nsldap was not loading
because AOLServer couldn&#39;t find the openldap client libraries,
but he was able to fix it by adding the openldap libraries to his
LD_LIBRARY_PATH (e.g. /usr/local/openldap/lib)</p><p>
<strong>Credits. </strong>Thanks to Malte Sussdorf for his
help and the <a href="http://www.lcs.mgh.harvard.edu/" target="_top">Laboratory of Computer Science at Massachusetts General
Hospital</a> for underwriting this work.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="ext-auth-pam-install" leftLabel="Prev" leftTitle="Using Pluggable Authentication Modules
(PAM) with OpenACS"
			rightLink="configure-batch-sync" rightLabel="Next" rightTitle="Configure Batch Synchronization"
			homeLink="index" homeLabel="Home" 
			upLink="ext-auth-install" upLabel="Up"> 
		    