
<property name="context">{/doc/acs-authentication {Authentication}} {Using LDAP/Active Directory with OpenACS}</property>
<property name="doc(title)">Using LDAP/Active Directory with OpenACS</property>
<master>

<body>
<div class="navheader"><table width="100%" summary="Navigation header" border="0"><tr>
<td width="20%" align="left"><a accesskey="p" href="ext-auth-pam-install">Prev</a></td><th width="60%" align="center">Installation</th><td width="20%" align="right"><a accesskey="n" href="configure-batch-sync">Next</a></td>
</tr></table></div><div class="sect1" lang="en">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="ext-auth-ldap-install" id="ext-auth-ldap-install"></a>Using
LDAP/Active Directory with OpenACS</h2></div></div></div><div class="authorblurb">by <a href="http://openacs.org/shared/community-member?user_id=8551" target="_top">John Sequeira</a>, <a href="http://openacs.org/shared/community-member?user_id=8263" target="_top">Michael Steigman</a>, and <a href="http://openacs.org/shared/community-member?user_id=12805" target="_top">Carl Blesius</a>. OpenACS docs are written by the named
authors, and may be edited by OpenACS documentation staff.</div><p>
<b>ToDo: </b>Add/verify information on on-demand sync,
account registration, and batch synchronization. Add section on
ldapsearch.</p><p>
<b>Overview. </b>You do not want to make users remember yet
another password and username. If you can avoid it you do not want
to store their passwords either. This document should help you set
your system up so your users can seamlessly log in to your OpenACS
instance using the password they are accustomed to using for other
things at your institution.</p><p>
<b>Background. </b>The original OpenACS LDAP implementation
(which has been depreciated by this package) treated the LDAP
server as another data store similar to Oracle or Postgresql. It
opened a connection using a priveleged account and read or stored
an encrypted password for the user in question. This password was
independent of the user's operating system or network account, and
had to be synchronized if you wanted the same password for
OpenACS.Save their passwords? Sync passwords? Deal with forgotten
password requests? No Thanks. Using ldap bind, you can delegate
authentication completely to LDAP. This way you can let the IT
department (if you are lucky) worry about password
storage/synchronization/etc. The bind operation takes a username
and password and returns a true of false depending on whether they
match up. This document takes the 'bind' approach so that your
users LDAP/AD password (or whatever else you use) can be used to
login to OpenACS.</p><p>
<b>Note on Account Creation. </b>On the authentication
driver configure screens, you will also see lots of options for
synchronizing users between your directory and OpenACS. This
document takes the approach of provisioning users on demand instead
of ahead-of-time. This means that when they attempt to login to
OpenACS, if they have a valid Windows account, we'll create an
account for them in OpenACS and log them in.</p><div class="orderedlist"><ol type="1">
<li>
<p>
<a name="ext-auth-ldap-setup" id="ext-auth-ldap-setup"></a><b>Installing AOLserver LDAP support
(openldap and nsldap). </b>Install openldap and nsldap using
<a href="http://openacs.org/doc/current/install-ldap-radius.html" target="_top">the document Malte created</a> Next, modify your
config.tcl file as directed in the nsldap README. Here's what the
relevant additions should look like:</p><pre class="screen"><code class="computeroutput">
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
<b>auth-ldap + driver installation. </b>Next, visit the
software installation page in acs-admin and install the auth-ldap
package. Your OpenACS installation now has all the code required to
authenticate using nsldap, so now you need to configure your site's
authentication to take advantage of it. To add the authentication
driver to your OpenACS instance, go to: Main Site, Site-Wide
Administration, and then AuthenticationHere's some sample
Authentication Driver values:Name=Active Directory, Short Name=AD,
Enabled=Yes, Authentication=LDAP, Password Management=LDAPYou may
wish to push this new authority to the top of the list so it will
become the default for users on the login screen.Next, you have to
configure the authentication driver parameters by going to: Main
Site, Site-Wide Administration, Authentication, Active Directory,
and then ConfigureParameters that match our example will look
like:UsernameAttribute=sAMAccountNMame, BaseDN=
cn=Users,dc=mydomain,dc=com,
InfoAttributeMap=first_names=givenName;last_name=sn;email=mail,
PasswordHash=N/A</p></li><li>
<p>
<b>Code Tweaks for Bind. </b>Bind-style authentication is
not supported via configuration parameters, so we will have to
modify the tcl authentication routine to provide this
behavior.You'll have to modify the existing
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
<b>Troubleshooting. </b>If you're having trouble figuring
out some the values for the ldapm, see this useful page on <a href="http://bugzilla.glob.com.au/activedirectory/" target="_top">setting up Active Directory integration with Bugzilla</a>.
It explains how distinguished names are defined in Active
Directory, and how to test that you have the correct values for
connectivity and base DN using the OpenLDAP command-line utility
ldapsearch.John had an issue where nsldap was not loading because
AOLServer couldn't find the openldap client libraries, but he was
able to fix it by adding the openldap libraries to his
LD_LIBRARY_PATH (e.g. /usr/local/openldap/lib)</p><p>
<b>Credits. </b>Thanks to Malte Sussdorf for his help and
the <a href="http://www.lcs.mgh.harvard.edu/" target="_top">Laboratory of Computer Science at Massachusetts General
Hospital</a> for underwriting this work.</p>
</div><div class="navfooter">
<hr><table width="100%" summary="Navigation footer">
<tr>
<td width="40%" align="left"><a accesskey="p" href="ext-auth-pam-install">Prev</a></td><td width="20%" align="center"><a accesskey="h" href="index">Home</a></td><td width="40%" align="right"><a accesskey="n" href="configure-batch-sync">Next</a></td>
</tr><tr>
<td width="40%" align="left">Using Pluggable Authentication Modules
(PAM) with OpenACS</td><td width="20%" align="center"><a accesskey="u" href="ext-auth-install">Up</a></td><td width="40%" align="right">Configure Batch Synchronization</td>
</tr>
</table><hr><address><a href="mailto:docs\@openacs.org">docs\@openacs.org</a></address>
</div><a name="comments" id="comments"></a><center><a href="http://openacs.org/doc/current/ext-auth-ldap-install.html#comments">
View comments on this page at openacs.org</a></center>
</body>
