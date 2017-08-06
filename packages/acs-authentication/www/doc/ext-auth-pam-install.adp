
<property name="context">{/doc/acs-authentication {ACS Authentication}} {Using Pluggable Authentication Modules (PAM) with
OpenACS}</property>
<property name="doc(title)">Using Pluggable Authentication Modules (PAM) with
OpenACS</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="ext-auth-install" leftLabel="Prev"
		    title="Installation"
		    rightLink="ext-auth-ldap-install" rightLabel="Next">
		<div class="sect1" lang="en">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="ext-auth-pam-install" id="ext-auth-pam-install"></a>Using
Pluggable Authentication Modules (PAM) with OpenACS</h2></div></div></div><p>OpenACS supports PAM authetication via the ns_pam module in
AOLserver.</p><div class="orderedlist"><ol type="1">
<li>
<p>
<strong>Add PAM support to
AOLserver. </strong>OpenACS supports PAM support via
the PAM AOLserver module. PAM is system of modular support, and can
provide local (unix password), RADIUS, LDAP (<a href="http://www.tldp.org/HOWTO/archived/LDAP-Implementation-HOWTO/pamnss.html" target="_top">more information</a>), and other forms of
authentication. Note that due to security issues, the AOLserver PAM
module cannot be used for local password authentication.</p><div class="orderedlist"><ol type="a">
<li>
<p>
<a name="install-nspam" id="install-nspam"></a><strong>Compile
and install ns_pam. </strong>Download the <a href="/doc/nspam-download" target="_top">tarball</a> to <code class="computeroutput">/tmp</code>.</p><p>Debian users: first do <strong class="userinput"><code>apt-get
install libpam-dev</code></strong>
</p><pre class="screen">
[root\@yourserver root]# <strong class="userinput"><code>cd /usr/local/src/aolserver</code></strong>
[root\@yourserver aolserver]# <strong class="userinput"><code>tar xzf /tmp/ns_pam-0.1.tar.gz</code></strong>
[root\@yourserver aolserver]# <strong class="userinput"><code>cd nspam</code></strong>
[root\@yourserver nspam]# <strong class="userinput"><code>make</code></strong>
gcc -I/usr/include/pam -I/usr/local/aolserver/include -D_REENTRANT=1 
  -DNDEBUG=1 -g -fPIC -Wall -Wno-unused -mcpu=i686 -DHAVE_CMMSG=1 
  -DUSE_FIONREAD=1 -DHAVE_COND_EINTR=1   -c -o nspam.o nspam.c
