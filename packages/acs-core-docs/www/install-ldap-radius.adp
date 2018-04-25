
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install LDAP for use as external authentication}</property>
<property name="doc(title)">Install LDAP for use as external authentication</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install-pam-radius" leftLabel="Prev"
			title="Appendix B. Install
additional supporting software"
			rightLink="aolserver" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-ldap-radius" id="install-ldap-radius"></a>Install LDAP for use as external
authentication</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By <a class="ulink" href="mailto:openacs\@sussdorff.de" target="_top">Malte
Sussdorff</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><p>This step by step guide on how to use LDAP for external
authentication using the LDAP bind command, which differs from the
approach usually taken by auth-ldap. Both will be dealt with in
these section</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<a name="install-openldap" id="install-openldap"></a><p>
<strong>Install openldap. </strong> Download and install
ns_ldap</p><pre class="screen">[root aolserver]# <strong class="userinput"><code>cd /usr/local/src/</code></strong>
          [root src]# <strong class="userinput"><code>wget ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-2.2.17.tgz</code></strong>
          [root src]# <strong class="userinput"><code>tar xvfz openldap-2.2.17.tgz</code></strong>
          [root src]# <strong class="userinput"><code>cd openldap-2.2.17</code></strong>
          [root src]# <strong class="userinput"><code>./configure --prefix=/usr/local/openldap</code></strong>
          [root openldap]# <strong class="userinput"><code>make install</code></strong>
          [root openldap]#
<span class="action">cd /usr/local/src/
wget ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-2.2.17.tgz
tar xvfz openldap-2.2.17.tgz
cd openldap-2.2.17
./configure --prefix=/usr/local/openldap --disable-slapd
make install
</span>
</pre>
</li><li class="listitem">
<a name="install-ns_ldap" id="install-ns_ldap"></a><p>
<strong>Install ns_ldap. </strong> Download and install
ns_ldap</p><pre class="screen">[root aolserver]# <strong class="userinput"><code>cd /usr/local/src/aolserver/</code></strong>
          [root aolserver]# <strong class="userinput"><code>wget http://www.sussdorff.de/ressources/nsldap.tgz</code></strong>
          [root aolserver]# <strong class="userinput"><code>tar xfz nsldap.tgz</code></strong>
          [root aolserver]# <strong class="userinput"><code>cd nsldap</code></strong>
          [root ns_pam-0.1]# <strong class="userinput"><code>make install LDAP=/usr/local/openldap INST=/usr/local/aolserver</code></strong>
          [root ns_pam-0.1]#
<span class="action">cd /usr/local/src/aolserver/
wget http://www.sussdorff.de/resources/nsldap.tgz
tar xfz nsldap.tgz
cd nsldap
make install LDAP=/usr/local/openldap INST=/usr/local/aolserver
</span>
</pre>
</li><li class="listitem">
<a name="configure-ns_ldap" id="configure-ns_ldap"></a><p>
<strong>Configure ns_ldap for traditional use. </strong>
Traditionally OpenACS has supported ns_ldap for authentication by
storing the OpenACS password in an encrypted field within the LDAP
server called "userPassword". Furthermore a CN field was
used for searching for the username, usually userID or something
similar. This field is identical to the <span class="emphasis"><em>username</em></span>stored in OpenACS. Therefore the
login will only work if you change login method to make use of the
username instead.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p>Change <span class="emphasis"><em>config.tcl</em></span>. Remove
the <span class="emphasis"><em>#</em></span> in front of
<code class="computeroutput">ns_param nsldap
${bindir}/nsldap.so</code> to enable the loading of the ns_ldap
module.</p></li></ul></div>
</li><li class="listitem">
<a name="configure-ns_ldap-bind" id="configure-ns_ldap-bind"></a><p>
<strong>Configure ns_ldap for use with LDAP bind. </strong>
LDAP authentication usually is done by trying to bind (aka. login)
a user with the LDAP server. The password of the user is not stored
in any field of the LDAP server, but kept internally. The latest
version of ns_ldap supports this method with the <span class="emphasis"><em>ns_ldap bind</em></span> command. All you have to do
to enable this is to configure auth_ldap to make use of the BIND
authentication instead. Alternatively you can write a small script
on how to calculate the username out of the given input (e.g. if
the OpenACS username is malte.fb03.tu, the LDAP request can be
translated into "ou=malte,ou=fb03,o=tu" (this example is
encoded in auth_ldap and you just have to comment it out to make
use of it).</p>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install-pam-radius" leftLabel="Prev" leftTitle="Install PAM Radius for use as external
authentication"
			rightLink="aolserver" rightLabel="Next" rightTitle="Install AOLserver 3.3oacs1"
			homeLink="index" homeLabel="Home" 
			upLink="install-more-software" upLabel="Up"> 
		    