nspam.c: In function `PamCmd':
nspam.c:107: warning: implicit declaration of function `Tcl_SetObjResult'
nspam.c:107: warning: implicit declaration of function `Tcl_NewIntObj'
gcc -I/usr/include/pam -I/usr/local/aolserver/include -D_REENTRANT=1 
  -DNDEBUG=1 -g -fPIC -Wall -Wno-unused -mcpu=i686 -DHAVE_CMMSG=1 
  -DUSE_FIONREAD=1 -DHAVE_COND_EINTR=1   -c -o pam_support.o pam_support.c
/bin/rm -f nspam.so
gcc -shared -nostartfiles -o nspam.so nspam.o pam_support.o -lpam
[root\@yourserver nspam]# <strong class="userinput"><code>make install</code></strong>
[root\@yourserver nspam]#
<span class="action"><span class="action">cd /usr/local/src/aolserver
tar xzf /tmp/ns_pam-0.1.tar.gz
cd nspam
make
make install</span></span>
</pre>
</li><li>
<p>
<strong>Set up a PAM domain. </strong>A PAM domain
is a set of rules for granting privileges based on other programs.
Each instance of AOLserver uses a domain; different aolserver
instances can use the same domain but one AOLserver instance cannot
use two domains. The domain describes which intermediate programs
will be used to check permissions. You may need to install software
to perform new types of authentication.</p><div class="itemizedlist"><ul type="disc">
<li>
<p><strong>RADIUS in PAM. </strong></p><div class="orderedlist"><ol type="i">
<li>
<p>Untar the <a href="/doc/individual-programs" target="_top">pam_radius tarball</a> and compile and install. (<a href="http://www.freeradius.org/pam_radius_auth/" target="_top">more
information</a>)</p><pre class="screen">
[root\@yourserver root]# <strong class="userinput"><code>cd /usr/local/src/</code></strong>
[root\@yourserver src]# <strong class="userinput"><code>tar xf /tmp/pam_radius-1.3.16.tar</code></strong>
[root\@yourserver src]# <strong class="userinput"><code>cd pam_radius-1.3.16</code></strong>
[root\@yourserver pam_radius-1.3.16]# <strong class="userinput"><code>make</code></strong>
cc -Wall -fPIC -c pam_radius_auth.c -o pam_radius_auth.o
cc -Wall -fPIC   -c -o md5.o md5.c
ld -Bshareable pam_radius_auth.o md5.o -lpam -o pam_radius_auth.so
[root\@yourserver pam_radius-1.3.16]# <strong class="userinput"><code>cp pam_radius_auth.so /lib/security/pam_radius_auth.so</code></strong>
[root\@yourserver pam_radius-1.3.16]#
<span class="action"><span class="action">cd /usr/local/src/
tar xf /tmp/pam_radius-1.3.16.tar
cd pam_radius-1.3.16
make
cp pam_radius_auth.so /lib/security/pam_radius_auth.so</span></span>
</pre><p>Debian users: <strong class="userinput"><code>apt-get install
libpam-radius-auth</code></strong>
</p>
</li><li>
<p>Set up the PAM domain. Recent PAM distributions have a different
file for each domain, all in <code class="computeroutput">/etc/pam.d</code>. Previous PAM setups put all
domain configuration lines into a single file, <code class="computeroutput">/etc/pam.conf</code>. On Red Hat, create the file
<code class="computeroutput">/etc/pam.d/<span class="replaceable"><span class="replaceable">service0</span></span>
</code> with these
contents:</p><pre class="programlisting">
auth       sufficient   /lib/security/pam_radius_auth.so
</pre>
</li><li>
<p>Modify the AOLserver configuration file to use this PAM domain.
Edit the line</p><pre class="programlisting">
ns_param   PamDomain             "<span class="replaceable"><span class="replaceable">service0</span></span>"
</pre><p>So that the value of the parameter matches the name (just the
file name, not the fully pathed name) of the domain file in</p><pre class="programlisting">
/etc/pam.d/
</pre>
</li>
</ol></div>
</li><li><p>
<strong>LDAP in PAM. </strong><a href="http://www.tldp.org/HOWTO/archived/LDAP-Implementation-HOWTO/pamnss.html#AEN110" target="_top">more information</a>
</p></li>
</ul></div>
</li><li>
<p><strong>Modify the AOLserver configuration file to support
ns_pam. </strong></p><p>In <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">service0</span></span>/etc/config.tcl</code>, enable
the nspam module by uncommenting this line:</p><pre class="programlisting">
ns_param   nspam           ${bindir}/nspam.so
</pre>
</li>
</ol></div>
</li><li><p>
<strong>Install auth-pam OpenACS service
package. </strong><a href="/acs-admin/install/" target="_top">Install</a><code class="computeroutput">auth-pam</code> and
restart the server.</p></li><li>
<p>
<a name="ext-auth-create-authority" id="ext-auth-create-authority"></a><strong>Create an OpenACS
authority. </strong>OpenACS supports multiple
authentication authorities. The OpenACS server itself is the
"Local Authority," used by default.</p><div class="orderedlist"><ol type="a">
<li><p>Browse to the authentication administration page, <code class="computeroutput">http://<span class="replaceable"><span class="replaceable">yourserver</span></span><a href="/acs-admin/auth/" target="_top">/acs-admin/auth/</a>
</code>. Create and name an
authority (in the sitewide admin UI)</p></li><li><p>Set Authentication to PAM.</p></li><li><p>If the PAM domain defines a <code class="computeroutput">password</code> command, you can set Password
Management to PAM. If not, the PAM module cannot change the
user&#39;s password and you should leave this option Disabled.</p></li><li><p>Leave Account Registration disabed.</p></li><li><p><a href="configure-batch-sync" title="Configure Batch Synchronization">Configure Batch
Synchronization</a></p></li>
</ol></div>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="ext-auth-install" leftLabel="Prev" leftTitle="Installation"
		    rightLink="ext-auth-ldap-install" rightLabel="Next" rightTitle="Using LDAP/Active Directory with
OpenACS"
		    homeLink="index" homeLabel="Home" 
		    upLink="ext-auth-install" upLabel="Up"> 
		